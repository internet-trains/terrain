# least squares solver
# input_coords should be lon, lat
# output coords if CCW should be y, x

# this is tokyo setting
input_coords <- matrix(data = c(
  138.730582, 35.362493, 1,
  140.859025, 35.739034, 1,
  138.878135, 36.476586, 1), ncol = 3, byrow=T)
output_coords <- matrix(data = c(
  318, 3056, 1,
  4007, 2253, 1,
  573, 695, 1
), ncol = 3, byrow = T)

# input_coords <- matrix(data = c(
#   -77.024620, 38.867924, 1,
#   -73.922911, 41.877520, 1,
#   -70.240975, 42.064169, 1), ncol = 3, byrow=T)
# output_coords <- matrix(data = c(
#   1224, 7151, 1,
#   36, 3413, 1,
#   1492, 901, 1
# ), ncol = 3, byrow = T)

# Baltic
input_coords <- matrix(data = c(
  21.189727, 55.340904, 1,
  29.853561, 53.423180, 1,
  28.101029, 59.787783, 1), ncol = 3, byrow=T)
output_coords <- matrix(data = c(
  553, 2731, 1,
  3392, 3856, 1,
  2817, 123, 1
), ncol = 3, byrow = T)

results <- solve(t(input_coords) %*% input_coords) %*% t(input_coords) %*% output_coords

results

generate_tile_coords <- function(lon, lat) {
  matrix(data = c(lon, lat, 1), ncol = 3, byrow = T) %*% results
}

remove(input_coords)
remove(output_coords)
