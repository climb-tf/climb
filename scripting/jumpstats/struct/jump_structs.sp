#define JS_MAX_TRACKED_STRAFES 48
#define JS_FAILSTATS_MAX_TRACKED_TICKS 128

enum struct Pose
{
	float position[3];
	float orientation[3];
	float velocity[3];
	float speed;
	int duration;
	int overlap;
	int deadair;
	int syncTicks;
}

enum struct Jump
{
	int jumper;
	int block;
	int crouchRelease;
	int crouchTicks;
	int deadair;
	int duration;
	int originalType;
	int overlap;
	int releaseW;
	int strafes;
	int type;
	float deviation;
	float distance;
	float edge;
	float height;
	float maxSpeed;
	float offset;
	float sync;
	float width;

	float preSpeed;

	// For the 'always' stats
	float miss;

	// We can't make a separate enum struct for that cause it won't let us
	// index an array of enum structs.
	int strafes_gainTicks[JS_MAX_TRACKED_STRAFES];
	int strafes_deadair[JS_MAX_TRACKED_STRAFES];
	int strafes_overlap[JS_MAX_TRACKED_STRAFES];
	int strafes_ticks[JS_MAX_TRACKED_STRAFES];
	float strafes_gain[JS_MAX_TRACKED_STRAFES];
	float strafes_loss[JS_MAX_TRACKED_STRAFES];
	float strafes_sync[JS_MAX_TRACKED_STRAFES];
	float strafes_width[JS_MAX_TRACKED_STRAFES];
}