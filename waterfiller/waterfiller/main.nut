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

}

function Main::Print(string) {
    GSLog.Info((GSDate.GetSystemTime() % 3600) + " " + string);
}

function Main::Save()
{
    return null;
}
