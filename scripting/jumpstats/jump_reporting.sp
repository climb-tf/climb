#define JS_MAX_TRACKED_STRAFES 48

static char sounds[6][256];


void JumpReporting_OnMapStart()
{
	if (!LoadSounds())
	{
	    PrintToServer("[error] Error loading sounds");
	}
}

static bool LoadSounds()
{
	char downloadPath[256];
	for (int tier = DistanceTier_Impressive; tier < 6; tier++)
	{
	    FormatEx(sounds[tier], 256, "climbtf/%s.mp3", distanceTierNames[tier]);
		FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", sounds[tier]);
		AddFileToDownloadsTable(downloadPath);
		PrecacheSound(sounds[tier], true);
	}

	return true;
}

public void JumpReport_OnFailStat(Jump jump)
{
    Chat_SendMessage(jump.jumper, "JumpReport_OnFailStat: ");
}

public void JumpReport_OnFailstatAlways(Jump jump)
{
    Chat_SendMessage(jump.jumper, "JumpReport_OnFailstatAlways: ");
}

public void JumpReport_OnLanding(Jump jump)
{
    bool invalid = jump.type == JumpType_Invalid || jump.type == JumpType_FullInvalid || jump.type == JumpType_Other || jump.offset < -2.0;

    int tier = invalid ? DistanceTier_None : GetDistanceTier(jump.type, jump.distance, jump.offset);

    //Chat_SendMessage(jump.jumper, "{blue}[JumpReport_OnLanding] %s | {default} Dist: {blue}%f{default} | Offset: {blue}%f{default} | Edge: {blue}%f{default} | Tier: %i, other type: %s",
    //gC_JumpTypes[jump.originalType], jump.distance, jump.offset, jump.edge, tier, gC_JumpTypes[jump.type]);

    if (tier == DistanceTier_None)
    {
        return;
    }

    // Report the jumpstat to the client and their spectators
    DoJumpstatsReport(jump.jumper, jump, tier);

    ReportToSpectators(jump, tier);
}

public void PlayJumpstatSound(int client, int tier)
{
	int soundOption = settings[client].jumpStats.jumpStatsMinSoundTier;
	if (tier <= DistanceTier_Meh || soundOption == DistanceTier_None || soundOption > tier)
	{
		return;
	}

	EmitSoundToClient(client, sounds[tier]);
}

void ReportToSpectators(Jump jump, int tier)
{

}


//Unused
public void JumpReport_OnTakeOff(int client, int jumpType)
{

}

static void DoJumpstatsReport(int client, Jump jump, int tier)
{
	if(TF_GetClassType(client) == SCOUT || !settings[client].jumpStats.displayJumpStats)
	{
	    return;
	}

	DoChatReport(client, false, jump, tier);
	DoConsoleReport(client, false, jump, tier, "Console Jump Header");
	PlayJumpstatSound(client, tier);
}

