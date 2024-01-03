//sv_accelerate 6.5
//sv_airaccelerate 100.0
//sv_friction 5.0
//sv_gravity 800.0
//sv_enablebunnyhopping 1
//sv_maxspeed 320.0
//sv_maxvelocity 2000.0
//sv_staminalandcost 0.00
//sv_staminajumpcost 0.00
//sv_wateraccelerate 10.0

float KZT_AirAccel = 1000.0;

public void Styles_RegisterCommands()
{
    RegConsoleCmd("sm_styles", Command_Styles, "Change your movement style");
}

public Action Command_Styles(int client, int iArgs)
{

}

