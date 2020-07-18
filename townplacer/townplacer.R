library(tidyverse)
set.seed(2)
#source("load_data.R")
source("util/compute_transformation.R")

# Rasterization step
# do we need to reproject or can we assume its square grid
towns_per_county <- 10

# for in-US
#to_map <- of_interest_cull %>%
#  group_by(combined.GEOID) %>%
#  filter(class %in% class_types) %>%
#  filter(indicator > 0) %>%
#  filter(population > 0) %>%
#  top_n(towns_per_county, population) %>%
#  arrange(-population)

# join up with outside US
to_map <- rbind(
#  to_map %>% st_transform(crs = 4326) %>% ungroup() %>% select(-indicator, -combined.GEOID)
  to_map_foreign) %>%
  filter(class %in% class_types)

#to_map <- to_map_foreign

names <- to_map$name

coords <- to_map %>% st_coordinates()

xvec <- coords[,2]
yvec <- coords[,1]


original <- matrix(data = c(xvec, yvec, rep(1, length(xvec))), ncol = 3)
image <- original %*% results

# throw out out of bounds coords
# switch these for ccw?
xvec_t <- round(image[,1])
yvec_t <- round(image[,2])

to_keep <- between(xvec_t, 12, x_bound-13) & between(yvec_t, 12, y_bound-13)

xvec_t <- xvec_t[to_keep]
yvec_t <- yvec_t[to_keep]
names <- names[to_keep]

review <- to_map[to_keep,]
review$x <- xvec_t
review$y <- yvec_t

review <-
  review %>%
  group_by(name, class == "RSTN") %>%
  mutate(count = row_number()) %>%
  filter(count == 1) %>%
  ungroup() %>%
  mutate(name = ifelse(count > 1, paste0(name, " ", as.roman(count)), name))

stations <- review %>% filter(class == "RSTN") %>% select(id, name, x, y)
towns <- review %>% filter(class != "RSTN")
pop_towns <- towns %>% filter(population > 0)

# Of these, find the ones for each train station
data_tree <- createTree(data.frame(towns$x, towns$y))

selected_town_indices <- knnLookup(data_tree, newdat = data.frame(stations$x, stations$y), k = 1)
selected_towns <- towns[selected_town_indices,] %>%
  filter(population == 0) %>% # we are already including all the pop > 0 places
  distinct(name, .keep_all=T)

review <- bind_rows(pop_towns, selected_towns) %>% arrange(-population, class)

xstr <- paste0("[", paste0(review$x, collapse=','), "]")
ystr <- paste0("[", paste0(review$y, collapse=','), "]")
namestr <- paste0("[", paste0("\"", review$name, "\"", collapse=','), "]")

out_str <- paste0("require(\"version.nut\")
class Main extends GSController
{
    company_id = 0;
    constructor()
    {
    }
}

function Main::Start()
{
    Sleep(1); // don't have this happen during world gen, but after we've 'loaded'
    local x = ",
  xstr,
  ";
    local y = ",
  ystr,
  ";
    local names = ",
  namestr,
  ";
    for(local i = 0; i < ",
  nrow(review),
  "; i++) {
        if (i < 1) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_LARGE, true, names[i]);
        } else if (i < 19) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_MEDIUM, true, names[i]);
        } else if (i < 19) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_LARGE, false, names[i]);
        } else if (i < 176) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_MEDIUM, false, names[i]);
        } else {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_SMALL, false, names[i]);
        }
    }
}

function Main::TryTown(x, y, size, city, name) {
    local success = false;
    local timeout = 1000;
    local counter = 0;

    while(!success && counter < timeout) {
        local cur_tile = GSMap.GetTileIndex(x, y);
        success = GSTown.FoundTown(cur_tile, size, city, GSTown.ROAD_LAYOUT_BETTER_ROADS, name);
        x = x + GSBase.RandRange(3) - 1;
        y = y + GSBase.RandRange(3) - 1;
        counter += 1;
    }
    if(!success) {
        GSLog.Warning(name);
    }
}
function Main::Save()
{
    return {};
}

function Main::Load()
{
}
")

write_file(out_str, "~/Documents/OpenTTD/game/townplacer/main.nut")

