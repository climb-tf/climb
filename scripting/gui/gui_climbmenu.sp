//
// Handles the menu for saving a checkpoint, teleporting to a checkpoint, restarting the run
//

public Action ClimbMenu_Display(int client)
{
    Menu menu = new Menu(ClimbMenuHandler);

//    if(Timer_IsActive(client))
//    {
//        char menuTitle[32];
//        //FormatTime(menuTitle, sizeof(menuTitle), "Menu - %T", Timer_Get(client));
//        char fTime[32];2
//        Timer_GetStr(client, fTime, sizeof(fTime));
//        FormatEx(menuTitle, sizeof(menuTitle), "Menu - %s", fTime);
//
//        menu.SetTitle(menuTitle);
//    }
//    else
//    {
//    }

    menu.SetTitle("Menu");

    menu.AddItem("save", "Save Location");

    int teleportCount = Checkpoints_GetTeleports(client);

    if(teleportCount != 0) {
        char teleports[32];
        Format(teleports, sizeof(teleports), "Teleport (%i)", teleportCount);
        menu.AddItem("goto", teleports);
    } else {
        menu.AddItem("goto", "Teleport Back");
    }

    menu.AddItem("", "", ITEMDRAW_SPACER);
    menu.AddItem("undotp", "Undo Teleport");
    menu.AddItem("prevcp", "Prev CP");
    menu.AddItem("time", "Print Time");
    menu.AddItem("restart", "Restart");
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}


public int ClimbMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char info[32];
        bool found = menu.GetItem(param2, info, sizeof(info));

        if(StrEqual(info, "save")) {
            Checkpoints_SaveLocation(client);
        } else if(StrEqual(info, "goto")) {
            Command_Teleport(client, 0);
        } else if(StrEqual(info, "restart")) {
            Run_Restart(client);
        } else if(StrEqual(info, "time")) {
            if(!Timer_IsActive(client))
            {
                Chat_SendMessage(client, "Timer not active.");
                return 0;
            }

            char szTime[64];
            char buffer[12];
            Timer_GetStr(client, buffer, sizeof(buffer));
            Format(szTime, sizeof(szTime), "Time: %s", buffer);
            Chat_SendMessage(client, szTime);
        }
        else if(StrEqual(info, "prevcp"))
        {
            Checkpoints_PrevTeleport(client);
        }
        else if(StrEqual(info, "undotp"))
        {
            Command_UndoTeleport(client, 0);
        }

        ClimbMenu_Display(client);
    }
    else if (action == MenuAction_Cancel)
    {

    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}