static void DoChatReport(int client, bool isFailstat, Jump jump, int tier)
{
	int minChatTier = settings[client].jumpStats.jumpStatsMinChatTier;

	if (minChatTier > tier)
	{
	    Chat_SendMessage(client, "Tier: %i, %s", tier, distanceTierNames[tier]);
		return;
	}

	char typePostfix[3], color[16], blockStats[32], extBlockStats[32];
	char releaseStats[32], edgeOffset[64], offsetEdge[32], missString[32];

	if (isFailstat)
	{
		//if (GOKZ_JS_GetOption(client, JSOption_FailstatsChat) == JSToggleOption_Disabled
		//	&& GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled)
		//{
		//	return;
		//}
		//strcopy(typePostfix, sizeof(typePostfix), "-F");
		//strcopy(color, sizeof(color), "{grey}");
	}
	else
	{
		strcopy(color, sizeof(color), gC_DistanceTierChatColours[tier]);
	}

	if (jump.block > 0)
	{
		FormatEx(blockStats, sizeof(blockStats), " | %s", GetFloatChatString(client, "Edge", jump.edge));
		FormatEx(extBlockStats, sizeof(extBlockStats), " | %s", GetFloatChatString(client, "Deviation", jump.deviation));
	}

	if (jump.miss > 0.0)
	{
		FormatEx(missString, sizeof(missString), " | %s", GetFloatChatString(client, "Miss", jump.miss));
	}

	if (jump.edge > 0.0 || (jump.block > 0 && jump.edge == 0.0))
	{
		FormatEx(edgeOffset, sizeof(edgeOffset), " | %s", GetFloatChatString(client, "Edge", jump.edge));
	}

	if (jump.originalType == JumpType_LongJump ||
		jump.originalType == JumpType_WeirdJump)
	{
		if (jump.releaseW >= 20 || jump.releaseW <= -20)
		{
			FormatEx(releaseStats, sizeof(releaseStats), " | {red}✗ {grey}W", GetReleaseChatString(client, "W Release", jump.releaseW));
		}
		else
		{
			FormatEx(releaseStats, sizeof(releaseStats), " | %s", GetReleaseChatString(client, "W Release", jump.releaseW));
		}
	}
	else if (jump.crouchRelease < 20 && jump.crouchRelease > -20)
	{
		FormatEx(releaseStats, sizeof(releaseStats), " | %s", GetReleaseChatString(client, "Crouch Release", jump.crouchRelease));
	}

	FormatEx(offsetEdge, sizeof(offsetEdge), " | %s", GetFloatChatString(client, "Offset", jump.offset));

	Chat_SendMessageSpec(client, true,
		"%s%s%s{grey}: %s%.1f{grey} | %s | %s%s%s",
		color,
		gC_JumpTypesShort[jump.originalType],
		typePostfix,
		color,
		jump.distance,
		GetStrafesSyncChatString(client, jump.strafes, jump.sync),
		GetSpeedChatString(client, jump.preSpeed, jump.maxSpeed),
		edgeOffset,
		releaseStats);

	if (settings[client].jumpStats.extendedChatReport)
	{
		Chat_SendMessage(client,
			"%s | %s%s%s | %s | %s%s",
			GetIntChatString(client, "Overlap", jump.overlap),
			GetIntChatString(client, "Dead Air", jump.deadair),
			offsetEdge,
			extBlockStats,
			GetWidthChatString(client, jump.width, jump.strafes),
			GetFloatChatString(client, "Height", jump.height),
			missString);
	}

	JumpstatApi_OnStat(client, jump.distance, jump.strafes, jump.sync, jump.originalType);
}

static char[] GetFloatChatString(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString),
		"{lime}%.1f{grey} %T",
		value, stat, client);
	return resultString;
}

static char[] GetIntChatString(int client, const char[] stat, int value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString),
		"{lime}%d{grey} %T",
		value, stat, client);
	return resultString;
}

static char[] GetReleaseChatString(int client, char[] releaseType, int release)
{
	char resultString[32];
	if (release == 0)
	{
		FormatEx(resultString, sizeof(resultString),
			"{green}✓{grey} %T",
			releaseType, client);
	}
	else if (release > 0)
	{
		FormatEx(resultString, sizeof(resultString),
			"{red}+%d{grey} %T",
			release,
			releaseType, client);
	}
	else
	{
		FormatEx(resultString, sizeof(resultString),
			"{blue}%d{grey} %T",
			release,
			releaseType, client);
	}
	return resultString;
}

static char[] GetStrafesSyncChatString(int client, int strafes, float sync)
{
	char resultString[64];
	FormatEx(resultString, sizeof(resultString),
		"{lime}%d{grey} %T ({lime}%.0f%%%%{grey})",
		strafes, "Strafes", client, sync);
	return resultString;
}

static char[] GetSpeedChatString(int client, float preSpeed, float maxSpeed)
{
	char resultString[64];
	FormatEx(resultString, sizeof(resultString),
		"{lime}%.0f{grey} / {lime}%.0f{grey} %T",
		preSpeed, maxSpeed, "Speed", client);
	return resultString;
}

static char[] GetWidthChatString(int client, float width, int strafes)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString),
		"{lime}%.1f°{grey} %T",
		GetAverageStrafeWidth(strafes, width), "Width", client);
	return resultString;
}

static float GetAverageStrafeWidth(int strafes, float totalWidth)
{
	if (strafes == 0)
	{
		return 0.0;
	}

	return totalWidth / strafes;
}


