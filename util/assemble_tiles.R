library(gdalUtils)
library(rgdal)

assemble_tiles <- function(tile_directory, base_filename, output_filename) {
  tile_filenames <- list.files(tile_directory, full.names=T)
  gdalbuildvrt(
    tile_filenames,
    "data/temp/temp.vrt",
    overwrite = T)
  align_rasters(
    "data/temp/temp.vrt",
    base_filename,
    output_filename,
    nThreads = "ALL_CPUS")
}
