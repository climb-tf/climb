#define JS_MAX_JUMP_DISTANCE 500
#define MAX_OFFSET = 2.0

float distanceTiers[6][6];
char distanceTierNames[6][16] = {
    "meh",
    "impressive",
    "perfect",
    "godlike",
    "ownage",
    "wrecker"
}



//  	JumpType_LongJump,
//  	JumpType_Bhop,
//  	JumpType_MultiBhop,
//  	JumpType_WeirdJump, //?
//  	JumpType_Jumpbug,
//  	JumpType_Fall, //

//        "vanilla"
//        {
//            "meh"               "210.0"
//            "impressive"        "235.0"
//            "perfect"           "240.0"
//            "godlike"           "245.0"
//            "ownage"            "248.0"
//            "wrecker"           "250.0"
//        }

enum
{
	DistanceTier_None = -1,
	DistanceTier_Meh,
	DistanceTier_Impressive,
	DistanceTier_Perfect,
	DistanceTier_Godlike,
	DistanceTier_Ownage,
	DistanceTier_Wrecker,
	DISTANCETIER_COUNT
};

char gC_DistanceTierChatColours[DISTANCETIER_COUNT][] =
{
	"{grey}",
	"{blue}",
	"{green}",
	"{darkred}",
	"{gold}",
	"{orchid}"
};

//todo: make this configurable
public void InitTiers()
{
    distanceTiers[JumpType_LongJump] = {
        301.0,
        306.0,
        310.0,
        312.0,
        315.0,
        318.0
    };

    distanceTiers[JumpType_Bhop] = {
        320.0,
        325.0,
        330.0,
        335.0,
        340.0,
        350.0
    };

    distanceTiers[JumpType_MultiBhop] = {
        350.0,
        360.0,
        370.0,
        940.0,
        945.0,
        950.0
    };

    distanceTiers[JumpType_WeirdJump] = {
        300.0,
        930.0,
        935.0,
        940.0,
        945.0,
        950.0
    };

    distanceTiers[JumpType_Jumpbug] = {
        300.0,
        308.0,
        935.0,
        940.0,
        945.0,
        950.0
    };

    distanceTiers[JumpType_Fall] = {
        300.0,
        930.0,
        935.0,
        940.0,
        945.0,
        950.0
    };
}

int GetDistanceTier(int jumpType, float distance, float offset = 0.0)
{
	// No tiers given for 'Invalid' jumps.
	if (jumpType == JumpType_Invalid
	|| jumpType == JumpType_FullInvalid
	 || jumpType == JumpType_Fall
	 || jumpType == JumpType_Other
	  && offset < -2.1
	  || distance > JS_MAX_JUMP_DISTANCE)
	{
		// TODO Give a tier to "Other" jumps
		// TODO Give a tier to offset jumps
		return DistanceTier_None;
	}

    int lastTier = DistanceTier_None;
	// Get highest tier distance that the jump beats
	for(int i = 0; i < 6; i++)
	{
	    if(distance > distanceTiers[jumpType][i])
	    {
	        lastTier = i;
	    }
	}

	return lastTier;
}