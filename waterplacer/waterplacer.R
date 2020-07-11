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

function Main::FillCash(company_id) {
    if(GSCompany.GetBankBalance(company_id) < 20000000) {
        GSCompany.ChangeBankBalance(company_id, 1800000000, GSCompany.EXPENSES_OTHER);
    }
}

function Main::Start()
{
    Sleep(1);
    company_id = GSCompany.ResolveCompanyID(GSCompany.COMPANY_FIRST);
    FillCash(company_id);

    local x = [",
  paste0(data$x-1, collapse = ','), # reverse these if ottd is ccw
   "];
    local y = [",
  paste0(data$y-1, collapse = ','),
   "];

    for(local i = 0; i < x.len(); i++) {
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        if(!(GSTile.IsCoastTile(cur_tile) || GSTile.IsWaterTile(cur_tile))) {
            GSLog.Warning(i);
            FillCash(company_id);
            local mode = GSCompanyMode(company_id);
            GSTile.DemolishTile(cur_tile);
            GSMarine.BuildCanal(cur_tile);
        }
    }
}
")

fileconn <- file("~/Documents/OpenTTD/game/waterplacer/main.nut")
writeLines(out_str, fileconn)
close(fileconn)
