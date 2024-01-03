#include "gui/gui_climbmenu.sp"

int g_menuTracker[MAXPLAYERS + 1];
const int MENU_CLIMBMENU = 0;

Handle refreshTimers[MAXPLAYERS+1];

public void StartMenuRefresher(int client)
{
   // refreshTimers[client] = CreateTimer(0.1, Timer_MenuRefresher, client, TIMER_REPEAT);
}

public void StopMenuRefresher(int client)
{
    delete refreshTimers[client];
}

public void OpenMenu(int client, int menuId)
{
    g_menuTracker[client] = menuId;
    UpdateMenu(client);
}

public void UpdateMenu(int client)
{
    int currentMenu = g_menuTracker[client];

    switch(currentMenu)
    {
        case MENU_CLIMBMENU:
        {
            ClimbMenu_Display(client);
            return;
        }
        default:
        {
            return;
        }
    }
}

public Action Timer_MenuRefresher(Handle timer, int client)
{
    UpdateMenu(client);
}

public void CloseMenu(int client)
{
    if(client < 0) return;
    g_menuTracker[client] = 0;
}