set.seed(2)
#source("load_data.R")
source("../util/compute_transformation.R")

# Rasterization step
# do we need to reproject or can we assume its square grid
towns_per_county <- 10

# for in-US
to_map <- of_interest_cull %>% 
  group_by(combined.GEOID) %>%
  filter(class %in% class_types) %>%
#  filter(indicator > 0) %>% 
  filter(population > 0) %>%
#  top_n(towns_per_county, population) %>%
  arrange(-population)

# join up with outside US
to_map <- rbind(
  to_map %>% st_transform(crs = 4326) %>% ungroup() %>% select(-indicator, -combined.GEOID)
#  to_map_foreign
) %>%
#  filter(population > 0) %>%
  arrange(-population)

names <- to_map$name

coords <- to_map %>% st_coordinates()

xvec <- coords[,1]
yvec <- coords[,2]


original <- matrix(data = c(xvec, yvec, rep(1, length(xvec))), ncol = 3)
image <- original %*% results

# throw out out of bounds coords
# switch these for ccw?
xvec_t <- round(image[,2])
yvec_t <- round(image[,1])

to_keep <- between(xvec_t, 12, x_bound-13) & between(yvec_t, 12, y_bound-13)

xvec_t <- xvec_t[to_keep]
yvec_t <- yvec_t[to_keep]
names <- names[to_keep]

review <- to_map[to_keep,]
review$x <- xvec_t
review$y <- yvec_t

review <-
  review %>%
  group_by(name) %>%
  mutate(count = row_number()) %>%
  ungroup() %>%
  mutate(name = ifelse(count > 1, paste0(name, " ", as.roman(count)), name))

names <- review$name


xstr <- paste0("[", paste0(xvec_t, collapse=','), "]")
ystr <- paste0("[", paste0(yvec_t, collapse=','), "]")
namestr <- paste0("[", paste0("\"", names, "\"", collapse=','), "]")

out_str <- paste0("require(\"version.nut\")
class Main extends GSController
{
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
        } else if (i < 1) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_MEDIUM, true, names[i]);
        } else if (i < 1) {
            TryTown(x[i], y[i], GSTown.TOWN_SIZE_LARGE, false, names[i]);
        } else if (i < 164) {
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
        success = GSTown.FoundTown(GSMap.GetTileIndex(x, y), size, city, GSTown.ROAD_LAYOUT_BETTER_ROADS, name);
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

