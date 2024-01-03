#define MAX_CLASSES 4

float g_fSaveLocation[MAXPLAYERS + 1][3];
float g_fSaveAngles[MAXPLAYERS + 1][3];

float g_fUndoTpLocation[MAXPLAYERS + 1][3];
float g_fUndoTpAngles[MAXPLAYERS + 1][3];

float g_fPrevCpLoc[MAXPLAYERS +1][10][3];
float g_fPrevCpAng[MAXPLAYERS +1][10][3];
int g_fCpIdx[MAXPLAYERS +1];

int g_iTeleportCount[MAXPLAYERS + 1];

public void Checkpoints_RegisterCommands()
{
    RegConsoleCmd("sm_saveloc", Command_SaveLoc, "Saves your current location.");
    RegConsoleCmd("sm_s", Command_SaveLoc, "Saves your current location.");
    RegConsoleCmd("sm_checkpoint", Command_SaveLoc, "Saves your current location.");
    RegConsoleCmd("sm_cp", Command_SaveLoc, "Saves your current location.");

    RegConsoleCmd("sm_gocheck", Command_Teleport, "Goes to your checkpoint.");
    RegConsoleCmd("sm_tp", Command_Teleport, "Goes to your checkpoint.");
    RegConsoleCmd("sm_teleport", Command_Teleport, "Goes to your checkpoint.");

    RegConsoleCmd("sm_undotp", Command_UndoTeleport, "Undo your last teleport.");

    RegConsoleCmd("sm_restart", Command_Restart, "Restarts your run");
    RegConsoleCmd("sm_r", Command_Restart, "Restarts your run");
}

public Action Command_UndoTeleport(int client, int args)
{
    if (!IsPlayerAlive(client))
    {
        Chat_SendMessage(client, "You must be alive to teleport.");
        return Plugin_Handled;
    }

    Checkpoints_TeleportLoc(client, g_fUndoTpLocation[client], g_fUndoTpAngles[client]);
    return Plugin_Handled;
}

public Action Command_SaveLoc(int client, int args)
{
    Checkpoints_SaveLocation(client);
    return Plugin_Handled;
}

public Action Command_Restart(int client, int iArgs) {
    if (!IsPlayerAlive(client))
    {
        Chat_SendMessage(client, "You must be alive to use this command.");
        return Plugin_Handled;
    }

    Run_Restart(client);

    return Plugin_Handled;
}

public Action Command_Teleport(int client, int iArgs)
{
    if (!IsPlayerAlive(client))
    {
        Chat_SendMessage(client, "You must be alive to teleport.");
        return Plugin_Handled;
    }

    g_iTeleportCount[client]++;

    Checkpoints_Teleport(client);

    return Plugin_Handled;
}

public void Checkpoints_SaveLocation(int client)
{
    if (!IsPlayerAlive(client)) {
        Chat_SendMessage(client, "You must be alive to set a checkpoint.");
        return;
    }

    if (!(GetEntityFlags(client) & FL_ONGROUND)) {
        Chat_SendMessage(client, "You must be on the ground to save a checkpoint.");
        return;
    }

    if (GetEntityFlags(client) & FL_DUCKING) {
        Chat_SendMessage(client, "You cannot save a checkpoint while crouched.");
        return;
    }

    //Moves all checkpoints up an element
    for(int i = 0; i < 9; i++)
    {
        int idx = 9 - i;

        g_fPrevCpLoc[client][idx] = g_fPrevCpLoc[client][idx - 1];
        g_fPrevCpAng[client][idx] = g_fPrevCpAng[client][idx - 1];
    }

    g_fPrevCpLoc[client][0] = g_fSaveLocation[client];
    g_fPrevCpAng[client][0] = g_fSaveAngles[client];

    GetClientAbsOrigin(client, g_fSaveLocation[client]);
    GetClientEyeAngles(client, g_fSaveAngles[client]);

    g_fCpIdx[client] = 0;
}

public void Checkpoints_Teleport(int client)
{
    float fVelocity[3] = {0.0, 0.0, 0.0};
    Checkpoints_TeleportLoc(client, g_fSaveLocation[client], g_fSaveAngles[client]);
    g_fCpIdx[client] = 0;
}

public void Checkpoints_PrevTeleport(int client)
{
    int idx = g_fCpIdx[client]++;

    if(idx == 10 || g_fPrevCpLoc[client][idx][0] == 0.0)
    {
        Chat_SendMessage(client, "End of checkpoint history.");
        g_fCpIdx[client] = 0;
        return;
    }

    Checkpoints_TeleportLoc(client, g_fPrevCpLoc[client][idx], g_fPrevCpAng[client][idx]);
}

public bool Checkpoints_HasCheckpoint(int client)
{
    return g_fSaveLocation[client][0] != 0;
}

// Handles teleporting the player safely
static void Checkpoints_TeleportLoc(int client, float origin[3], float angles[3]) {
    float fVelocity[3] = {0.0, 0.0, 0.0};

    if (!IsPlayerAlive(client)) {
        Chat_SendMessage(client, "You must be alive to teleport.");
    } else if (origin[0] == 0) {
        Chat_SendMessage(client, "You don't have a save for your current class speed.");
    } else {
        float cachedLocation[3];
        float cachedAngles[3];
        GetClientAbsOrigin(client, cachedLocation);
        GetClientAbsAngles(client, cachedAngles);

        TeleportEntity(client, origin, angles, fVelocity);

        g_fUndoTpLocation[client] = cachedLocation;
        g_fUndoTpAngles[client] = cachedAngles;

        //Chat_SendMessage(client, "You have been teleported.");
    }
}

public int Checkpoints_GetTeleports(int client)
{
    return g_iTeleportCount[client];
}

public void Checkpoints_Reset(int client)
{
    g_fSaveLocation[client] = {0.0, 0.0, 0.0};
    g_fSaveAngles[client] = {0.0, 0.0, 0.0};

    for(int i = 0; i < 10; i++)
    {
        g_fPrevCpLoc[client][i] = {0.0, 0.0, 0.0};
        g_fPrevCpAng[client][i] = {0.0, 0.0, 0.0};
    }

    g_fCpIdx[client] = 0;
    g_iTeleportCount[client] = 0;

    g_fUndoTpLocation[client] = {0.0, 0.0, 0.0};
    g_fUndoTpAngles[client] = {0.0, 0.0, 0.0};
}
