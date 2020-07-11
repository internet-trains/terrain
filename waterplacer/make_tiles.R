
read_watertiles <- function(filename) {
  read_csv(filename, col_names = FALSE) %>%
    mutate(filename = filename)
}

path <- "waterfiller"
data <-
  file.path(path, list.files(path, pattern = ".csv")) %>%
  map(read_watertiles) %>%
  reduce(bind_rows)

colnames(data) <- c("y", "x", "file") # swap these depending on cw or ccw

# dedupe

data <- data %>%
  distinct(x, y, .keep_all=T)


# coordinate fix -- the image processor assigns 0 0 to the upper left and OTTD depending on direction doesn't
# data <-
#   data %>%
#   mutate(y = 8191 - y) %>%
#   mutate(x = pmax(x - 1, 1))
data <-
  data %>%
  arrange(y, x)

# write to OTTD format
out_str <- paste0(
  "require(\"version.nut\")
class Main extends GSController
{
    company_id = 0;
    constructor()
    {
    }
}

function Main::Save()
{
    return {};
}
// Load function
function Main::Load() {
}

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
  paste0(data$y, collapse = ','), # reverse these if ottd is ccw
  "];
    local y = [",
  paste0(data$x, collapse = ','),
  "];

    for(local i = 0; i < x.len(); i++) {
        local cur_tile = GSMap.GetTileIndex(x[i], y[i]);
        if(!(GSTile.IsCoastTile(cur_tile) || GSTile.IsWaterTile(cur_tile))) {
            FillCash(company_id);
            local mode = GSCompanyMode(company_id);
            GSTile.DemolishTile(cur_tile);
            GSMarine.BuildCanal(cur_tile);
        }
    }
}
")

fileconn <- file("main.nut")
writeLines(out_str, fileconn)
close(fileconn)
