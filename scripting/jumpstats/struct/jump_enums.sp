#define JUMPTYPE_COUNT 8

enum
{
	JumpType_FullInvalid = -1,
	JumpType_LongJump,
	JumpType_Bhop,
	JumpType_MultiBhop,
	JumpType_WeirdJump, //?
	JumpType_Jumpbug,
	JumpType_Fall, //
	JumpType_Other,
	JumpType_Invalid,
};

enum
{
	StrafeDirection_None,
	StrafeDirection_Left,
	StrafeDirection_Right
};

public char gC_JumpTypes[JUMPTYPE_COUNT][] =
{
	"Long Jump",
	"Bunnyhop",
	"Multi Bunnyhop",
	"Weird Jump",
	"Jumpbug",
	"Fall",
	"Unknown Jump",
	"Invalid Jump"
};

public char gC_JumpTypesShort[JUMPTYPE_COUNT][] =
{
	"LJ",
	"BH",
	"MBH",
	"WJ",
	"JB",
	"FL",
	"UNK",
	"INV"
};

public char gC_JumpTypeKeys[JUMPTYPE_COUNT][] =
{
	"longjump",
	"bhop",
	"multibhop",
	"weirdjump",
	"jumpbug",
	"fall",
	"unknown",
	"invalid"
};