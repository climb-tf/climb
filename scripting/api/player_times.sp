ArrayList g_SpyRuns;
ArrayList g_SniperRuns;

enum struct PlayerTime
{
    char steamId[32];
    char username[64];
    float runTime;

    void Init(char steamId[32], char username[64], float runTime) {
        this.steamId = steamId;
        this.username = username;
        this.runTime = runTime;
    }
}

public void PlayerTimes_OnClientAuthorized(int client, const char[] steam_id)
{
    char username[32];
    GetClientName(client, username, sizeof(username));

    UpdateCachedUsername(g_SpyRuns, steam_id, username);
    UpdateCachedUsername(g_SniperRuns, steam_id, username);
}

static void UpdateCachedUsername(ArrayList array, const char[] steam_id, char username[32]) {
    for(int i = 0; i < array.Length; i++){
        PlayerTime time;
        array.GetArray(i, time);

        if(StrEqual(time.steamId, steam_id, false)) {
            time.username = username;
            return;
        }
    }
}

public void PlayerTimes_CompleteMap(int client)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    if(!Timer_IsActive(client))
    {
        char szTime[256];
        FormatEx(szTime, sizeof(szTime), "{blue}%N{default} has completed {blue}%s{default} (timer not active)", client, map);
        Chat_Broadcast(szTime);
        return;
    }

    int currentClassId = TF_GetClassType(client);

    float timeSince = Timer_Complete(client);

    float personalBest = PlayerTimes_GetPlayerBest(client, currentClassId);
    float mapRecord = PlayerTimes_GetRecord(currentClassId);

    int teleportCount = Checkpoints_GetTeleports(client);

    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

    char differenceMsg[32];
    GetDifferenceMessage(differenceMsg, sizeof(differenceMsg), timeSince, personalBest);

    //Build message
    char timeStr[32];
    Timer_FormatTime(timeSince, timeStr, sizeof(timeStr));

    char classTypeName[22];
    TF_GetClassTypeName(currentClassId, classTypeName, sizeof(classTypeName));

    char placementText[32];
    if(personalBest == 0 || timeSince < personalBest) {
        CreatePlacementText(placementText, client, currentClassId);
    } else {
        Format(placementText, sizeof(placementText), "");
    }

    char szTime[256];
    FormatEx(szTime, sizeof(szTime), "{blue}%N{default} has completed {blue}%s{default} in %s{default} %s {default}as {blue}%s%s", client, map, timeStr, differenceMsg, classTypeName, placementText);
    Chat_Broadcast(szTime);

    if(timeSince < mapRecord)
    {
        char beatRecordMsg[256];

        char recordDifferenceMsg[32];
        GetDifferenceMessage(recordDifferenceMsg, sizeof(recordDifferenceMsg), timeSince, mapRecord);

        FormatEx(beatRecordMsg, sizeof(beatRecordMsg), "{blue}%N{default} set a new {blue}%s{default} map record beating the previous by {green}%s{default}!", client, classTypeName, recordDifferenceMsg);
        Chat_Broadcast(beatRecordMsg);
    } else if (mapRecord == 0) {
        char beatRecordMsg[256];
        FormatEx(beatRecordMsg, sizeof(beatRecordMsg), "{blue}%N{default} set a new {blue}%s{default} map record!", client, classTypeName);
        Chat_Broadcast(beatRecordMsg);
    }
    //Save time first before building and sending the message
    PlayerTimes_SaveTime(client, map, steamId, currentClassId, timeSince, teleportCount);

    if(timeSince < mapRecord) {
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientConnected(i) || !IsClientInGame(client)) {
                continue;
            }

            PlayJumpstatSound(i, 3);
        }
    } else if (timeSince < personalBest) {
        PlayJumpstatSound(client, 2);
    }
}

public bool PlayerTimes_HasTime(int client, int class_id)
{
    return PlayerTimes_GetPlayerBest(client, class_id) != 0;
}

