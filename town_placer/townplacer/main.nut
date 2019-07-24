require("version.nut")
class Main extends GSController
{
    constructor()
    {
    }
}

function Main::Start()
{
    Sleep(1); // don't have this happen during world gen, but after we've 'loaded'

    local x = 
    local y = 
    local names = 

    for(local i = 0; i < 461; i++) {
        if (i < 10) {
            GSTown.FoundTown(GSMap.GetTileIndex(x[i], y[i]), GSTown.TOWN_SIZE_LARGE, true, GSTown.ROAD_LAYOUT_3x3, names[i]);
        } else if (i < 50) {
            GSTown.FoundTown(GSMap.GetTileIndex(x[i], y[i]), GSTown.TOWN_SIZE_LARGE, false, GSTown.ROAD_LAYOUT_3x3, names[i]);
        } else if (i < 100) {
            GSTown.FoundTown(GSMap.GetTileIndex(x[i], y[i]), GSTown.TOWN_SIZE_MEDIUM, false, GSTown.ROAD_LAYOUT_3x3, names[i]);
        } else {
            GSTown.FoundTown(GSMap.GetTileIndex(x[i], y[i]), GSTown.TOWN_SIZE_SMALL, false, GSTown.ROAD_LAYOUT_3x3, names[i]);
        }
    }
}

function Main::Print(string) {
    GSLog.Info((GSDate.GetSystemTime() % 3600) + " " + string);
}

function Main::Save()
{
    return null;
}
