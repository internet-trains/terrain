source("util/load_png.R")

# for fun, switch the order of the data
# (controls which way the water is 'scanned' in in game)
data <- data %>%
  arrange(x, y)

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

function Main::Start()
{
    Sleep(1);

    local x = [",
  paste0(data$x-1, collapse = ','), # reverse these if ottd is ccw
   "];
    local y = [",
  paste0(data$y-1, collapse = ','),
   "];

    for(local i = 0; i < x.len(); i++) {
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        if(!(GSTile.IsCoastTile(cur_tile) || GSTile.IsWaterTile(cur_tile))) {
            GSTile.DemolishTile(cur_tile);
            GSMarine.BuildRiver(cur_tile);
        }
    }
}
")

fileconn <- file("~/Documents/OpenTTD/game/waterplacer/main.nut")
writeLines(out_str, fileconn)
close(fileconn)
