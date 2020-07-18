library(tidyverse)
# TODO: handle overlapping signs
# TODO: handle abbreviations in signs, to reduce clutter!
library(sf)
library(tigris)
library(ggplot2)
options(tigris_class = "sf")
options(tigris_use_cache = T)
source("util/parameters.R")
source("util/compute_transformation.R")

poi_classes <- c(
  "RSTN",
  "RSTP",
  "TRANT"
)

read_geonames <- function(country_code) {
  read_delim(paste0("data/geonames/", country_code, ".zip"), delim="\t", col_names=FALSE, col_types = cols(.default = 'c'), quote = "") %>%
    select(id = X1, name = X3, lat = X5, long = X6, level = X7, class = X8, population = X15) %>%
    mutate(lat = as.numeric(lat), long = as.numeric(long), population = as.integer(population), dataset = country_code)
}

data <- countries %>%
  map(read_geonames) %>%
  reduce(bind_rows)

of_interest <- data %>%
  filter(class %in% poi_classes)

names <- of_interest$name

xvec <- of_interest$lat
yvec <- of_interest$long


original <- matrix(data = c(xvec, yvec, rep(1, length(xvec))), ncol = 3)
image <- original %*% results

# throw out out of bounds coords
# switch these for ccw?
xvec_t <- round(image[,2])
yvec_t <- round(image[,1])

to_keep <- between(xvec_t, 1, x_bound) & between(yvec_t, 1, y_bound)

xvec_t <- xvec_t[to_keep]
yvec_t <- yvec_t[to_keep]
names <- names[to_keep]

review <- of_interest[to_keep,]
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

out_str <- paste0("
require(\"version.nut\")
class Main extends GSController
{
    constructor(){};
}

function Main::Start()
{
    Sleep(1); // don't have this happen during world gen, but after we've 'loaded'
    local x = ", xstr, ";
    local y = ", ystr, ";
    local names = ", namestr, ";
    for(local i = 0; i < ", nrow(review), "; i++) {
        local tile = GSMap.GetTileIndex(x[i], y[i]);
        GSSign.BuildSign(tile, names[i]);
    }
}

function Main::Save()
{
    return {};
}

function Main::Load(){};
")

write_file(out_str, "~/Documents/OpenTTD/game/poilabeler/main.nut")
