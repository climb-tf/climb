#include "commands/general_commands.sp"
#include "commands/admin_commands.sp"

public void RegisterCommands()
{
    Commands_RegisterGeneralCommands();
    PlayerTimes_RegisterCommands();
    MapSpawn_RegisterCommands();
    Checkpoints_RegisterCommands();
    Commands_RegisterAdminCommands();
    HudDisplay_RegisterCommands();
}