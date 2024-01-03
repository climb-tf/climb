enum struct JumpStatsSettings
{
    bool displayJumpStats;
    int jumpStatsMinChatTier;
    int jumpStatsMinConsoleTier;
    int jumpStatsMinSoundTier;
    bool extendedChatReport;

    void Init()
    {
        this.displayJumpStats = true;
        this.jumpStatsMinChatTier = 0;
        this.jumpStatsMinConsoleTier = 0;
        this.jumpStatsMinSoundTier = 0;
        this.extendedChatReport = true;
    }
}