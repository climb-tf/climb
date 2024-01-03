
float restoreLocations[MAXPLAYERS + 1][3];
float restoreAngles[MAXPLAYERS + 1][3];

bool restoredLocation[MAXPLAYERS + 1];

public void LocationRestore_RegisterCommands()
{
    RegConsoleCmd("sm_restore", Command_Restore, "Restores your previous session's position.");
}

public Action Command_Restore(int client, int args)
{
    if(restoreLocations[client][0] == 0)
    {
        Chat_SendMessage(client, "No previous session to found.");
        return;
    }

    float fVelocity[3] = {0.0, 0.0, 0.0};
    TeleportEntity(client, restoreLocations[client], restoreAngles[client], fVelocity);
    Chat_SendMessage(client, "You have been teleported to your last position.");
}

public void LocationRestore_SaveToDatabase(int client)
{
    if(!Checkpoints_HasCheckpoint(client)) {
        return;
    }

	char map[64];
	GetCurrentMap(map, sizeof(map));

	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

	int classIdx = TF_GetClassType(client);

    char query[512];
    FormatEx(query, sizeof(query),
        "INSERT INTO saved_locations (steam_id, map_name, class_idx, x, y, z, pitch, yaw, timer) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') ON CONFLICT (steam_id, map_name, class_idx) DO UPDATE SET x = '%s', y = '%s', z = '%s', pitch = '%s', yaw = '%s', time = '%s'",
        steamId, map, classIdx,
        g_fSaveLocation[client][0], g_fSaveLocation[client][1], g_fSaveLocation[client][2], g_fSaveAngles[client][0], g_fSaveAngles[client][1], Timer_Get(client),
        g_fSaveLocation[client][0], g_fSaveLocation[client][1], g_fSaveLocation[client][2], g_fSaveAngles[client][0], g_fSaveAngles[client][1], Timer_Get(client)
    );

    SQL_TQuery(db, LocationRestore_SavedToDatabase, query, client);
}

public void LocationRestore_SavedToDatabase(Handle owner, Handle hndl, const char[] error, any data)
{

}

public void LocationRestore_LoadFromDatabase(int client)
{
    if(restoredLocation[client]) {
        return;
    }

    char map[64];
    GetCurrentMap(map, sizeof(map));

    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

    int classIdx = TF_GetClassType(client);

    char query[512];
    FormatEx(query, sizeof(query),
        "SELECT class_idx, x, y, z, pitch, yaw, time FROM saved_locations FROM saved_locations WHERE steam_id = '%s' AND map_name = '%s' AND class_idx = '%s'",
        steamId, map, classIdx
    );

    SQL_TQuery(db, LocationRestoreLoadedFromDatabase, query, client);
}


public void LocationRestoreLoadedFromDatabase(Handle owner, Handle hndl, const char[] error, any client)
{
    if(!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) == 0) {
        return;
    }

    SQL_FetchRow(hndl);
    int classIdx = SQL_FetchFloat(hndl, 0);
    float posX = SQL_FetchFloat(hndl, 1);
    float posY = SQL_FetchFloat(hndl, 2);
    float posZ = SQL_FetchFloat(hndl, 3);
    float pitch = SQL_FetchFloat(hndl, 4);
    float yaw = SQL_FetchFloat(hndl, 5);

    //If for some reason there was a delay with the query and the player has since changed class, return.
    if(TF_GetClassType(client) != classIdx || posX == 0)
    {
        return;
    }

    restoreLocations[client][0] = posX;
    restoreLocations[client][1] = posY;
    restoreLocations[client][2] = posZ;

    restoreAngles[client][0] = pitch;
    restoreAngles[client][1] = yaw;

    Chat_SendMessage(client, "Your location from your last session on this map has been restored. Type /restore to teleport there.");
}