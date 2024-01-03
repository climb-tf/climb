#include <sdkhooks>
#include <sdktools>
#include <sdktools_trace>
#include <sourcemod>
#include <tf2_stocks>
#include <smlib>
#include <morecolors>
#include <devzones>
#include <movement>
#include <movementapi>
#include <dhooks>

#include "tf2utils.sp"
#include "api/website_api.sp"
#include "database/db_settings.sp"
#include "chat_utils.sp"
#include "database/db_handler.sp"
#include "spawn/mapspawn.sp"
#include "messages/messagecycle.sp"
#include "events/event_handler.sp"
#include "events/event_register.sp"
#include "fixes.sp"
#include "checkpoints.sp"
#include "climb_player.sp"
#include "chat_reporter.sp"
#include "location_restore.sp"
#include "timer.sp"
#include "gui/hud_display.sp"

#include "run_handler.sp"
#include "gui/menu_facilitator.sp"

#include "commands/command_registerer.sp"
#include "jumpstats/jumpstats.sp"


public Plugin myinfo =
{
    name = "climb",
    author = "pants",
    description = "climb.tf sourcemod plugin",
    version = "1.0.0",
    url = "https://github.com/climb-tf/climb"
};

public void OnPluginStart()
{
    LoadTranslations("climb.phrases");
    //db = SQL_Connect("climb", false, error, sizeof(error));

    PlayerTimes_OnPluginStart();

    //Database_Init();

    Fixes_Init();
    Events_Init();

    RegisterCommands();
}

bool IsValidClient(int client)
{
    return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}
