static float g_fStartTimes[MAXPLAYERS + 1];
/**
 * Starts the timer
 */
public void Timer_Start(int client)
{
    if(GetEntityMoveType(client) == MOVETYPE_NOCLIP) {
        return;
    }

    g_fStartTimes[client] = GetEngineTime();
}

/**
 * Stops the timer
 */
public void Timer_Reset(int client)
{
    g_fStartTimes[client] = 0;
}

/**
 * Gets the time elapsed since starting
 */
public float Timer_Get(int client)
{
    float time = g_fStartTimes[client];
    float time_elapsed = GetEngineTime() - time;
    return time_elapsed;
}

public void Timer_GetStr(int client, char[] buffer, int bufferLen)
{
    Timer_FormatTime(Timer_Get(client), buffer, bufferLen);
}

public void Timer_FormatTime(float time, char[] buffer, int bufferLen)
{
    float timeSince = time;
    int roundedTime = RoundToFloor(timeSince);

    int ms = RoundToFloor((timeSince - roundedTime) * 1000);

    char formattedTime[32];
    FormatTime(formattedTime, sizeof(formattedTime), "%T", roundedTime);

    if(StrContains(formattedTime, "00:", false) == 0)
    {
        char cutTime[32];
        strcopy(cutTime, 32, formattedTime[3]);
        FormatEx(buffer, bufferLen, "%s.%02i", cutTime, ms);
        return;
    }

    FormatEx(buffer, bufferLen, "%s.%02i", formattedTime, ms);
}

/**
 * Gets the time elapsed since start and stops the timer.
 */
public float Timer_Complete(int client)
{
    float time = Timer_Get(client);
    Timer_Reset(client);
    return time;
}

public bool Timer_IsActive(int client)
{
    return g_fStartTimes[client] != 0;
}