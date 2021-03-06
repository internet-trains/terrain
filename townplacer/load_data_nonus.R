library(tidyverse)
library(sf)
library(tigris)
library(ggplot2)
options(tigris_class = "sf")
options(tigris_use_cache = T)
source("util/parameters.R")

#BLDG
#HTL - Hotel
#CH - Church
#LIBR - Library
#PPL - City

#top tier - cities and communities
#PPL
#PPLA
#PPLA2
#-
#subdivisions
#PPLX

read_geonames <- function(country_code) {
  read_delim(paste0("data/geonames/", country_code, ".zip"), delim="\t", col_names=FALSE, col_types = cols(.default = 'c'), quote = "") %>%
    select(id = X1, name = X3, lat = X5, long = X6, level = X7, class = X8, population = X15) %>%
    mutate(lat = as.numeric(lat), long = as.numeric(long), population = as.integer(population), dataset = country_code)
}

data <- countries %>%
  map(read_geonames) %>%
  reduce(bind_rows)

# class types
# BLDG, HTL, CH, LIBR
# level types
# P populated

of_interest <- data %>%
#  filter(level == "P") %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)

to_map_foreign <- of_interest
