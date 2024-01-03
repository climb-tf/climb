int g_iNextEntity = 0;

public void Commands_RegisterAdminCommands()
{
	RegAdminCmd("sm_here", Command_Here, 1, "Brings a player to you");

	RegAdminCmd("sm_debug", Command_Debug, 1, "Brings a player to you");
	RegAdminCmd("sm_tpdest", Command_TpDest, 1, "Goto a info_teleport_destination entity");
	RegAdminCmd("sm_findstuck", Command_FindStuck, 1, "Goto a info_teleport_destination entity");

	RegAdminCmd("sm_psbroadcast", Command_PlaySoundBroadcast, 1, "Broadcasts a sound to the server");
	//RegAdminCmd("sm_godmode", Command_Here, 0, "Brings a player to you");

	//RegConsoleCmd("sm_delete", Command_Here, "Deletes a players time on a map");

    RegAdminCmd("sm_testapi", Command_TestApi, 1, "Tests an API");
    RegAdminCmd("sm_testapi2", Command_TestApi2, 1, "Tests an API");
}

public Action Command_TestApi(int client, int args)
{
    PlayerTimes_GetMapsRuns("kz_height_a4", 0);
    PlayerTimes_GetMapsRuns("kz_height_a4", 1);

    char destName[32];
    GetCmdArg(1, destName, sizeof(destName));
}

public Action Command_TestApi2(int client, int args)
{
}

public Action Command_PlaySoundBroadcast(int client, int args)
{
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientConnected(i) || !IsClientInGame(client)) {
            continue;
        }

        PlayJumpstatSound(i, 3);
    }
 }

public Action Command_Debug(int client, int args)
{
    g_bDebugEnabled[client] = !g_bDebugEnabled[client];
    Chat_SendMessage(client, "Toggled debug mode: %s", (g_bDebugEnabled[client] ? "{green}on" : "{red}off"));
    Chat_Debug(client, "Test debug message!");
    return Plugin_Handled;
}

public Action Command_FindStuck(int client, int args)
{
    static float emptyVec[3];

    int skipped = 0;

    char targetname[256];
    int entity;

    float entityPos[3];
    float entityAng[3];

     while ((entity = FindEntityByClassname(entity, "info_teleport_destination")) != -1) {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

        if(StrContains(targetname, "tp_", false) == -1) {
            continue;
        }

        if(skipped++ != g_iNextEntity) {
            continue;
        }

        g_iNextEntity++;


        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
        GetEntPropVector(entity, Prop_Data, "m_angRotation", entityAng);

        TeleportEntity(client, entityPos, entityAng, emptyVec);
        Chat_SendMessage(client, "Teleported to {red}%s{default}. Postion: %f, %f, %f", targetname, entityPos[0], entityPos[1], entityPos[2]);

        return Plugin_Handled;
     }
    return Plugin_Handled;
}

public Action Command_TpDest(int client, int args)
{
    static float emptyVec[3];

    char destName[32];
    GetCmdArg(1, destName, sizeof(destName));

    char targetname[256];

    int entity;

    float entityPos[3];
    float entityAng[3];

    while ((entity = FindEntityByClassname(entity, "info_teleport_destination")) != -1) {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

        if(StrEqual(targetname, destName)) {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
            GetEntPropVector(entity, Prop_Data, "m_angRotation", entityAng);

            TeleportEntity(client, entityPos, entityAng, emptyVec);
            Chat_SendMessage(client, "Teleported to {red}%s{default}. Postion: %f, %f, %f", destName, entityPos[0], entityPos[1], entityPos[2]);
            return Plugin_Handled;
        }
    }

    return Plugin_Handled;
}

public Action Command_Here(int client, int args)
{
    if (args < 1)
    {
        Chat_SendMessage(client, "Usage: here <name>");
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

    float fVelocity[3] = {0.0, 0.0, 0.0};
    float clientLoc[3];
    float clientAng[3];

    GetClientAbsOrigin(client, clientLoc);
    GetClientAbsAngles(client, clientAng);

    TeleportEntity(target, clientLoc, clientAng, fVelocity);

    if(Timer_IsActive(target))
    {
        Timer_Reset(target);
        Chat_SendMessage(target, "Timer reset due to being teleported.");
    }

	return Plugin_Handled;
}

public Action Command_Delete(int client, int iArgs)
{
	return Plugin_Handled;
}

public int FindPlayer(char[] name)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i))
        {
            continue;
        }

        char other[32];
        GetClientName(i, other, sizeof(other));

        if (StrContains(other, name, false) != -1)
        {
            return i;
        }
    }

    return -1;
}