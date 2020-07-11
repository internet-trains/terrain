# Reads a PNG and spits out non-blank tiles
library(tidyverse)
library(png)

image_path <- file.choose()
image_data <- readPNG(image_path)
data <- image_data %>%
  as.table() %>%
  as.data.frame(stringsAsFactors = F) %>%
  filter(Freq != 0) %>%
  mutate(bigVar1 = as.integer(gsub("[A-Z]", "", Var1)),
         bigVar1 = ifelse(is.na(bigVar1), 0, bigVar1),
         smallVar1 = match(gsub("[0-9]", "", Var1), LETTERS),
         bigVar2 = as.integer(gsub("[A-Z]", "", Var2)),
         bigVar2 = ifelse(is.na(bigVar2), 0, bigVar2),
         smallVar2 = match(gsub("[0-9]", "", Var2), LETTERS),
         x = 26 * bigVar1 + smallVar1,
         y = 26 * bigVar2 + smallVar2
  ) %>%
  select(x, y, value = Freq)
remove(image_path)
remove(image_data)
