source("util/load_png.R")

library(data.table)
library(dtplyr)

# Tile tree state in OTTD has 5 states
# 0-4 trees on a tile
# For our purposes let's just specify the breakpoints here between PNG brightness and the states
tree_breaks <- c(0, .2, .4, .6, .8, 1)

data <-
  data %>%
  mutate(tree_count = as.integer(as.character(cut(value, breaks = tree_breaks, labels = 0:4)))) %>%
  filter(tree_count > 0, x > 1, y > 1) %>%
  select(-value)

# if OTTD is ccw
# data <-
#   data %>%
#   rename(y = x, x = y)

# Axis here means the coordinate axis that indexes things to be compressed
# So axis = x means that it's being squashed against the y axis, since each x value is our index
# i.e. our result will be for each x coordinate a bunch of y locations and lengths
compress_map <- function(data, axis) {
  data <- data %>% lazy_dt()
  if(axis == "x") {
    results <- data %>%
      group_by(x) %>%
      mutate(cont_1 = y == lag(y) + 1) %>%
      mutate(cont_1 = ifelse(is.na(cont_1), F, cont_1)) %>%
      mutate(group_id = cumsum(!cont_1)) %>%
      group_by(x, group_id) %>%
      mutate(length = row_number()) %>%
      mutate(length_adj = (length - 1) %% 20 + 1, group_adj = floor((length - 1) / 20)) %>%
      mutate(group_id_adj = paste0(group_id, "_", group_adj)) %>%
      group_by(x, group_id_adj) %>%
      summarize(start = min(y), length = max(length_adj)) %>%
      ungroup() %>%
      select(x, y = start, length) %>%
      as_tibble()
  }
  if(axis == "y") {
    results <- data %>%
      group_by(y) %>%
      mutate(cont_1 = x == lag(x) + 1) %>%
      mutate(cont_1 = ifelse(is.na(cont_1), F, cont_1)) %>%
      mutate(group_id = cumsum(!cont_1)) %>%
      group_by(y, group_id) %>%
      mutate(length = row_number()) %>%
      mutate(length_adj = (length - 1) %% 20 + 1, group_adj = floor((length - 1) / 20)) %>%
      mutate(group_id_adj = paste0(group_id, "_", group_adj)) %>%
      group_by(y, group_id_adj) %>%
      summarize(start = min(x), length = max(length_adj)) %>%
      ungroup() %>%
      select(x = start, y, length) %>%
      as_tibble()
  }
  results
}

level1_comp_x <- data %>%
  filter(tree_count > 0) %>%
  compress_map("x")
level1_comp_y <- data %>%
  filter(tree_count > 0) %>%
  compress_map("y")

level2_comp_x <- data %>%
  filter(tree_count > 1) %>%
  compress_map("x")
level2_comp_y <- data %>%
  filter(tree_count > 1) %>%
  compress_map("y")

level3_comp_x <- data %>%
  filter(tree_count > 2) %>%
  compress_map("x")
level3_comp_y <- data %>%
  filter(tree_count > 2) %>%
  compress_map("y")

level4_comp_x <- data %>%
  filter(tree_count > 3) %>%
  compress_map("x")
level4_comp_y <- data %>%
  filter(tree_count > 3) %>%
  compress_map("y")

# So when assessing direction, if compression is better by indexing on the x-axis
# and compressing along the y-axis then we choose that direction
# i.e. we loop over every x-coordinate and drop rectangles defined in the y-direction
# This is also what the game calls 'height' (dimension in the y-direction)
axis_1 <- ifelse(nrow(level1_comp_x) < nrow(level1_comp_y), "x", "y")
axis_2 <- ifelse(nrow(level2_comp_x) < nrow(level2_comp_y), "x", "y")
axis_3 <- ifelse(nrow(level3_comp_x) < nrow(level3_comp_y), "x", "y")
axis_4 <- ifelse(nrow(level4_comp_x) < nrow(level4_comp_y), "x", "y")

