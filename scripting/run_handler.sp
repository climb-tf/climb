
public void Run_Restart(int client)
{
	Checkpoints_Reset(client);

	if(MapSpawn_Exists())
	{
		MapSpawn_Teleport(client);
	}
	else
	{
		Chat_SendMessage(client, "This map hasn't been configured properly. GET AN ADMIN!!!!!1111!11");
	}

	//If the timer_start zone doesn't exist on the map, start the timer. Is this a bad idea? If you accidently press restart RIP your run.
	if(!Zone_CheckIfZoneExists("timer_start", true, false))
	{
		Run_StartTimer(client);
	}
}

public void Run_StartTimer(int client)
{
	Timer_Start(client);
	Checkpoints_Reset(client);
	Chat_SendMessage(client, "Timer has {green}started{default}.");
}

public void Zone_OnClientEntry(int client, const char [] zone)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) ||!IsPlayerAlive(client))
		return;

	if(StrEqual(zone, "timer_start", false))
	{
		Run_StartTimer(client);
	}
	else if(StrEqual(zone, "timer_end", false))
	{
		MapCompletedEvent(client);
	}
}