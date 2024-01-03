

public void MessageCycle_SendWelcome(int client)
{
    CPrintToChat(client, "Welcome to {red}climb.tf{white}! Do {red}/help{white} to get started | Join our Discord: {lightblue}https://climb.tf/discord{default}");

    char map[64];
    GetCurrentMap(map, sizeof(map));
    CPrintToChat(client, "You're playing on {red}%s{white} ({green}Tier %s{default}) created by {red}%s{default}. {red}/mapinfo{default} for more info",
        map, gMapData_MapDifficulty, gMapData_creator);

    if(PlayerTimes_HasRecord(MEDIC_SPY))
    {
        Chat_NewLine(client);

        PlayerTime playerTime;
        PlayerTimes_GetMapRecord(MEDIC_SPY, playerTime);

        char formattedTime[32];
        Timer_FormatTime(playerTime.runTime, formattedTime, sizeof(formattedTime));

        CPrintToChat(client, "The current record is {blue}%s{default} by {red}%s{default}.", formattedTime, playerTime.username);
    }

    CPrintToChat(client, "{indianred}Everything is still in an early stages of development. Feedback and feature requests are very welcome.");
}