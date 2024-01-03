bool g_bDisplayTimer[MAXPLAYERS + 1];

Handle g_hHudUpdateRate;
Handle g_hTimerStyle;

static Handle HudSync;

public void HudDisplay_RegisterCommands()
{
    HudSync = CreateHudSynchronizer();
    g_hHudUpdateRate = CreateConVar("climb_hud_updaterate", "0.1", "Rate to update the display timer.", 0, true, 0.01);
    g_hTimerStyle = CreateConVar("climb_hud_timerstyle", "0", "Global timer style to use.", 0, true, 0);

	RegConsoleCmd("sm_timer", Command_Timer, "Displays an on-screen timer");
}

public Action Command_Timer(int client, int iArgs)
{
    g_bDisplayTimer[client] = !g_bDisplayTimer[client];
	return Plugin_Handled;
}

public void HudDisplay_OnMapStart()
{
    PrecacheSound("UI/hint.wav");
    CreateTimer(GetConVarFloat(g_hHudUpdateRate), HudDisplay_Timer, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action HudDisplay_Timer(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client)) {
            int style = GetConVarInt(g_hTimerStyle);
            if(style == 0) {
                HudDisplay_UpdateHud(client);
            } else if(style == 1) {
                HudDisplay_UpdateHudPopup(client);
            }
        }
    }

    return Plugin_Continue;
}

public void HudDisplay_UpdateHudPopup(int client) {
    if(g_bDisplayTimer[client]) {
        if(Timer_IsActive(client)) {
            char buffer[13];
            Timer_GetStr(client, buffer, sizeof(buffer));
//ico_notify_flag_moving
            PrintHintText(client, "Time: %s", buffer);
            PrintCenterText(client, "Time: %s", buffer);
            StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
        } else {
            PrintHintText(client, "[ Timer not active ]");
            PrintCenterText(client, "[ Timer not active ]");
            StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
        }
    }
}

public void HudDisplay_UpdateHud(int client)
{
    if(g_bDisplayTimer[client]) {
        if(Timer_IsActive(client)) {
            char buffer[13];
            Timer_GetStr(client, buffer, sizeof(buffer));

        	SetHudTextParams(0.15, -1.7, 0.6, 255, 255, 255, 255);
            ShowSyncHudText(client, HudSync, buffer);
            //PrintHintText(client, "Time: %s", buffer);
        } else {
            //PrintHintText(client, "[ Timer not active ]");
        }
        //StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
    }
}

//void SendHudNotificationCustom(int client, const char[] szText, const char[] szIcon, TFTeam nTeam = TFTeam_Unassigned)
//{
//	BfWrite bf = UserMessageToBfWrite(StartMessageOne("HudNotifyCustom", client));
//	bf.WriteString(szText);
//	bf.WriteString(szIcon);
//	bf.WriteByte(view_as<int>(nTeam));
//	EndMessage();
//}
//
//void SendHudNotification(HudNotification_t iType, bool bForceShow = false)
//{
//	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
//	bf.WriteByte(view_as<int>(iType));
//	bf.WriteBool(bForceShow);	// Display in cl_hud_minmode
//	EndMessage();
//}