
enum struct JumpstatData
{
    char steamId[32];
    char username[64];
    float distance;
    int strafes;
    float sync;

    void Init(char steamId[32], char username[64], float distance, int strafes, int sync) {
        this.steamId = steamId;
        this.username = username;
        this.distance = distance;
        this.strafes = strafes;
        this.sync = sync;
    }
}

JumpstatData jumpstatPbs[MAXPLAYERS + 1][3];

public void JumpstatApi_OnClientAuthorized(int client, const char[] steam_id)
{
    JumpstatData emptyJumpstatData;
    JumpstatData emptyJumpstatData2;
    jumpstatPbs[client][0] = emptyJumpstatData;
    jumpstatPbs[client][1] = emptyJumpstatData2;

    //lj
    JumpstatApi_GetJumpstats(client, steam_id, 0, 0, 0);
    //bhop
    JumpstatApi_GetJumpstats(client, steam_id, 0, 0, 1);
}

public void JumpstatApi_ReportPB(int client, int class_id) {
    float ljDistance = jumpstatPbs[client][0].distance;
    float bhopDistance = jumpstatPbs[client][1].distance;

    if(ljDistance <= 0) {
        Chat_SendMessage(client, "{default}Long Jump: not yet set");
    } else {
        Chat_SendMessage(client, "{default}Long Jump: {blue}%.2f{default} units", ljDistance);
    }

    if(bhopDistance <= 0) {
        Chat_SendMessage(client, "{default}Bhop: {red}not yet set");
    } else {
        Chat_SendMessage(client, "{default}Bhop: {blue}%.2f{default} units", bhopDistance);
    }

}

public void JumpstatApi_GetJumpstats(int client, const char[] steamId, int classIdx, int style, int type) {
}


void GetJumpstats_OnJumpstatsRetrieved(HTTPResponse response, int client) {
    if (response.Status != HTTPStatus_OK) {
        return;
    }

    PrintToServer("[INFO] Retrieved Jumpstats HTTP Response");

    JSONObject run = view_as<JSONObject>(response.Data);
    JSONObject userProfile = view_as<JSONObject>(run.Get("user"));

    float distance = run.GetFloat("distance");

    if(distance <= 0) {
        //No jump stat for user
        PrintToServer("[INFO] User has no jumpstat PB");
        return;
    }

    int strafes = run.GetFloat("strafes");
    int sync = run.GetFloat("sync");
    int type = run.GetInt("type");

    char displayName[64];
    userProfile.GetString("username", displayName, sizeof(displayName));

    char steamId[32];
    userProfile.GetString("steamId", steamId, sizeof(steamId));

    JumpstatData jumpstatData;
    jumpstatData.Init(steamId, displayName, distance, strafes, sync);

    PrintToServer("[INFO] Loaded jumpstat (%i) pb: %f", type, jumpstatData.distance);
    jumpstatPbs[client][type] = jumpstatData;
}


public void JumpstatApi_OnStat(int client, float distance, int strafes, float sync, int type)
{
    int class_id = TF_GetClassType(client);

    if(class_id != MEDIC_SPY || type > 1) {
        return;
    }

    if(distance > jumpstatPbs[client][type].distance) {
        char message[256];

        if(type == 0) {
            FormatEx(message, sizeof(message), "{blue}%N{default} beat their LongJump PB! {blue}%N{default} jumped {blue}%.1f{default} units! ({green}+%.1f{default})", client, client, distance, distance - jumpstatPbs[client][type].distance);
        } else if(type == 1) {
            FormatEx(message, sizeof(message), "{blue}%N{default} beat their Bhop PB! {blue}%N{default} jumped {blue}%.1f{default} units! ({green}+%.1f{default})", client, client, distance, distance - jumpstatPbs[client][type].distance);
        }

        Chat_Broadcast(message);


        jumpstatPbs[client][type].distance = distance;
        jumpstatPbs[client][type].strafes = strafes;
        jumpstatPbs[client][type].sync = sync;

        JumpstatApi_SaveStat(client, distance, strafes, sync, type, class_id);
    }
}

//String steamId, int classId, int type, double distance, int strafes, int sync)
public void JumpstatApi_SaveStat(int client, float distance, int strafes, int sync, int type, int class_id)
{
}

void SaveStat_Response(HTTPResponse response, any value) {
}
