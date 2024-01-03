#include "jumpstats/jump_settings.sp"

enum struct PlayerSettings {
    JumpStatsSettings jumpStats;

    void Init()
    {
        this.jumpStats.Init();
    }
}

public PlayerSettings settings[MAXPLAYERS + 1];

public void Settings_InitClient(int client)
{
    settings[client].Init();
}