sts <- c("WI", "IL", "IN", "MI", "OH")  # states of interest -- just a big culling step

# todo: support other res. besides 2048 x 2048
xrange <- c(-90.390833, -85.524167)
yrange <- c(39.463056, 43.214167)

map_scale <- 2048 - 3 # tile range goes from 1 to 2^n - 1
result_size <- 500 # how many cities to place on map


class_types <- c("PPL", "PPLA", "PPLA2", "PPLX") # Omit "PPLX" to exclude subdivisions