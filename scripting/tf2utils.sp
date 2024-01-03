int MEDIC_SPY = 0;
int SNIPER_ENGIE_PYRO = 1;
int SCOUT = 2;
int OTHER = 3;

public int TF_GetClassType(int client)
{
    switch (TF2_GetPlayerClass(client)) {
		case 1:	{ return SCOUT;  }
		case 2: { return SNIPER_ENGIE_PYRO; }
		case 3: { return OTHER; }
		case 4: { return OTHER; }
		case 5: { return MEDIC_SPY; }
		case 6: { return OTHER; }
		case 7: { return SNIPER_ENGIE_PYRO; }
		case 8: { return MEDIC_SPY; }
		case 9: { return SNIPER_ENGIE_PYRO; }
		default: { return OTHER; }
	}
}

public int TF_GetClassTypeFromId(int id)
{
    switch (id) {
		case 1:	{ return SCOUT;  }
		case 2: { return SNIPER_ENGIE_PYRO; }
		case 3: { return OTHER; }
		case 4: { return OTHER; }
		case 5: { return MEDIC_SPY; }
		case 6: { return OTHER; }
		case 7: { return SNIPER_ENGIE_PYRO; }
		case 8: { return MEDIC_SPY; }
		case 9: { return SNIPER_ENGIE_PYRO; }
		default: { return OTHER; }
	}
}

public void TF_GetClassTypeName(int class_id, char[] buffer, int buffLen)
{
    if(class_id == SCOUT)
    {
        strcopy(buffer, buffLen, "Scout");
    }
    else if(class_id == SNIPER_ENGIE_PYRO)
    {
        strcopy(buffer, buffLen, "Sniper/Engie/Pyro");
    }
    else if(class_id == MEDIC_SPY)
    {
        strcopy(buffer, buffLen, "Medic/Spy");
    }
    else
    {
        strcopy(buffer, buffLen, "Other");
    }
}