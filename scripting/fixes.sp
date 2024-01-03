int g_iCollisionGroup;

bool g_bGodMode = true;

bool fixEntityPositions = false;

public void Fixes_Init()
{
    g_iCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public void Fixes_OnMapChange()
{
    fixEntityPositions = true;
}

public void Fixes_OnPlayerSpawn(int client)
{
    Fixes_RemoveCollisions(client);
    Fixes_ApplyGodmode(client);
}

public void Fixes_RemoveCollisions(int client)
{
    SetEntData(client, g_iCollisionGroup, 2, 4, true);
}

public void Fixes_ApplyGodmode(int client)
{
    if(!g_bGodMode) return;

    SetEntProp(client, Prop_Data, "m_takedamage", 0);
    SetEntityFlags(client, GetEntityFlags(client) | FL_GODMODE);
}

public void Fixes_FixTeleportVelocity(int client, Handle params)
{
    static float emptyVec[3];

    if(IsValidClient(client) && params != null && !DHookIsNullParam(params, 1))
    {
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, emptyVec);
    }
}