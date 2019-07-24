source("load_data.R")
# Rasterization step
# do we need to reproject or can we assume its square grid

to_map <- of_interest_cull %>% 
  filter(class %in% class_types) %>%
  filter(indicator) %>% 
  filter(population > 0) %>%
  arrange(-population)


names <- to_map %>% filter(indicator) %>% filter(population > 0) %>% .$name
coords <- to_map %>% st_coordinates()

# out of range coords
xvec <- coords[,1]
yvec <- coords[,2]

in_x <- between(xvec, xrange[1], xrange[2])
in_y <- between(yvec, yrange[1], yrange[2])

both <- in_y & in_x

xvec <- coords[both, 2]
yvec <- coords[both, 1]
names <- names[both]


xvec <- floor(1 + map_scale * ((max(xvec) - xvec)) / (max(xvec) - min(xvec)))
yvec <- floor(1 + map_scale * (yvec - min(yvec)) / (max(yvec) - min(yvec)))

xstr <- paste0("[", paste0(xvec[1:result_size], collapse=','), "]")
ystr <- paste0("[", paste0(yvec[1:result_size], collapse=','), "]")
namestr <- paste0("[", paste0("\"", names[1:result_size], "\"", collapse=','), "]")

