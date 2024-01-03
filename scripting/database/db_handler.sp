Database db = null;

public void SQL_OnConnect(Handle hOwner, Handle hDatabase, const char[] sError, any iData) 
{ 
    if (hDatabase == INVALID_HANDLE) {
        LogError("Database failure: %s", sError);
        SetFailState("Error: %s", sError);
    } else {
        db = hDatabase;
        PrintToServer("[INFO] Connected to database succesfully!");
        OnDatabaseConnect();
    }
}

public void Database_Init()
{
    if(db == null)
    {
        SQL_TConnect(SQL_OnConnect, "climb");
    }
}

public void Database_LogConnection(int client, const char[] steam_id)
{
    char username[MAX_NAME_LENGTH], nameEscaped[MAX_NAME_LENGTH * 2 + 1];
    GetClientName(client, username, sizeof(username));

    SQL_EscapeString(db, username, nameEscaped, MAX_NAME_LENGTH * 2 + 1);

    char ip_address[32];
    GetClientIP(client, ip_address, sizeof(ip_address));

    char map[64];
    GetCurrentMap(map, sizeof(map));

    char date[32];
    FormatTime(date, sizeof(date), "%Y-%m-%d %T");

    Transaction tx = SQL_CreateTransaction();

    char query[512];
    FormatEx(query, sizeof(query),
        "INSERT INTO connection_history (steam_id, username, ip_address, map, date) VALUES ('%s', '%s', '%s', '%s', '%s')",
        steam_id, nameEscaped, ip_address, map, date
    );
    tx.AddQuery(query);

    char histQuery[512];
    FormatEx(histQuery, sizeof(histQuery),
        "INSERT INTO players (steam_id, username, ip_address, points, server_rank) VALUES ('%s', '%s', '%s', '0', '0') ON CONFLICT (steam_id) DO UPDATE SET username = '%s', ip_address = '%s'",
        steam_id, nameEscaped, ip_address,
        nameEscaped, ip_address
    );

    tx.AddQuery(histQuery);

    SQL_ExecuteTransaction(db, tx, SQL_Succ, SQL_OnError);
}

public void SQL_Succ(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{

}

public void SQL_OnError(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    PrintToServer("[ERROR] %s", error);
}

public void Database_LoadPlayer()
{

}

public void Database_OnPlayerAuthorized()
{

}