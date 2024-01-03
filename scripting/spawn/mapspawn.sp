float g_fMapSpawnLocation[3];
float g_fMapSpawnAngles[3];

char gMapData_mapName[64];
char gMapData_creator[64];
int gMapData_MapDifficultySpyTP;
int gMapData_MapDifficultySpyPro;
int gMapData_MapDifficultySniperTP;
int gMapData_MapDifficultySniperPro;
int gMapData_IntendedClass;


char gMapData_creatorExtra[128];
char gMapData_MapDifficulty[3];

//char gMapDifficulties[][] = {
//        "{lightgreen}Very Easy{default}", //T0
//        "{lightgreen}Easy{default}", //T1
//        "{lightgreen}Easy+{default}", //T2
//        "{lightblue}Medium{default}",  //T3
//        "{lightblue}Medium+{default}", //T4
//        "{darkred}Hard{default}", //T5
//        "{darkred}Very Hard{default}", //T6
//        "{purple}Insane{default}", //T7
//        "{purple}Insane+{default}" //T8
//};

void MapSpawn_RegisterCommands()
{
	RegAdminCmd("sm_mapdata_spawn", Command_Set_MapStart, 1, "Set the map's starting point.");

	RegAdminCmd("sm_mapdata_creator", Command_SetCreator, 1, "Set the map's creator");
	RegAdminCmd("sm_mapdata_creator_extra", Command_SetCreatorExtra, 1, "Set extra data about the map's creator");
	RegAdminCmd("sm_mapdata_difficulty", Command_SetMapDifficulty, 1, "Set the map's difficulty");

	RegConsoleCmd("sm_mapinfo", Command_MapInfo, "Show info about the map");
	RegConsoleCmd("sm_mi", Command_MapInfo, "Show info about the map");
}

void MapSpawn_OnMapLoad() {
    char map[64];
    GetCurrentMap(map, sizeof(map));

    MapSpawn_GetApiMapInfo(map);
}

void MapSpawn_GetApiMapInfo(char[] mapName) {
    char buffer[253];
    Format(buffer, sizeof(buffer), "https://climb.tf/v1/maps/%s", mapName);

    HTTPRequest request = new HTTPRequest(buffer);
    request.Get(GetApiMapInfo_OnRetrieved);
}

void GetApiMapInfo_OnRetrieved(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK) {
        PrintToServer("[INFO] MapInfo response was not OK");
        PrintToServer("[INFO] Response: %i", response.Status);
        return;
    }

    PrintToServer("[INFO] Retrieved Map Info");
    JSONObject responseData = view_as<JSONObject>(response.Data);

    responseData.GetString("mapName", gMapData_mapName, sizeof(gMapData_mapName));
    responseData.GetString("mapCreator", gMapData_creator, sizeof(gMapData_creator));

    gMapData_IntendedClass = responseData.GetInt("intendedClass");
    gMapData_MapDifficultySpyTP = responseData.GetInt("tierSpyTP");
    gMapData_MapDifficultySniperTP = responseData.GetInt("tierSniperTP");

    gMapData_MapDifficultySpyPro = responseData.GetInt("tierSniperPro");
    gMapData_MapDifficultySniperPro = responseData.GetInt("tierSniperPro");
}

public Action Command_MapInfo(int client, int iArgs) {
    char map[64];
    GetCurrentMap(map, sizeof(map));

    Chat_SendMessage(client, "{white}---- {green}%s {white}----", map);
    Chat_SendMessage(client, "{green}Creator: {white}%s", gMapData_creator);
    Chat_SendMessage(client, "{green}Difficulty (Spy/Medic): {white}T%i (T%i PRO)", gMapData_MapDifficultySpyTP, gMapData_MapDifficultySpyPro);
    Chat_SendMessage(client, "{green}Difficulty (Pyro/Engie/Sniper): {white}T%i (T%i PRO)", gMapData_MapDifficultySniperTP, gMapData_MapDifficultySniperPro);

    return Plugin_Handled;
}

public Action Command_Set_MapStart(int client, int args)
{
	GetClientAbsOrigin(client, g_fMapSpawnLocation);
	GetClientAbsAngles(client, g_fMapSpawnAngles);
	Client_PrintToChat(client, true, "{red}[Client]{default} Updated map start point.");

	SaveSpawnpoint(client);

	return Plugin_Handled;
}

public Action Command_SetCreator(int client, int args)
{
    GetCmdArg(1, gMapData_creator, 64);
    Client_PrintToChat(client, true, "{red}[Client]{default} Set map creator to: {green}%s", gMapData_creator);
    SaveMapInfo(client);
	return Plugin_Handled;
}

public Action Command_SetCreatorExtra(int client, int args)
{
    GetCmdArg(1, gMapData_creatorExtra, 64);
    Client_PrintToChat(client, true, "{red}[Client]{default} Set extra data to: {green}%s", gMapData_creatorExtra);
    SaveMapInfo(client);
	return Plugin_Handled;
}

