public void Movement_OnStopTouchGround(int client, bool jumped, bool ladderJump, bool jumpbug)
{
	JumpStats_OnStopTouchGround(client, jumped, jumpbug);
//	OnStopTouchGround_MapTriggers(client);
}

public void Movement_OnStartTouchGround(int client)
{
	JumpStats_OnStartTouchGround(client);
}