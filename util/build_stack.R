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
source("util/parameters.R")
source("util/assemble_tiles.R")

# end user customizable code
scenario_dir <- file.path("data", "scenarios", scenario_name)

base_file <- file.path(scenario_dir, "base.tif")

# This is the output 'stack' template
# Everything will be a raster that fits into this template.
template <- projectExtent(raster(base_file), map_crs)

load("data/srtm.crs")

# Step 1. Reproject and save the coast and base files
gdalwarp(
  file.path(scenario_dir, "base.tif"),
  file.path(scenario_dir, "height.tif"),
  tr = res(template),
  s_srs = srtm_crs,
  t_srs = map_crs)
gdalwarp(
  file.path(scenario_dir, "base_coast.tif"),
  file.path(scenario_dir, "coast.tif"),
  tr = res(template),
  s_srs = srtm_crs,
  t_srs = map_crs)

# Step 2. Generate inland water files
water <-
  list.files(
    file.path(scenario_dir, "water"),
    pattern = ".shp",
    full.names = T,
    recursive = T) %>%
  map(st_read) %>%
  reduce(bind_rows) %>%
  st_set_crs(srtm_crs) %>%
  st_transform(map_crs) %>%
  st_zm() %>%
  st_buffer(dist = 0)

cropped_water <-
  water %>%
  st_crop(
    template %>%
      extent() %>%
      as("SpatialPolygons") %>%
      st_as_sf() %>%
      st_set_crs(map_crs)
  ) %>%
  st_cast()

water_map <- cropped_water %>% fasterize(template)
writeRaster(water_map, file.path(scenario_dir, "water.tif"), overwrite = T)

rm(water)
rm(cropped_water)
rm(water_map)

# Step 3. Generate river ways
rivers <-
  file.path("data", "rivers", c("asia.gdb")) %>%
  map(st_read) %>%
  reduce(bind_rows) %>%
  st_transform(crs = map_crs)


cropped_rivers <-
  rivers %>%
  filter(ORD_FLOW < 7, ORD_FLOW > 4) %>%
  st_crop(
    template %>%
      extent() %>%
      as("SpatialPolygons") %>%
      st_as_sf() %>%
      st_set_crs(map_crs)
  )

# expand the linestrings into rectangles
raster_rivers <-
  cropped_rivers %>%
  #  st_transform(crs("+init=EPSG:25884")) %>% # temporary hack for tweaking buffer size
  st_buffer(
    # dist = river_scale *
    #   (1 + .5 * (cropped_rivers$a_WIDTH - min(cropped_rivers$a_WIDTH)) /
    #      (max(cropped_rivers$a_WIDTH) - min(cropped_rivers$a_WIDTH))),
    dist = 12*(8 - cropped_rivers$ORD_FLOW),
    endCapStyle = "FLAT",
    joinStyle = "ROUND") %>%
  st_cast() %>%
  st_transform(map_crs)

raster_rivers$value <- 1

river_map <- raster_rivers %>% fasterize(template)

river_map %>%
  writeRaster(file.path(scenario_dir, "rivers.tif"), overwrite = T)

rm(rivers)
rm(cropped_rivers)
rm(raster_rivers)
rm(river_map)

# Step 4. Generate tree map

assemble_tiles(
  file.path(scenario_dir, "trees"),
  file.path(scenario_dir, "base.tif"),
  file.path(scenario_dir, "trees.tif"))