static void DoConsoleReport(int client, bool isFailstat, Jump jump, int tier, char[] header)
{
	int minConsoleTier = settings[client].jumpStats.jumpStatsMinConsoleTier;

	//if ((minConsoleTier == 0 || minConsoleTier > tier) && GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Disabled
	//	|| isFailstat && GOKZ_JS_GetOption(client, JSOption_FailstatsConsole) == JSToggleOption_Disabled)
	//{
	//	return;
	//}

	char releaseWString[32], blockString[32], edgeString[32], deviationString[32], missString[32];

	if (jump.originalType == JumpType_LongJump ||
		jump.originalType == JumpType_WeirdJump)
	{
		FormatEx(releaseWString, sizeof(releaseWString), " %s", GetIntConsoleString(client, "W Release", jump.releaseW));
	}
	else if (jump.crouchRelease < 20 && jump.crouchRelease > -20)
	{
		FormatEx(releaseWString, sizeof(releaseWString), " %s", GetIntConsoleString(client, "Crouch Release", jump.crouchRelease));
	}

	if (jump.miss > 0.0)
	{
		FormatEx(missString, sizeof(missString), " %s", GetFloatConsoleString2(client, "Miss", jump.miss));
	}

	if (jump.block > 0)
	{
		FormatEx(blockString, sizeof(blockString), " %s", GetIntConsoleString(client, "Block", jump.block));
		FormatEx(deviationString, sizeof(deviationString), " %s", GetFloatConsoleString1(client, "Deviation", jump.deviation));
	}

	if (jump.edge > 0.0 || (jump.block > 0 && jump.edge == 0.0))
	{
		FormatEx(edgeString, sizeof(edgeString), " %s", GetFloatConsoleString2(client, "Edge", jump.edge));
	}

	PrintToConsole(client, "%t", header, jump.jumper, jump.distance, gC_JumpTypes[jump.originalType]);

	PrintToConsole(client, "%s%s%s %s %s %s %s%s %s %s%s %s %s %s %s %s",
		blockString,
		edgeString,
		missString,
		GetIntConsoleString(client, jump.strafes == 1 ? "Strafe" : "Strafes", jump.strafes),
		GetSyncConsoleString(client, jump.sync),
		GetFloatConsoleString2(client, "Pre", jump.preSpeed),
		GetFloatConsoleString2(client, "Max", jump.maxSpeed),
		releaseWString,
		GetIntConsoleString(client, "Overlap", jump.overlap),
		GetIntConsoleString(client, "Dead Air", jump.deadair),
		deviationString,
		GetWidthConsoleString(client, jump.width, jump.strafes),
		GetFloatConsoleString1(client, "Height", jump.height),
		GetIntConsoleString(client, "Airtime", jump.duration),
		GetFloatConsoleString1(client, "Offset", jump.offset),
		GetIntConsoleString(client, "Crouch Ticks", jump.crouchTicks));

	PrintToConsole(client, "  #.  %12t%12t%12t%12t%12t%9t%t", "Sync (Table)", "Gain (Table)", "Loss (Table)", "Airtime (Table)", "Width (Table)", "Overlap (Table)", "Dead Air (Table)");
	if (jump.strafes_ticks[0] > 0)
	{
		PrintToConsole(client, "  0.  ----      -----     -----     %3.0f%%      -----     --     --", GetStrafeAirtime(jump, 0));
	}
	for (int strafe = 1; strafe <= jump.strafes && strafe < JS_MAX_TRACKED_STRAFES; strafe++)
	{
		PrintToConsole(client,
			" %2d.  %3.0f%%      %5.2f     %5.2f     %3.0f%%      %5.1f°    %2d     %2d",
			strafe,
			GetStrafeSync(jump, strafe),
			jump.strafes_gain[strafe],
			jump.strafes_loss[strafe],
			GetStrafeAirtime(jump, strafe),
			FloatAbs(jump.strafes_width[strafe]),
			jump.strafes_overlap[strafe],
			jump.strafes_deadair[strafe]);
	}
	PrintToConsole(client, ""); // New line
}

static char[] GetSyncConsoleString(int client, float sync)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.0f%% %T", sync, "Sync", client);
	return resultString;
}

static char[] GetWidthConsoleString(int client, float width, int strafes)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.1f° %T", GetAverageStrafeWidth(strafes, width), "Width", client);
	return resultString;
}

// I couldn't really merge those together
static char[] GetFloatConsoleString1(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.1f %T", value, stat, client);
	return resultString;
}

static char[] GetFloatConsoleString2(int client, const char[] stat, float value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %.2f %T", value, stat, client);
	return resultString;
}

static char[] GetIntConsoleString(int client, const char[] stat, int value)
{
	char resultString[32];
	FormatEx(resultString, sizeof(resultString), "| %d %T", value, stat, client);
	return resultString;
}