public Action Command_SetMapDifficulty(int client, int args)
{
    GetCmdArg(1, gMapData_MapDifficulty, 3);
    Client_PrintToChat(client, true, "{red}[Client]{default} Set difficulty to: Tier %s", gMapData_MapDifficulty);
    SaveMapInfo(client);
	return Plugin_Handled;
}

public void MapData_LoadSpawn()
{
    char BasePath[512];
    BuildPath(Path_SM, BasePath, sizeof(BasePath), "configs/climb");
    if (!DirExists(BasePath))
        CreateDirectory(BasePath, 511);

    char Path[512];
    BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/spawns");
    if (!DirExists(Path))
        CreateDirectory(Path, 511);

    char wsPath[512];
    BuildPath(Path_SM, wsPath, sizeof(wsPath), "configs/climb/spawns/workshop");
    if (!DirExists(wsPath))
        CreateDirectory(wsPath, 511);

    char map[64];
    GetCurrentMap(map, sizeof(map));
    BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/spawns/%s.spawn.txt", map);

    if (!FileExists(Path))
    {
        Handle kv = CreateKeyValues("Spawnpoint");
        KeyValuesToFile(kv, Path);
        PrintToServer("[INFO] Spawnpoint file doesn't exist so one will be created at: %s", Path);
    }


    Handle kv = CreateKeyValues("Spawnpoint");
    FileToKeyValues(kv, Path);

    KvGetVector(kv, "spawn_location", g_fMapSpawnLocation);
    KvGetVector(kv, "spawn_angles", g_fMapSpawnAngles);

    CloseHandle(kv);
}

public void MapData_LoadMapInfo()
{
    char BasePath[512];
    BuildPath(Path_SM, BasePath, sizeof(BasePath), "configs/climb");
    if (!DirExists(BasePath))
        CreateDirectory(BasePath, 511);

    char Path[512];
    BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/mapdata");
    if (!DirExists(Path))
        CreateDirectory(Path, 511);

    char wsPath[512];
    BuildPath(Path_SM, wsPath, sizeof(wsPath), "configs/climb/mapdata/workshop");
    if (!DirExists(wsPath))
        CreateDirectory(wsPath, 511);

    char map[64];
    GetCurrentMap(map, sizeof(map));
    BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/mapdata/%s.mapinfo.txt", map);

    if (!FileExists(Path))
    {
        Handle kv = CreateKeyValues("MapInfo");
        KeyValuesToFile(kv, Path);
        PrintToServer("[INFO] Mapinfo file doesn't exist so one will be created at: %s", Path);
    }


    Handle kv = CreateKeyValues("MapInfo");
    FileToKeyValues(kv, Path);

    KvGetString(kv, "creator", gMapData_creator, 64, "Undefined");
    KvGetString(kv, "creator_extra", gMapData_creatorExtra, 128, "");
    KvGetString(kv, "difficulty", gMapData_MapDifficulty, 3, "-1");

    CloseHandle(kv);
}

public void MapSpawn_Load()
{
    MapData_LoadSpawn();
	//MapData_LoadMapInfo();
}


static void SaveSpawnpoint(int client) {
	Client_PrintToChat(client, false, "Saving spawn point to file...");
	char Path[512];
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/spawns/%s.spawn.txt", map);
	Handle file = OpenFile(Path, "w+");
	CloseHandle(file);

	Handle kv = CreateKeyValues("Spawnpoint");

	KvSetVector(kv, "spawn_location", g_fMapSpawnLocation);
	KvSetVector(kv, "spawn_angles", g_fMapSpawnAngles);

	KeyValuesToFile(kv, Path);
	CloseHandle(kv);

	if (client != 0)
		PrintToChat(client, "Spawnpoint has been saved.");
}

static void SaveMapInfo(int client) {
	Client_PrintToChat(client, false, "Saving mapinfo to file...");
	char Path[512];
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/climb/mapdata/%s.mapinfo.txt", map);
	Handle file = OpenFile(Path, "w+");
	CloseHandle(file);

	Handle kv = CreateKeyValues("MapInfo");

    KvSetString(kv, "creator", gMapData_creator);
    KvSetString(kv, "creator_extra", gMapData_creatorExtra);
    KvSetString(kv, "difficulty", gMapData_MapDifficulty);

	KeyValuesToFile(kv, Path);
	CloseHandle(kv);

	if (client != 0)
		PrintToChat(client, "MapInfo has been saved.");
}

public void MapSpawn_Teleport(int client)
{
    float fVelocity[3] = {0.0, 0.0, 0.0};
    TeleportEntity(client, g_fMapSpawnLocation, g_fMapSpawnAngles, fVelocity);
}

public bool MapSpawn_Exists()
{
    return g_fMapSpawnLocation[0] != 0.0 || g_fMapSpawnLocation[1] != 0.0;
}