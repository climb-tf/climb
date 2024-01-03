Handle hTeleport;

bool g_bWelcomeSent[MAXPLAYERS + 1];

public Action Event_PlayerSpawn(Handle event, const char [] name, bool dontBroadcast)
{
    int client_id = GetEventInt(event, "userid");
    int client = GetClientOfUserId(client_id);

    //MapSpawn_Teleport(client);
    Checkpoints_Reset(client);

    //Removes collisions, gives godmode
    Fixes_OnPlayerSpawn(client);

    //Previously: OnClientPutInServer
    HookClientEvents(client);
    JumpTracking_OnClientPutInServer(client);

    if(MapSpawn_Exists())
    {
        MapSpawn_Teleport(client);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Event_PlayerChangeClass(Handle event, const char [] name, bool dontBroadcast)
{
    int userId = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userId);
    int classId = GetEventInt(event, "class");

    if (TF_GetClassTypeFromId(classId) == MEDIC_SPY)
    {
        //LocationRestore_LoadFromDatabase(client);
    }

    OpenMenu(client, 0);

    if(!g_bWelcomeSent[client])
    {
        g_bWelcomeSent[client] = true;
        MessageCycle_SendWelcome(client);
    }

    return Plugin_Continue;
}

public void MapCompletedEvent(int client)
{
    PlayerTimes_CompleteMap(client);
}

public void OnClientPutInServer(int client)
{
    DHookEntity(hTeleport, true, client);

    StartMenuRefresher(client);
    Settings_InitClient(client);

    //Needs to be here???
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	JumpTracking_OnPlayerRunCmd(client, buttons, tickcount);
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    JumpStats_OnPlayerRunCmdPost(client);

    if(Movement_GetNoclipping(client) && Timer_IsActive(client))
    {
        Timer_Reset(client);
    }
}

public void OnClientDisconnect(int client)
{
    LocationRestore_SaveToDatabase(client);
    StopMenuRefresher(client);
    g_bWelcomeSent[client] = false;
}

//Be careful putting DB interacting code here, this gets called before the database loads officially
public void OnMapStart()
{
    PrintToServer("[climb/debug] OnMapStart");
    MapSpawn_Load();
    JumpReporting_OnMapStart();
    JumpStats_Init();

    //DB Code, but makes sure DB is loaded first.
    PlayerTimes_OnMapLoad();
    MapSpawn_OnMapLoad();

    HudDisplay_OnMapStart();

    for(int i = 0; i < sizeof(g_bWelcomeSent); i++) {
        g_bWelcomeSent[i] = false;
    }
}

public MRESReturn DHooks_OnTeleport(int client, Handle params)
{   
    Fixes_FixTeleportVelocity(client, params);
    JumpTracking_OnTeleport(client);
    return MRES_Ignored;
}

public void OnClientAuthorized(int client, const char[] steam_id)
{
    //Database_LogConnection(client, steam_id);
    Website_LogConnection(client, steam_id);
    PlayerTimes_OnClientAuthorized(client, steam_id);
    JumpstatApi_OnClientAuthorized(client, steam_id);

    //Scores_LoadPlayer(client, map, steam_id);
    Checkpoints_Reset(client);
    Timer_Reset(client);
}

public void OnDatabaseConnect()
{

}

public void SDKHook_StartTouch_Callback(int client, int touched) // SDKHook_StartTouchPost
{
	JumpTracking_OnStartTouch(client);
}

public void SDKHook_Touch_CallBack(int client, int touched)
{
	JumpTracking_OnTouch(client);
}

public void SDKHook_EndTouch_Callback(int client, int touched) // SDKHook_EndTouchPost
{
	JumpTracking_OnEndTouch(client);
}

public Action Event_round_start(Handle event, const char[] name, bool dontBroadcast) {
    char map[64];
    GetCurrentMap(map, sizeof(map));
    if (StrContains(map, "pl_", false) != -1 || StrContains(map, "cp_", false) != -1)
    {
        //Only do this on vanilla maps.
        OpenDoors();
        DoAllEnts();
    }

    return Plugin_Continue;
}

// ----- Everything below is copied from https://github.com/sapphonie/SOAP-TF2DM/blob/master/addons/sourcemod/scripting/soap_tf2dm.sp
/* OpenDoors() - rewritten by nanochip and stephanie
 *
 * Initially forces all doors open and keeps them unlocked even when they close.
 * -------------------------------------------------------------------------- */
void OpenDoors()
{
    int ent = -1;
    // search for all func doors
    while ((ent = FindEntityByClassname(ent, "func_door")) > 0)
    {
        if (IsValidEntity(ent))
        {
            AcceptEntityInput(ent, "unlock", -1);
            AcceptEntityInput(ent, "open", -1);
            FixNearbyDoorRelatedThings(ent);
        }
    }
    // reset ent
    ent = -1;
    // search for all other possible doors
    while ((ent = FindEntityByClassname(ent, "prop_dynamic")) > 0)
    {
        if (IsValidEntity(ent))
        {
            char iName[64];
            char modelName[64];
            GetEntPropString(ent, Prop_Data, "m_iName", iName, sizeof(iName));
            GetEntPropString(ent, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
            if
            (
                    StrContains(iName, "door", false)       != -1
                 || StrContains(iName, "gate", false)       != -1
                 || StrContains(iName, "exit", false)       != -1
                 || StrContains(iName, "grate", false)      != -1
                 || StrContains(modelName, "door", false)   != -1
                 || StrContains(modelName, "gate", false)   != -1
                 || StrContains(modelName, "exit", false)   != -1
                 || StrContains(modelName, "grate", false)  != -1
            )
            {
                AcceptEntityInput(ent, "unlock", -1);
                AcceptEntityInput(ent, "open", -1);
                FixNearbyDoorRelatedThings(ent);
            }
        }
    }
    // reset ent
    ent = -1;
    // search for all other possible doors
    while ((ent = FindEntityByClassname(ent, "func_brush")) > 0)
    {
        if (IsValidEntity(ent))
        {
            char brushName[64];
            GetEntPropString(ent, Prop_Data, "m_iName", brushName, sizeof(brushName));
            if
            (
                    StrContains(brushName, "door", false)   != -1
                 || StrContains(brushName, "gate", false)   != -1
                 || StrContains(brushName, "exit", false)   != -1
                 || StrContains(brushName, "grate", false)  != -1
            )
            {
                RemoveEntity(ent);
                FixNearbyDoorRelatedThings(ent);
            }
        }
    }
}

// remove any func_brushes that could be blockbullets and open area portals near those func_brushes
void FixNearbyDoorRelatedThings(int ent)
{
    float doorLocation[3];
    float brushLocation[3];

    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", doorLocation);

    int iterEnt = -1;
    while ((iterEnt = FindEntityByClassname(iterEnt, "func_brush")) > 0)
    {
        if (IsValidEntity(iterEnt))
        {
            GetEntPropVector(iterEnt, Prop_Send, "m_vecOrigin", brushLocation);
            if (GetVectorDistance(doorLocation, brushLocation) < 50.0)
            {
                char brushName[32];
                GetEntPropString(iterEnt, Prop_Data, "m_iName", brushName, sizeof(brushName));
                if
                (
                        StrContains(brushName, "bullet", false) != -1
                     || StrContains(brushName, "door", false)   != -1
                )
                {
                    RemoveEntity(iterEnt);
                }
            }
        }
    }

    // iterate thru all area portals on the map and open them
    // don't worry - the client immediately closes ones that aren't neccecary to be open. probably.
    iterEnt = -1;
    while ((iterEnt = FindEntityByClassname(iterEnt, "func_areaportal")) > 0)
    {
        if (IsValidEntity(iterEnt))
        {
            AcceptEntityInput(iterEnt, "Open");
        }
    }
}

// Entities to remove - don't worry! these all get reloaded on round start!
char g_entIter[][] =
{
    "team_round_timer",                 // DISABLE*     - Don't delete this ent, it will crash servers otherwise. Don't disable on passtime maps either, for the same reason.
    "team_control_point_master",        // DISABLE      - this ent causes weird behavior in DM servers if deleted. just disable
    "team_control_point",               // DISABLE      - No need to remove this, disabling works fine
    "tf_logic_koth",                    // DISABLE      - ^
    "logic_auto",                       // DISABLE      - ^
    "logic_relay",                      // DISABLE      - ^
    "item_teamflag",                    // DISABLE      - ^
    "trigger_capture_area",             // TELEPORT     - we tele these ents under the map by 5000 units to disable them - otherwise, huds bug out occasionally
    "tf_logic_arena",                   // DELETE*      - need to delete these, otherwise fight / spectate bullshit shows up on arena maps
                                        //                set mp_tournament to 1 to prevent this, since nuking the ents permanently breaks arena mode, for some dumb tf2 reason
                                        //                if this is not acceptable for your use case, please open a github issue and i will address it, thank you!
    "func_regenerate",                  // DELETE       - deleting this ent is the only way to reliably prevent it from working in DM otherwise
    "func_respawnroom",                 // DELETE       - ^
    "func_respawnroomvisualizer",       // DELETE       - ^
    "item_healthkit_full",              // DELETE       - ^
    "item_healthkit_medium",            // DELETE       - ^
    "item_healthkit_small",             // DELETE       - ^
    "item_ammopack_full",               // DELETE       - ^
    "item_ammopack_medium",             // DELETE       - ^
    "item_ammopack_small"               // DELETE       - ^
};

void DoAllEnts()
{
    // iterate thru list of entities to act on
    for (int i = 0; i < sizeof(g_entIter); i++)
    {
        // init variable
        int ent = -1;
        // does this entity exist?
        while ((ent = FindEntityByClassname(ent, g_entIter[i])) > 0)
        {
            if (IsValidEntity(ent) && ent > 0)
            {
                DoEnt(i, ent);
            }
        }
    }
}

// act on the ents: requires iterator #  and entityid
void DoEnt(int i, int entity)
{
    if (IsValidEntity(entity))
    {
        // remove arena logic (disabling doesn't properly disable the fight / spectate bullshit)
        if (StrContains(g_entIter[i], "tf_logic_arena", false) != -1)
        {
            RemoveEntity(entity);
        }
        // move trigger zones out of player reach because otherwise the point gets capped in dm servers and it's annoying
        // we don't remove / disable because both cause issues/bugs otherwise
        else if (StrContains(g_entIter[i], "trigger_capture", false) != -1)
        {
            float hell[3] = {0.0, 0.0, -5000.0};
            TeleportEntity(entity, hell, NULL_VECTOR, NULL_VECTOR);
        }
        else if (StrContains(g_entIter[i], "team_round_timer", false) != -1)
        {
            char map[64];
            GetCurrentMap(map, sizeof(map));
            if (StrContains(map, "pass_", false) != -1)
            {
            }
            else
            {
                AcceptEntityInput(entity, "Disable");
            }
        }
        else
        {
            AcceptEntityInput(entity, "Disable");
        }
    }
}