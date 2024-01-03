public bool gB_SpeedJustModifiedExternally[MAXPLAYERS + 1];

#include "jumpstats/struct/jump_enums.sp"
#include "jumpstats/struct/jump_structs.sp"
#include "jumpstats/jump_tiers.sp"
#include "jumpstats/jump_reporting.sp"
#include "jumpstats/jump_utils.sp"
#include "jumpstats/jump_tracking.sp"

// This must be global because it's both used by jump tracking and validating.

public void JumpStats_Init()
{
    InitTiers();
}

public void JumpStats_OnStopTouchGround(int client, bool jumped, bool jumpbug)
{
    Chat_Debug(client, "JumpStats_OnStopTouchGround");
    if(Movement_GetMovetype(client) == MOVETYPE_WALK)
    {
        JumpTracking_OnValidJump(client, jumped, jumpbug);
    }
    else
    {
    	Chat_Debug(client, "JumpStats_OnStopTouchGround: Invalidating...");
        InvalidateJumpstat(client);
    }
}

public void JumpStats_OnStartTouchGround(int client)
{
    Chat_Debug(client, "JumpStats_OnStartTouchGround");
    JumpTracking_OnStartTouchGround(client);
}

public void JumpStats_OnPlayerRunCmd(int client, int buttons, int tickcount)
{
    JumpTracking_OnPlayerRunCmd(client, buttons, tickcount);
}

public void JumpStats_OnPlayerRunCmdPost(int client)
{
    JumpTracking_OnPlayerRunCmdPost(client);
}