if(axis_1 == "x") {
  level1 <- level1_comp_x %>% arrange(x, y) %>% mutate(axis = axis_1)
} else {
  level1 <- level1_comp_y %>% arrange(y, x) %>% mutate(axis = axis_1)
}

if(axis_2 == "x") {
  level2 <- level2_comp_x %>% arrange(x, y) %>% mutate(axis = axis_2)
} else {
  level2 <- level2_comp_y %>% arrange(y, x) %>% mutate(axis = axis_2)
}

if(axis_3 == "x") {
  level3 <- level3_comp_x %>% arrange(x, y) %>% mutate(axis = axis_3)
} else {
  level3 <- level3_comp_y %>% arrange(y, x) %>% mutate(axis = axis_3)
}

if(axis_4 == "x") {
  level4 <- level4_comp_x %>% arrange(x, y) %>% mutate(axis = axis_4)
} else {
  level4 <- level4_comp_y %>% arrange(y, x) %>% mutate(axis = axis_4)
}

joined <-
  bind_rows(
    level1,
    level2,
    level3,
    level4
  )

# write to OTTD format
out_str <- paste0(
  "
require(\"version.nut\")
class Main extends GSController
{
    company_id = 0;
    constructor() {};
}

function Main::Save()
{
    return {};
}

// Load function
function Main::Load() {}

function Main::FillCash(company_id) {
    if(GSCompany.GetBankBalance(company_id) < 20000000) {
       GSCompany.ChangeBankBalance(company_id, 1800000000, GSCompany.EXPENSES_OTHER);
   }
}

function Main::Start()
{
    Sleep(1);
    company_id = GSCompany.ResolveCompanyID(GSCompany.COMPANY_FIRST);
    local x = [",
  paste0(joined$x-1, collapse = ','),
   "];
    local y = [",
  paste0(joined$y-2, collapse = ','),
   "];
    local sizes = [",
  paste0(joined$length, collapse = ','),
   "];
    // Plant trees one at a time in rectangles
    GSLog.Warning(\"Level 1\");
    for(local i = 0; i < ", nrow(level1), "; i++) {
        FillCash(company_id);
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        local mode = GSCompanyMode(company_id);
        GSTile.PlantTreeRectangle(cur_tile, ", ifelse(axis_1 == 'x', '1, sizes[i]', 'sizes[i], 1'), ")
    }
    GSLog.Warning(\"Level 2\");
    for(local i = ", nrow(level1), "; i < ", nrow(level1) + nrow(level2), "; i++) {
        FillCash(company_id);
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        local mode = GSCompanyMode(company_id);
        GSTile.PlantTreeRectangle(cur_tile, ", ifelse(axis_2 == 'x', '1, sizes[i]', 'sizes[i], 1'), ")
    }
    GSLog.Warning(\"Level 3\");
    for(local i = ", nrow(level1) + nrow(level2), "; i < ", nrow(level1) + nrow(level2) + nrow(level3), "; i++) {
        FillCash(company_id);
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        local mode = GSCompanyMode(company_id);
        GSTile.PlantTreeRectangle(cur_tile, ", ifelse(axis_3 == 'x', '1, sizes[i]', 'sizes[i], 1'), ")
    }
    GSLog.Warning(\"Level 4\");
    for(local i = ", nrow(level1) + nrow(level2) + nrow(level3), "; i < ", nrow(level1) + nrow(level2) + nrow(level3) + nrow(level4), "; i++) {
        FillCash(company_id);
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        local mode = GSCompanyMode(company_id);
        GSTile.PlantTreeRectangle(cur_tile, ", ifelse(axis_4 == 'x', '1, sizes[i]', 'sizes[i], 1'), ")
    }
    GSLog.Warning(\"Done\");
}
")

fileconn <- file("~/Documents/OpenTTD/game/treeplacer/main.nut")
writeLines(out_str, fileconn)
close(fileconn)

