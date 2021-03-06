sts <- c(
  "NY",
  "MA",
  "DE",
  "MD",
  "VA",
  "WV",
  "NH",
  "ME",
  "CT",
  "NJ",
  "PA",
  "RI",
  "DC"
)

countries <- c(
  "JP"
)

x_bound <- 4096
y_bound <- 4096

# helper function: just goes between degrees and decimals
to_decimal <- function(angle, minutes, seconds) {
  angle + minutes / 60 + seconds / 3600
}

map_scale_x <- x_bound - 3 # tile range goes from 1 to 2^n - 1; the extra 1 is because the formula is 1 + map_scale * factor, where factor ranges from 0 to 1
map_scale_y <- y_bound - 3


class_types <- c(
  "PPL",
  "PPLA",
  "PPLA2",
  "PPLA3",
  "PPLA4",
  "PPLA5",
  "PPLC",
  "PPLF",
  "PPLG",
  "PPLL",
  "PPLR",
  "PPLS",
  "RSTN",
  "PPLX"
  ) # Omit "PPLX" to exclude subdivisions

scenario_name <- "tokyo"
river_scale <- 25
map_crs <- sp::CRS("+init=EPSG:4326")
map_crs <- sp::CRS("+init=EPSG:4301")
map_crs <- sp::CRS("+proj=tmerc +lat_0=35.685036 +lon_0=139.752813")
