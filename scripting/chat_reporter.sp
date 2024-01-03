public Reporter_CompleteMap(ClimbPlayer player, int runTime, int personalBest)
{
	char map[64];
	GetCurrentMap(map, sizeof(map));

	char steamId[32];
	GetClientAuthId(player.client, AuthId_Steam2, steamId, sizeof(steamId));

	char timeStr[20];
	FormatTime(timeStr, sizeof(timeStr), "%T", runTime);

	char differenceMsg[32]; 
	//Best PB
	if(personalBest == -1)
	{
		differenceMsg = "(No previous time)";
	}
	else if(runTime < personalBest)
	{
		FormatTime(differenceMsg, sizeof(differenceMsg), "({green}-%T{default})", personalBest - runTime);
	}
	else
	{
		FormatTime(differenceMsg, sizeof(differenceMsg), "({red}+%T{default})", runTime - personalBest);
	}

	char szTime[128];
	FormatEx(szTime, sizeof(szTime), "{blue}%N{default} has completed {blue}%s{default} in: %s{default} %s", player.client, map, timeStr, differenceMsg);

	Chat_Broadcast(szTime);
}