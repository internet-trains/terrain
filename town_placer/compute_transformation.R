# least squares solver
# input_coords should be lon, lat
# output coords if CCW should be y, x

input_coords <- matrix(data = c(
  -70.196665, 42.065710, 1,
  -77.027192, 38.872778, 1,
  -73.964454, 41.574135, 1), ncol = 3, byrow=T)
output_coords <- matrix(data = c(
  1467, 460, 1,
  1200, 7236, 1,
  150, 3419, 1
), ncol = 3, byrow = T)

results <- solve(t(input_coords) %*% input_coords) %*% t(input_coords) %*% output_coords

results

generate_tile_coords <- function(lon, lat) {
  matrix(data = c(lon, lat, 1), ncol = 3, byrow = T) %*% results
}
