library(tidyverse)
library(sf)
library(tigris)
library(ggplot2)
options(tigris_class = "sf")
source("parameters.R")

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

data <- read_delim("US.zip", delim="\t", col_names=FALSE, col_types = cols(.default = 'c'), quote = "") %>%
  select(id = X1, name = X3, lat = X5, long = X6, level = X7, class = X8, population = X15) %>%
  mutate(lat = as.numeric(lat), long = as.numeric(long), population = as.integer(population))

# class types
# BLDG, HTL, CH, LIBR
# level types
# P populated

combined <- rbind_tigris(
  lapply(sts, function(x) {
    counties(x, cb = TRUE)
  })
)

of_interest <- data %>% 
  filter(level == "P") %>%
  st_as_sf(coords = c("long", "lat"), crs = st_crs(combined))

of_interest$indicator <- st_within(of_interest, combined) %>% lengths > 0

of_interest_cull <- of_interest %>% filter(indicator)

