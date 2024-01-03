bool g_bDebugEnabled[MAXPLAYERS + 1];

public void Chat_SendMessage(int client, const char[] format, any ...)
{
    char prefixed[253];
    char buffer[253];


    VFormat(buffer, sizeof(buffer), format, 3);
    Format(prefixed, sizeof(prefixed), "{red}climb.tf {grey}|{default} %s", buffer);

    CPrintToChat(client, prefixed);
}

public void Chat_SendMessageSpec(int client, bool spectators, const char[] format, any ...)
{
    char prefixed[253];
    char buffer[253];


    VFormat(buffer, sizeof(buffer), format, 4);
    Format(prefixed, sizeof(prefixed), "{red}climb.tf {grey}|{default} %s", buffer);

    CPrintToChat(client, prefixed);

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientConnected(i) || !IsClientInGame(i) || IsClientSourceTV(i) && IsClientReplay(i))
        {
            continue;
        }

        if(GetClientTeam(i) != TFTeam_Spectator)
        {
            continue;
        }

        int mode = GetEntProp(i, Prop_Send, "m_iObserverMode");
        if (mode != 4 && mode != 5) {
            continue;
        }

        int target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
        if (target != client) {
            continue;
        }

        CPrintToChat(i, prefixed);
    }
}

public void Chat_NewLine(int client)
{
    CPrintToChat(client, "");
}

public void Chat_Broadcast(const char[] format, any ...)
{
    char prefixed[253];
    char buffer[253];

    VFormat(buffer, sizeof(buffer), format, 2);
    FormatEx(prefixed, sizeof(prefixed), "{red}climb.tf {grey}|{default} %s", buffer);

    CPrintToChatAll(prefixed);
}

public void Chat_Debug(int client, const char[] format, any ...)
{
    if(!g_bDebugEnabled[client])
    {
        return;
    }

    char prefixed[253];
    char buffer[253];

    VFormat(buffer, sizeof(buffer), format, 3);
    Format(prefixed, sizeof(prefixed), "{grey}[{red}climb.tf{grey}/{red}Debug{grey}]{default} %s", buffer);

    CPrintToChat(client, prefixed);
}