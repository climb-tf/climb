#include "events/events_movement.sp"

public void Events_Init()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("teamplay_round_start", Event_round_start);

    RegisterTeleportEvent();

    AddCommandListener(CommandListener_Build, "build");
    //AddCommandListener(CommandListener_JoinClass, "joinclass");
}

//https://asherkin.github.io/vtable/
static void RegisterTeleportEvent()
{
	hTeleport = DHookCreate(114, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
	DHookAddParam(hTeleport, HookParamType_VectorPtr);
	DHookAddParam(hTeleport, HookParamType_ObjectPtr);
	DHookAddParam(hTeleport, HookParamType_VectorPtr);
}

public void HookClientEvents(int client)
{
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_TouchPost, SDKHook_Touch_CallBack);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
}

public Action CommandListener_Build(int client, const char[] command, int argc)
{
    return Plugin_Handled;
}