public bool PlayerTimes_HasRecord(int classId)
{
    return PlayerTimes_GetRecord(classId) != 0;
}

public void PlayerTimes_GetMapRecord(int classIdx, PlayerTime playerTime)
{
    ArrayList arrayList;

    if(classIdx == MEDIC_SPY) {
        arrayList = g_SpyRuns;
    } else if(classIdx == SNIPER_ENGIE_PYRO) {
        arrayList = g_SniperRuns;
    }

    if(arrayList.Length == 0) {
        playerTime.runTime = 0;
        return;
    }

    arrayList.GetArray(0, playerTime);
}


public float PlayerTimes_GetRecord(int classIdx)
{
    PlayerTime playerTime;
    PlayerTimes_GetMapRecord(classIdx, playerTime);

    return playerTime.runTime;
}

public float PlayerTimes_GetPlayerBest(int client, int classIdx)
{
	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

    ArrayList arrayList;

    if(classIdx == MEDIC_SPY) {
        arrayList = g_SpyRuns;
    } else if(classIdx == SNIPER_ENGIE_PYRO) {
        arrayList = g_SniperRuns;
    }


    for(int i = 0; i < arrayList.Length; i++) {
        PlayerTime time;
        arrayList.GetArray(i, time);

        if(StrEqual(time.steamId, steamId, false)) {
            return time.runTime;
        }
    }

    return 0;
}

public void PlayerTimes_OnPluginStart()
{
    g_SpyRuns = new ArrayList(sizeof(PlayerTime));
    g_SniperRuns = new ArrayList(sizeof(PlayerTime));
}

public void PlayerTimes_RegisterCommands()
{
    RegConsoleCmd("sm_best", Command_GetBestTime, "Display your current best time on the map.");
    RegConsoleCmd("sm_pb", Command_GetBestTime, "Display your current best time on the map.");

    RegConsoleCmd("sm_wr", Command_GetWorldRecord, "Displays the map's world record.");
    RegConsoleCmd("sm_worldrecord", Command_GetWorldRecord, "Displays the map's world record.");
    RegConsoleCmd("sm_record", Command_GetWorldRecord, "Displays the map's world record.");

    RegConsoleCmd("sm_top", Command_GetTopRuns, "Displays the top runs.");
}

public void PlayerTimes_OnMapLoad()
{
    PrintToServer("[INFO] Loading player times from REST API");
    g_SpyRuns.Clear();
    g_SniperRuns.Clear();

    char map[64];
    GetCurrentMap(map, sizeof(map));

    PlayerTimes_GetMapsRuns(map, MEDIC_SPY);
    PlayerTimes_GetMapsRuns(map, SNIPER_ENGIE_PYRO);
}

public void PlayerTimes_SaveTime(int client, char[] map, char[] steam_id, int class_id, float run_time, int teleportCount)
{
    UpdateCachedTimes(client, steam_id, run_time, class_id);
}

void OnResponse_SaveTime(HTTPResponse response, any value) {
}


static void UpdateCachedTimes(int client, char[] steam_id, float run_time, int class_id)
{
    float currentBestTime = PlayerTimes_GetPlayerBest(client, class_id);

    if(currentBestTime != 0 && run_time > currentBestTime) {
        PrintToServer("User didn't beat previous best time. Not updating.");
        return;
    }

    PrintToServer("Updating PB for %s", steam_id);

    ArrayList arrayList;

    if(class_id == MEDIC_SPY) {
        arrayList = g_SpyRuns;
    } else if(class_id == SNIPER_ENGIE_PYRO) {
        arrayList = g_SniperRuns;
    }

    if(currentBestTime == 0) {
        PrintToServer("User's first time clearing the map, initializing cache.", steam_id);

        PlayerTime newTime;

        char username[64];
        GetClientName(client, username, sizeof(username));

        char steamIdLength[32];
        strcopy(steamIdLength, sizeof(steamIdLength), steam_id);

        newTime.Init(steamIdLength, username, run_time);

        arrayList.PushArray(newTime);

        SortPlayerTimes(class_id);

        return;
    }

    PrintToServer("User has cleared the map already, updating runtime value.", steam_id);

    for(int i = 0; i < arrayList.Length; i++) {
        PlayerTime time;
        arrayList.GetArray(i, time);

        if(StrEqual(time.steamId, steam_id, false)) {
            time.runTime = run_time;
            PrintToServer("runTime updated.", steam_id);
            arrayList.SetArray(i, time);
            break;
        }
    }

    SortPlayerTimes(class_id);
}

