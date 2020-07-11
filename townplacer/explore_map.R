source("load_data.R")

# TODO: make this an interactive using leaflet or something

combined %>%
  ggplot() +
  geom_sf(color = 'grey') +
  geom_sf_text(data = of_interest %>% filter(indicator) %>% arrange(-population), aes(label = name), size = 3, check_overlap = T) +
  coord_sf(xlim = xrange, ylim = yrange) +
  ggsave("map.png")
