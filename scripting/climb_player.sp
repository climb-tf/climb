methodmap ClimbPlayer
{
    public ClimbPlayer(int client)
    {
        return view_as<ClimbPlayer>(client);
    }

    property int client
    {
        public get() 
        {
            return view_as<int>(this);
        }
    }

    public void SaveCheckpoint()
    {
        Checkpoints_SaveLocation(this.client);
    }

    public void GotoCheckpoint()
    {
        Checkpoints_Teleport(this.client);
    }

    public void GotoPrevCheckpoint()
    {
        Checkpoints_PrevTeleport(this.client);    
    }

    public void ResetCheckpoints()
    {
        Checkpoints_Reset(this.client);
    }

    public void StartTimer()
    {
        Timer_Start(this.client);
    }

    public void ResetTimer()
    {
         Timer_Reset(this.client);
    }

    public bool IsTimerActive()
    {
        return Timer_IsActive(this.client);
    }
}