public void PlayerTimes_GetMapsRuns(char[] mapName, int classIdx) {
}

void GetMapRuns_OnRunsRetrieved(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK) {
        return;
    }

    PrintToServer("[INFO] Retrieved HTTP Response");
    JSONArray runs = view_as<JSONArray>(response.Data);
    int numRuns = runs.Length;

    JSONObject run;
    JSONObject userProfile;

    int classIdx = -1;

    for (int i = 0; i < numRuns; i++) {
        run = view_as<JSONObject>(runs.Get(i));
        userProfile = view_as<JSONObject>(run.Get("user"));

        float runTime = run.GetFloat("runTime");
        classIdx = run.GetInt("classId");

        char displayName[64];
        userProfile.GetString("username", displayName, sizeof(displayName));

        char steamId[32];
        userProfile.GetString("steamId", steamId, sizeof(steamId));

        PlayerTime playerTime;
        playerTime.Init(steamId, displayName, runTime);

        if(classIdx == MEDIC_SPY) {
            g_SpyRuns.PushArray(playerTime);
        } else if(classIdx == SNIPER_ENGIE_PYRO) {
            g_SniperRuns.PushArray(playerTime);
        }
    }

    if(classIdx != -1) {
        SortPlayerTimes(classIdx);
    }
}

void SortPlayerTimes(int classIdx) {
    if(classIdx == MEDIC_SPY) {
        g_SpyRuns.SortCustom(SortTimeArray);
    } else if(classIdx == SNIPER_ENGIE_PYRO) {
        g_SniperRuns.SortCustom(SortTimeArray);
    }
}

int SortTimeArray(int index1, int index2, Handle arrayHndl, Handle hndl) {
    ArrayList array = arrayHndl;

    PlayerTime left;
    array.GetArray(index1, left);

    PlayerTime right;
    array.GetArray(index2, right);

    return left.runTime < right.runTime ? 0 : 1;
}

static void GetDifferenceMessage(char[] buffer, int bufferLength, float time, float previousTime)
{
    if(previousTime == 0)
    {
        strcopy(buffer, bufferLength, "(No previous time)");
    }
    else if(time < previousTime)
    {
        char formattedTime[32];
        Timer_FormatTime(previousTime - time, formattedTime, sizeof(formattedTime));
        FormatEx(buffer, bufferLength, "({green}-%s{default})", formattedTime);
    }
    else
    {
        char formattedTime[32];
        Timer_FormatTime(time - previousTime, formattedTime, sizeof(formattedTime));
        FormatEx(buffer, bufferLength, "({red}+%s{default})", formattedTime);
    }
}

static void ReportClientPB(int client, int class_id, int current_class)
{
    char classTypeName[22];
    TF_GetClassTypeName(class_id, classTypeName, sizeof(classTypeName));

    float bestTime = PlayerTimes_GetPlayerBest(client, class_id);

    char time[32];

    if(bestTime == 0)
    {
        Format(time, sizeof(time), "{default}No Time");
    }
    else
    {
        Timer_FormatTime(bestTime, time, sizeof(time));
    }

    char placementText[32];
    CreatePlacementText(placementText, client, class_id);

    if(class_id == current_class)
    {
        Chat_SendMessage(client, "{default}[{blue}%s{default}] %s%s {arcana}(Current Class)", classTypeName, time, placementText);
    }
    else
    {
        Chat_SendMessage(client, "{default}[{blue}%s{default}] {default}%s%s", classTypeName, time, placementText);
    }
}

