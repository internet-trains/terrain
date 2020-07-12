# Starting materials. We need:

# 1. A Geotiff height map of the area in question
# 2. A CRS
# 3. The following files:
#  - the height map from 1)
#  - the 'coast' file, which is a mask just for the coastline
#  - the inland water file
#  - the trees file
#  All of these files should be geotiffs with the same extent and resolution!

library(tidyverse)
library(sf)
library(gdalUtils)
library(raster)
library(fasterize)
source("util/assemble_tiles.R")

scenario_name <- "baltic"
river_scale <- 5
map_crs <- CRS("+init=EPSG:4326")

# end user customizable code
scenario_dir <- file.path("data", "scenarios", scenario_name)

base_file <- file.path(scenario_dir, "base.tif")

# This is the output 'stack' template
# Everything will be a raster that fits into this template.
template <- projectExtent(raster(base_file), map_crs)

load("data/srtm.crs")

# Step 1. Reproject and save the coast and base files
gdalwarp(file.path(scenario_dir, "base.tif"), file.path(scenario_dir, "height.tif"), s_srs = srtm_crs, t_srs = map_crs)
gdalwarp(file.path(scenario_dir, "base_coast.tif"), file.path(scenario_dir, "coast.tif"), s_srs = srtm_crs, t_srs = map_crs)

# Step 2. Generate inland water files
water <- list.files(file.path(scenario_dir, "water"), pattern = ".shp", full.names = T, recursive = T) %>%
  map(st_read) %>%
  reduce(bind_rows) %>%
  st_set_crs(srtm_crs) %>%
  st_transform(map_crs) %>%
  st_buffer(dist = 0)

cropped_water <- water %>%
  st_crop(
    template %>%
      extent() %>%
      as("SpatialPolygons") %>%
      st_as_sf() %>%
      st_set_crs(map_crs)
  ) %>%
  st_cast()

water_map <- cropped_water %>% fasterize(template)
writeRaster(water_map, file.path(scenario_dir, "water.tif"))

# Step 3. Generate river ways
rivers <- list.files("data/rivers", pattern = "eurivs.shp", recursive = T, full.names = T) %>%
  map(st_read) %>%
  reduce(bind_rows) %>%
  st_transform(crs = map_crs)

cropped_data <- rivers %>%
  st_crop(
    template %>%
      extent() %>%
      as("SpatialPolygons") %>%
      st_as_sf() %>%
      st_set_crs(map_crs)
  )

# expand the linestrings into rectangles
rivers <- cropped_data %>%
  st_buffer(dist = cropped_data$a_WIDTH * river_scale) %>%
  st_cast()

rivers$value <- 1

river_map <- fasterize(rivers, template, fun = "max", background = 0)

river_map %>%
  writeRaster(file.path(scenario_dir, "rivers.tif"))

# Step 4. Generate tree map

assemble_tiles(file.path(scenario_dir, "trees"), file.path(scenario_dir, "height.tif"), file.path(scenario_dir, "trees.tif"))
