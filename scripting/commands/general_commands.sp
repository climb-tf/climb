bool g_bThirdPerson[MAXPLAYERS + 1];

public void Commands_RegisterGeneralCommands()
{
	RegConsoleCmd("sm_menu", Command_Menu, "Open run menu.");
	RegConsoleCmd("sm_help", Command_Help, "Shows available commands");
	RegConsoleCmd("sm_discord", Command_Discord, "Display the Discord server");
	RegConsoleCmd("sm_thirdperson", Command_Thirdperson, "Toggle Thirdperson");
	RegConsoleCmd("sm_firstperson", Command_Thirdperson, "Toggle Thirdperson");
	RegConsoleCmd("sm_noclip", Command_Noclip, "Toggle noclip");
	RegConsoleCmd("sm_goto", Command_Goto, "Toggle noclip");
}

public Action Command_Menu(int client, int iArgs) {
	OpenMenu(client, MENU_CLIMBMENU);
	return Plugin_Handled;
}

public Action Command_Discord(int client, int iArgs) {
	Chat_SendMessage(client, "{blue}https://climb.tf/discord");
	Chat_SendMessage(client, "{blue}https://discord.gg/7bju2XTYkT");
	return Plugin_Handled;
}

public Action Command_Help(int client, int iArgs)
{
    char validCommands[][][] = {
        {"!menu", "Dialog for saving a checkpoint, teleporting, and restarting"},
        {"!mhud", "Indicators for H-Speed, bhop and movement keys"},
        {"!wr", "Prints the world record for the map"},
        {"!pb", "Prints your personal best times"},
        {"!restart, !r", "Restarts the map (sm_restart)"},
        {"!saveloc, !s, !cp", "Saves a checkpoint (sm_saveloc)"},
        {"!tp", "Teleports to your recent checkpoint (sm_tp)"},
        {"!mapinfo, !mi", "Shows info about the map"},
        {"!timer", "Toggles the on-screen timer"},
        {"!settings", "Change settings related to the server."},
        {"!thirdperson, !firstperson", "Toggle thirdperson"},
        {"!discord", "Display the Discord server."}
    };

    for(int i = 0; i < sizeof(validCommands); i++)
    {
        Chat_SendMessage(client, "{blue}%s {grey}-{white} %s", validCommands[i][0], validCommands[i][1]);
    }

	return Plugin_Handled;
}

public Action Command_Thirdperson(int client, int iArgs) {
    if(!IsPlayerAlive(client)) {
        Chat_SendMessage(client, "{default}You must be alive to use this command.");
        return Plugin_Handled;
    }

    g_bThirdPerson[client] = !g_bThirdPerson[client];

    SetVariantInt(g_bThirdPerson[client] ? 1 : 0);
    AcceptEntityInput(client, "SetForcedTauntCam");

    PrintToChat(client, "Thirdperson toggled.");

	return Plugin_Handled;
}

public Action Command_Noclip(int client, int iArgs) {
    if (client< 1 || !IsClientInGame(client) || !IsPlayerAlive(client)) {
        Chat_SendMessage(client, "{default}You must be alive to use this command.");
        return Plugin_Handled;
    }

    float bestTime107 = PlayerTimes_GetPlayerBest(client, MEDIC_SPY);
    float bestTime100 = PlayerTimes_GetPlayerBest(client, SNIPER_ENGIE_PYRO);

    if(GetUserAdmin(client) == INVALID_ADMIN_ID && bestTime107 == 0 && bestTime100 == 0) {
        Chat_SendMessage(client, "You must complete the map first.");
        return Plugin_Handled;
    }

    if (GetEntityMoveType(client) != MOVETYPE_NOCLIP) {
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
        Chat_SendMessage(client, "{default}noclip {green}enabled{default}. If your timer was running, it's been disabled.");
        Timer_Reset(client);
    } else {
        SetEntityMoveType(client, MOVETYPE_WALK);
        Chat_SendMessage(client, "{default}noclip {red}disabled.");
    }

    float fVelocity[3] = {0.0, 0.0, 0.0};
    Movement_SetVelocity(client, fVelocity);

	return Plugin_Handled;
}

public Action Command_Goto(int client, int args)
{
    if (args < 1)
    {
        Chat_SendMessage(client, "Usage: goto <name>");
        return Plugin_Handled;
    }

    float bestTime107 = PlayerTimes_GetPlayerBest(client, MEDIC_SPY);
    float bestTime100 = PlayerTimes_GetPlayerBest(client, SNIPER_ENGIE_PYRO);

    if(GetUserAdmin(client) == INVALID_ADMIN_ID && bestTime107 == 0 && bestTime100 == 0) {
        Chat_SendMessage(client, "You must complete the map first.");
        return Plugin_Handled;
    }

    char name[32];
    GetCmdArg(1, name, sizeof(name));

    int target = FindPlayer(name);

    if(target == -1)
    {
        Chat_SendMessage(client, "Unable to find a player with that name.");
        return Plugin_Handled;
    }

    if(target == client)
    {
        Chat_SendMessage(client, "You can't teleport yourself.");
        return Plugin_Handled;
    }

    if(Timer_IsActive(client))
    {
        Timer_Reset(client);
        Chat_SendMessage(client, "Timer reset due to teleporting.");
    }

    float fVelocity[3] = {0.0, 0.0, 0.0};
    float targetLoc[3];
    float targetAng[3];

    GetClientAbsOrigin(target, targetLoc);
    GetClientAbsAngles(target, targetAng);

    TeleportEntity(client, targetLoc, targetAng, fVelocity);

	return Plugin_Handled;
}