static void CreatePlacementText(char placementText[32], int client, int class_id)
{
    int placement = PlayerTimers_GetPlacement(client, class_id);

    if(placement != 0) {
        ArrayList arrayList;

        if(class_id == MEDIC_SPY) {
            arrayList = g_SpyRuns;
        } else if(class_id == SNIPER_ENGIE_PYRO) {
            arrayList = g_SniperRuns;
        }

        Format(placementText, sizeof(placementText), " {blue}(#%i/%i)", placement, arrayList.Length);
    } else {
        Format(placementText, sizeof(placementText), "");
    }
}

public int PlayerTimers_GetPlacement(int client, int class_id)
{
	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

    ArrayList arrayList;

    if(class_id == MEDIC_SPY) {
        arrayList = g_SpyRuns;
    } else if(class_id == SNIPER_ENGIE_PYRO) {
        arrayList = g_SniperRuns;
    }

    for(int i = 0; i < arrayList.Length; i++) {
        PlayerTime time;
        arrayList.GetArray(i, time);

        if(StrEqual(time.steamId, steamId, false)) {
            return i + 1;
        }
    }

    return 0;
}

public int PlayerTimers_GetTimePlacement(float runTime, int class_id)
{
    ArrayList arrayList;

    if(class_id == MEDIC_SPY) {
        arrayList = g_SpyRuns;
    } else if(class_id == SNIPER_ENGIE_PYRO) {
        arrayList = g_SniperRuns;
    }

    for(int i = 0; i < arrayList.Length; i++) {
        PlayerTime time;
        arrayList.GetArray(i, time);

        if(runTime < time.runTime) {
            return i + 1;
        }
    }

    return 0;
}

static void ReportWorldRecord(int client, int classId)
{
    char classTypeName[22];
    TF_GetClassTypeName(classId, classTypeName, sizeof(classTypeName));

    if(PlayerTimes_HasRecord(classId))
    {
        PlayerTime recordTime;
        PlayerTimes_GetMapRecord(classId, recordTime);

        char formattedTime[32];
        Timer_FormatTime(recordTime.runTime, formattedTime, sizeof(formattedTime));

        Chat_SendMessage(client, "{default}[{blue}%s{default}] {default}%s by {blue}%s", classTypeName, formattedTime, recordTime.username);
    }
    else
    {
        Chat_SendMessage(client, "{default}[{blue}%s{default}] No current record", classTypeName);
    }
}

public Action Command_GetBestTime(int client, int args)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    int currentClassId = TF_GetClassType(client);

    Chat_SendMessage(client, "Personal Bests for {blue}%s", map);

    ReportClientPB(client, MEDIC_SPY, currentClassId);
    ReportClientPB(client, SNIPER_ENGIE_PYRO, currentClassId);

    JumpstatApi_ReportPB(client, MEDIC_SPY);

    return Plugin_Handled;
}

public Action Command_GetTopRuns(int client, int args)
{
    int maxLength = g_SpyRuns.Length > 10 ? 10 : g_SpyRuns.Length;

    Chat_SendMessage(client, "{blue} Top Scores (Showing %i/%i)", maxLength, g_SpyRuns.Length);

    for(int i = 0; i < maxLength; i++)
    {
        PlayerTime playerTime;
        g_SpyRuns.GetArray(i, playerTime);

        char formattedTime[16];
        Timer_FormatTime(playerTime.runTime, formattedTime, sizeof(formattedTime));
        Chat_SendMessage(client, "{gold}#%i {red}%s {white}- {green}%s", i + 1, playerTime.username, formattedTime);
    }
}

public Action Command_GetWorldRecord(int client, int args)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    Chat_SendMessage(client, "Records for {blue}%s", map);
    ReportWorldRecord(client, MEDIC_SPY);
    ReportWorldRecord(client, SNIPER_ENGIE_PYRO);
    return Plugin_Handled;
}
