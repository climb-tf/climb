#define JS_MAX_BHOP_GROUND_TICKS 5
#define EPSILON 0.000001
#define JS_MIN_TELEPORT_DELAY 5
#define PLAYER_WIDTH 49.0
#define HALF_PLAYER_WIDTH 24.5
#define JS_MIN_BLOCK_DISTANCE 230
#define JS_FAILSTATS_MAX_TRACKED_TICKS 128
#define JS_SPEED_MODIFICATION_TOLERANCE 0.1
#define JS_OFFSET_EPSILON 0.03125
#define JS_MAX_TRACKED_STRAFES 48
#define JS_MAX_WEIRDJUMP_FALL_OFFSET 64.0

#define JS_MIN_LAJ_BLOCK_DISTANCE 50
#define JS_MAX_LAJ_FAILSTAT_DISTANCE 250

#define JS_TOUCH_GRACE_TICKS 3

#define SERVER_TICK_RATE (200.0 / 3.0)

// We cannot return enum structs and it's annoying
// The modulo operator is broken, so we can't access this using negative numbers
// (https://github.com/alliedmodders/sourcepawn/issues/456). We use the method
// described here instead: https://stackoverflow.com/a/42131603/7421666
#define pose(%1) (poseHistory[this.jumper][((this.poseIndex + (%1)) % JS_FAILSTATS_MAX_TRACKED_TICKS + JS_FAILSTATS_MAX_TRACKED_TICKS) % JS_FAILSTATS_MAX_TRACKED_TICKS])


static const Jump emptyJump;
static bool validCmd[MAXPLAYERS + 1]; // Whether no illegal action is detected

static float lastJumpButtonTime[MAXPLAYERS + 1];
static int lastNoclipTime[MAXPLAYERS + 1];
static int lastDuckbugTime[MAXPLAYERS + 1];

static const float playerMins[3] =  { -HALF_PLAYER_WIDTH, -HALF_PLAYER_WIDTH, 0.0 };
static const float playerMaxs[3] =  { HALF_PLAYER_WIDTH, HALF_PLAYER_WIDTH, 0.0 };

static bool doFailstatAlways[MAXPLAYERS + 1];
static bool isInAir[MAXPLAYERS + 1];

static int entityTouchCount[MAXPLAYERS + 1];
static int entityTouchDuration[MAXPLAYERS + 1];

Pose poseHistory[MAXPLAYERS + 1][JS_FAILSTATS_MAX_TRACKED_TICKS];

enum struct JumpTracker
{
	Jump jump;
	int jumper;
	int jumpoffTick;
	int poseIndex;
	int strafeDirection;
	int lastJumpTick;
	int lastTeleportTick;
	int lastType;
	int lastWPressedTick;
	int nextCrouchRelease;
	int syncTicks;
	int lastCrouchPressedTick;
	int tickCount;
	bool failstatBlockDetected;
	bool failstatFailed;
	bool failstatValid;
	float failstatBlockHeight;
	float takeoffOrigin[3];
	float takeoffVelocity[3];
	float position[3];

	void Init(int jumper)
	{
		this.jumper = jumper;
		this.jump.jumper = jumper;
		this.nextCrouchRelease = 100;
		this.tickCount = GetGameTickCount();
	}

	bool HitBhop()
    {
        return Movement_GetTakeoffCmdNum(this.jumper) - Movement_GetLandingCmdNum(this.jumper) <= JS_MAX_BHOP_GROUND_TICKS;
    }

    int DetermineType(bool jumped, bool jumpbug)
    {
        if (gB_SpeedJustModifiedExternally[this.jumper] || this.tickCount - this.lastTeleportTick < JS_MIN_TELEPORT_DELAY)
        {
            return JumpType_Invalid;
        }
        else if (!jumped)
        {
            return JumpType_Fall;
        }
        else if (jumpbug)
        {
            // Check for no offset
            // The origin and offset is now correct, no workaround needed
            if (FloatAbs(this.jump.offset) < JS_OFFSET_EPSILON && this.lastType == JumpType_LongJump)
            {
                return JumpType_Jumpbug;
            }
            else
            {
                return JumpType_Invalid;
            }
        }
        else if(this.HitBhop())
        {
            if (FloatAbs(this.jump.offset) < JS_OFFSET_EPSILON)
            {
                switch(this.lastType)
                {
                    case JumpType_LongJump: return JumpType_Bhop;
                    case JumpType_Bhop: return JumpType_MultiBhop;
                    case JumpType_MultiBhop: return JumpType_MultiBhop;
                    default: return JumpType_Other;
                }
            }
            // Check for weird jump
            else if (this.lastType == JumpType_Fall && this.ValidWeirdJumpDropDistance())
            {
                return JumpType_WeirdJump;
            }
            else
            {
                return JumpType_Other;
            }
        }

        return JumpType_LongJump;
    }

	bool ValidWeirdJumpDropDistance()
	{
		if (this.jump.offset < -1 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
		{
			// Don't bother telling them if they fell a very far distance
//			if (!GetJumpstatsDisabled(this.jumper) && this.jump.offset >= -2 * JS_MAX_WEIRDJUMP_FALL_OFFSET)
//			{
//				GOKZ_PrintToChat(this.jumper, true, "%t", "Dropped Too Far (Weird Jump)", -1 * this.jump.offset, JS_MAX_WEIRDJUMP_FALL_OFFSET);
//			}
			return false;
		}
		return true;
	}

	void Reset(bool jumped, bool jumpbug)
	{
		// We need to do that before we reset the jump cause we need the
		// offset and type of the previous jump
		this.lastType = this.DetermineType(jumped, jumpbug);

		// We need this for weirdjump w-release
		int releaseWTemp = this.jump.releaseW;

		// Reset all stats
		this.jump = emptyJump;
		this.jump.type = this.lastType;
		this.jump.jumper = this.jumper;
		this.syncTicks = 0;
		this.strafeDirection = StrafeDirection_None;
		this.jump.releaseW = 100;

		// We have to show this on the jumpbug stat, not the lj stat
		this.jump.crouchRelease = this.nextCrouchRelease;
		this.nextCrouchRelease = 100;

		// Handle weirdjump w-release
		if (this.jump.type == JumpType_WeirdJump)
		{
			this.jump.releaseW = releaseWTemp;
		}

		// Reset pose history
		this.poseIndex = 0;
		// Update the first tick if it is a jumpbug.
		this.UpdateOnGround();
	}

    void Begin()
    {
        // Initialize stats
        this.CalcTakeoff();

        //this.failstatBlockDetected = this.jump.type != JumpType_LadderJump;
        //this.failstatFailed = false;
        //this.failstatValid = false;
        //this.failstatBlockHeight = this.takeoffOrigin[2];

        // Store the original type for the always stats
        this.jump.originalType = this.jump.type;

        JumpReport_OnTakeOff(this.jumper, this.jump.type);
    }

    void End()
    {
        // The jump is so invalid we don't even have to bother.
        // Also check if the player just teleported.
        if (this.jump.type == JumpType_FullInvalid ||
            this.tickCount - this.lastTeleportTick < JS_MIN_TELEPORT_DELAY)
        {
            return;
        }

        // Measure last tick of jumpstat
        this.Update();

        // Fix the edgebug for the current position
        Movement_GetNobugLandingOrigin(this.jumper, this.position);

        // There are a couple bugs and exploits we have to check for
        //todo: this.EndBugfixExploits();

        // Calculate the last stats
        this.jump.distance = this.CalcDistance();
        this.jump.sync = float(this.syncTicks) / float(this.jump.duration) * 100.0;
        this.jump.offset = this.position[2] - this.takeoffOrigin[2];

        this.EndBlockDistance();

        // Calculate always-on stats
        //if (GOKZ_JS_GetOption(this.jumper, JSOption_JumpstatsAlways) == JSToggleOption_Enabled)
        //{
        //    this.EndAlwaysJumpstats();
        //}

		// Call the appropriate functions for either regular or always stats
        this.Callback();
    }

    void EndAlwaysJumpstats()
    {
        // Only calculate that form of edge if the regular block calculations failed
        if (this.jump.block == 0)
        {
            this.CalcAlwaysEdge();
        }

        // It's possible that the offset calculation failed with the nobug origin
        // functions, so we have to fix it when that happens. The offset shouldn't
        // be affected by the bug anyway.
        if (this.jump.offset != this.jump.offset)
        {
            Movement_GetOrigin(this.jumper, this.position);
            this.jump.offset = this.position[2] - this.takeoffOrigin[2];
        }
    }

    void CalcAlwaysEdge()
    {
        int coordDist, distSign;
        float traceStart[3], traceEnd[3], velocity[3];

        // We calculate the orientation of the takeoff block based on what
        // direction the player was moving
        CopyVector(this.takeoffVelocity, velocity);
        this.jump.edge = -1.0;

        // Calculate the takeoff orientation
        coordDist = FloatAbs(velocity[0]) < FloatAbs(velocity[1]);
        distSign = velocity[coordDist] > 0 ? 1 : -1;

        // Make sure we hit the jumpoff block
        CopyVector(this.takeoffOrigin, traceEnd);
        traceEnd[coordDist] -= 16.0 * distSign;
        traceEnd[2] -= 1.0;

        // Assume a max edge of 20
        CopyVector(traceEnd, traceStart);
        traceStart[coordDist] += 20.0 * distSign;

        // Trace the takeoff block
        if (TraceRayPosition(traceStart, traceEnd, traceEnd))
        {
            // Check whether the trace was stuck in the block from the beginning
            if (FloatAbs(traceEnd[coordDist] - traceStart[coordDist]) > EPSILON)
            {
                // Block trace ends 0.03125 in front of the actual block. Adjust the edge correctly.
                this.jump.edge = FloatAbs(traceEnd[coordDist] - this.takeoffOrigin[coordDist] + (16.0 - 0.03125) * distSign);
            }
        }
    }

	void Callback()
	{
		//if (GOKZ_JS_GetOption(this.jumper, JSOption_JumpstatsAlways) == JSToggleOption_Enabled)
		//{
		//	Call_OnJumpstatAlways(this.jump);
		//}
		//else
		//{

	    Chat_Debug(this.jump.jumper, "JumpReport_OnLanding: Distance: %f", this.jump.distance);
			JumpReport_OnLanding(this.jump);
		//}
	}

    void EndBlockDistance()
    {
        if ((this.jump.type == JumpType_LongJump ||
                this.jump.type == JumpType_Bhop ||
                this.jump.type == JumpType_MultiBhop ||
                this.jump.type == JumpType_WeirdJump ||
                this.jump.type == JumpType_Jumpbug)
             && this.jump.distance >= JS_MIN_BLOCK_DISTANCE)
        {
            this.CalcBlockStats(this.position);
        }
    }

    void Update()
    {
        this.UpdatePoseHistory();

        float speed = pose(0).speed;

        // Fix certain props that don't give you base velocity
        /*
            We check for speed reduction for abuse; while prop abuses increase speed,
            wall collision will very likely (if not always) result in a speed reduction.
        */
        float actualSpeed = GetVectorHorizontalDistance(this.position, pose(-1).position) * SERVER_TICK_RATE;

        if (FloatAbs(speed - actualSpeed) > JS_SPEED_MODIFICATION_TOLERANCE && this.jump.duration != 0)
        {
            if (actualSpeed <= pose(-1).speed)
            {
                pose(0).speed = actualSpeed;
            }
            // This check is needed if you land via ducking instead of moving (duckbug)
            else if (FloatAbs(actualSpeed) > EPSILON)
            {
                this.Invalidate();
            }
        }

        this.jump.height = FloatMax(this.jump.height, this.position[2] - this.takeoffOrigin[2]);
        this.jump.maxSpeed = FloatMax(this.jump.maxSpeed, speed);
        this.jump.crouchTicks += Movement_GetDucking(this.jumper) ? 1 : 0;
        this.syncTicks += speed > pose(-1).speed ? 1 : 0;
        this.jump.duration++;

        this.UpdateStrafes();
        this.UpdateFailstat();
        this.UpdatePoseStats();

        this.lastType = this.jump.type;
    }

    void CalcBlockStats(float landingOrigin[3], bool checkOffset = false)
    {
        int coordDist, coordDev, distSign;
        float middle[3], startBlock[3], endBlock[3], sweepBoxMin[3], sweepBoxMax[3];

        // Get the orientation of the block.
        GetCoordOrientation(landingOrigin, this.takeoffOrigin, coordDist, distSign);
        coordDev = !coordDist;

        // We can't make measurements from within an entity, so we assume the
        // player had a remotely reasonable edge and that the middle of the jump
        // is not over a block and then start measuring things out from there.
        middle[coordDist] = (this.takeoffOrigin[coordDist] + landingOrigin[coordDist]) / 2;
        middle[coordDev] = (this.takeoffOrigin[coordDev] + landingOrigin[coordDev]) / 2;
        middle[2] = this.takeoffOrigin[2] - 1.0;

        // Get the deviation.
        this.jump.deviation = FloatAbs(landingOrigin[coordDev] - this.takeoffOrigin[coordDev]);

        // Setup a sweeping line that starts in the middle and tries to search for the smallest
        // block within the deviation of the player.
        sweepBoxMin[coordDist] = 0.0;
        sweepBoxMin[coordDev] = -this.jump.deviation - HALF_PLAYER_WIDTH;
        sweepBoxMin[2] = 0.0;
        sweepBoxMax[coordDist] = 0.0;
        sweepBoxMax[coordDev] = this.jump.deviation + HALF_PLAYER_WIDTH;
        sweepBoxMax[2] = 0.0;

        // Modify the takeoff and landing origins to line up with the middle and respect
        // the bounding box of the player.
        startBlock[coordDist] = this.takeoffOrigin[coordDist] - distSign * HALF_PLAYER_WIDTH;
        // Sometimes you can land 0.03125 units in front of a block, so the trace needs to be extended.
        endBlock[coordDist] = landingOrigin[coordDist] + distSign * (HALF_PLAYER_WIDTH + 0.03125);
        startBlock[coordDev] = middle[coordDev];
        endBlock[coordDev] = middle[coordDev];
        startBlock[2] = middle[2];
        endBlock[2] = middle[2];

        // Search for the blocks
        if (!TraceHullPosition(middle, startBlock, sweepBoxMin, sweepBoxMax, startBlock)
            || !TraceHullPosition(middle, endBlock, sweepBoxMin, sweepBoxMax, endBlock))
        {
            return;
        }

        // Make sure the edges of the blocks are parallel.
        if (!BlockAreEdgesParallel(startBlock, endBlock, this.jump.deviation + PLAYER_WIDTH, coordDist, coordDev))
        {
            return;
        }

        // Needed for failstats, but you need the endBlock position for that, so we do it here.
        if (checkOffset)
        {
            endBlock[2] += 1.0;
            if (FloatAbs(FindBlockHeight(endBlock, float(distSign) * (HALF_PLAYER_WIDTH + 1), coordDist, 1.0) - landingOrigin[2]) > JS_OFFSET_EPSILON)
            {
                return;
            }
        }

        // Calculate distance and edge.
        this.jump.block = RoundFloat(FloatAbs(endBlock[coordDist] - startBlock[coordDist]));
        // Block trace ends 0.03125 in front of the actual block. Adjust the edge correctly.
        this.jump.edge = FloatAbs(startBlock[coordDist] - this.takeoffOrigin[coordDist] + (HALF_PLAYER_WIDTH - 0.03125) * distSign);

        // Make it easier to check for blocks that too short
        if (this.jump.block < JS_MIN_BLOCK_DISTANCE)
        {
            this.jump.block = 0;
            this.jump.edge = -1.0;
        }
    }

	void UpdateFailstat()
	{
		int coordDist, distSign;
		float failstatPosition[3], block[3], traceStart[3];

		// There's no point in going further if we're already done
		if (this.failstatValid || this.failstatFailed)
		{
			return;
		}

		// Get the coordinate system orientation.
		GetCoordOrientation(this.position, this.takeoffOrigin, coordDist, distSign);

		// For ladderjumps we have to find the landing block early so we know at which point the jump failed.
		// For this, we search for the block 10 units above the takeoff origin, assuming the player already
		// traveled a significant enough distance in the direction of the block at this time.
		if (!this.failstatBlockDetected &&
			this.position[2] - this.takeoffOrigin[2] < 10.0 &&
			this.jump.height > 10.0)
		{
			this.failstatBlockDetected = true;

			// Setup a trace to search for the block
			CopyVector(this.takeoffOrigin, traceStart);
			traceStart[2] -= 5.0;
			CopyVector(traceStart, block);
			traceStart[coordDist] += JS_MIN_LAJ_BLOCK_DISTANCE * distSign;
			block[coordDist] += JS_MAX_LAJ_FAILSTAT_DISTANCE * distSign;

			// Search for the block
			if (!TraceHullPosition(traceStart, block, playerMins, playerMaxs, block))
			{
				// Mark the calculation as failed
				this.failstatFailed = true;
				return;
			}

			// Find the block height
			block[2] += 5.0;
			this.failstatBlockHeight = FindBlockHeight(block, float(distSign) * (HALF_PLAYER_WIDTH + 1), coordDist, 10.0) - 0.031250;
		}

		// Only do the calculation once we're below the block level
		if (this.position[2] >= this.failstatBlockHeight)
		{
			// We need that cause we can duck after getting lower than the failstat
			// height and still make the block.
			this.failstatValid = false;
			return;
		}

		// Calculate the true origin where the player would have hit the ground.
		this.GetFailOrigin(this.failstatBlockHeight, failstatPosition, -1);

		// Calculate the jump distance.
		this.jump.distance = FloatAbs(GetVectorHorizontalDistance(failstatPosition, this.takeoffOrigin));

		// Construct the maximum landing origin, assuming the player reached
		// at least the middle of the gap.
		CopyVector(this.takeoffOrigin, block);
		block[coordDist] = 2 * failstatPosition[coordDist] - this.takeoffOrigin[coordDist];
		block[!coordDist] = failstatPosition[!coordDist];
		block[2] = this.failstatBlockHeight;

		// Calculate block stats
		if ((this.lastType == JumpType_LongJump ||
				this.lastType == JumpType_Bhop ||
				this.lastType == JumpType_MultiBhop ||
				this.lastType == JumpType_WeirdJump ||
				this.lastType == JumpType_Jumpbug)
			 && this.jump.distance >= JS_MIN_BLOCK_DISTANCE)
		{
			// Add the player model to the distance.
			this.jump.distance += PLAYER_WIDTH;

			this.CalcBlockStats(block, true);
		}
		else
		{
			this.failstatFailed = true;
			return;
		}

		if (this.jump.block > 0)
		{
			// Calculate the last stats
			this.jump.sync = float(this.syncTicks) / float(this.jump.duration) * 100.0;
			this.jump.offset = failstatPosition[2] - this.takeoffOrigin[2];

			// Call the callback for the reporting.
			JumpReport_OnFailStat(this.jump);

			// Mark the calculation as successful
			this.failstatValid = true;
		}
		else
		{
			this.failstatFailed = true;
		}
	}

    float CalcDistance()
    {
        float distance = GetVectorHorizontalDistance(this.takeoffOrigin, this.position);

        // Check whether the distance is NaN
        if (distance != distance)
        {
            this.Invalidate();

            // We need that for the always stats
            float pos[3];

            // For the always stats it's ok to ignore the bug
            Movement_GetOrigin(this.jumper, pos);

            distance = GetVectorHorizontalDistance(this.takeoffOrigin, pos);
        }

        return distance + PLAYER_WIDTH;
    }

    void CalcTakeoff()
    {
        // MovementAPI now correctly calculates the takeoff origin
        // and velocity for jumpbugs. What is wrong though, is how
        // mode plugins set bhop prespeed.
        // Jumpbug takeoff origin is correct.
        Movement_GetTakeoffOrigin(this.jumper, this.takeoffOrigin);
        Movement_GetTakeoffVelocity(this.jumper, this.takeoffVelocity);

        if (this.jump.type == JumpType_Jumpbug || this.jump.type == JumpType_MultiBhop
            || this.jump.type == JumpType_Bhop || this.jump.type == JumpType_WeirdJump)
        {
            // Move the origin to the ground.
            // The difference can only be 2 units maximum.
            float bhopOrigin[3];
            CopyVector(this.takeoffOrigin, bhopOrigin);
            bhopOrigin[2] -= 2.0;
            TraceHullPosition(this.takeoffOrigin, bhopOrigin, playerMins, playerMaxs, this.takeoffOrigin);
        }

        this.jump.preSpeed = Movement_GetTakeoffSpeed(this.jumper);
        poseHistory[this.jumper][0].speed = this.jump.preSpeed;
    }

    void UpdateOnGround()
    {
        // We want accurate values to measure the first tick
        this.UpdatePose(poseHistory[this.jumper][0]);
    }

	// We split that up in two functions to get a reference to the pose so we
	// don't have to recalculate the pose index all the time.
	void UpdatePoseHistory()
	{
		this.poseIndex++;
		this.UpdatePose(pose(0));
	}

    void UpdatePose(Pose p)
    {
        Movement_GetProcessingOrigin(this.jumper, p.position);
        Movement_GetProcessingVelocity(this.jumper, p.velocity);
        Movement_GetEyeAngles(this.jumper, p.orientation);
        p.speed = GetVectorHorizontalLength(p.velocity);

        // We use the current position in a lot of places, so we store it
        // separately to avoid calling 'pose' all the time.
        CopyVector(p.position, this.position);
    }

    // We split that up in two functions to get a reference to the pose so we
    // don't have to recalculate the pose index all the time. We seperate that
    // from UpdatePose() cause those stats are not calculated yet when we call that.
    void UpdatePoseStats()
    {
        this.UpdatePoseStats_P(pose(0));
    }

    void UpdatePoseStats_P(Pose p)
    {
        p.duration = this.jump.duration;
        p.syncTicks = this.syncTicks;
        p.overlap = this.jump.overlap;
        p.deadair = this.jump.deadair;
    }

    void Invalidate()
    {
        if (this.jump.type != JumpType_Invalid &&
            this.jump.type != JumpType_FullInvalid)
        {
            this.jump.type = JumpType_Invalid;
            //OnJumpInvalidated();
        }
    }

    bool IsValidAirtime()
    {
        // Crouchjumped or perfed longjumps/bhops can have a maximum of 101 airtime
        // when the lj bug occurs. Since we've fixed that the airtime is valid.
        if (this.jump.duration <= 101)
        {
            return true;
        }

        return false;
    }

    void UpdateStrafes()
    {
        // Strafe direction
        if (Movement_GetTurningLeft(this.jumper) &&
            this.strafeDirection != StrafeDirection_Left)
        {
            this.strafeDirection = StrafeDirection_Left;
            this.jump.strafes++;
        }
        else if (Movement_GetTurningRight(this.jumper) &&
                 this.strafeDirection != StrafeDirection_Right)
        {
            this.strafeDirection = StrafeDirection_Right;
            this.jump.strafes++;
        }

        // Overlap / Deadair
        int buttons = Movement_GetButtons(this.jumper);
        int overlap = buttons & IN_MOVERIGHT && buttons & IN_MOVELEFT ? 1 : 0;
        int deadair = !(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT) ? 1 : 0;

        // Sync / Gain / Loss
        float deltaSpeed = pose(0).speed - pose(-1).speed;
        bool gained = deltaSpeed > EPSILON;
        bool lost = deltaSpeed < -EPSILON;

        // Width
        float width = FloatAbs(CalcDeltaAngle(pose(0).orientation[1], pose(-1).orientation[1]));

        // Overall stats
        this.jump.overlap += overlap;
        this.jump.deadair += deadair;
        this.jump.width += width;

        // Individual stats
        if (this.jump.strafes >= JS_MAX_TRACKED_STRAFES)
        {
            return;
        }

        int i = this.jump.strafes;
        this.jump.strafes_ticks[i]++;

        this.jump.strafes_overlap[i] += overlap;
        this.jump.strafes_deadair[i] += deadair;
        this.jump.strafes_loss[i] += lost ? -1 * deltaSpeed : 0.0;
        this.jump.strafes_width[i] += width;

        if (gained)
        {
            this.jump.strafes_gainTicks[i]++;
            this.jump.strafes_gain[i] += deltaSpeed;
        }
    }

    void GetFailOrigin(float planeHeight, float result[3], int poseIndex)
    {
        float newVel[3], oldVel[3];

        // Calculate the actual velocity.
        CopyVector(pose(poseIndex).velocity, oldVel);
        ScaleVector(oldVel, GetTickInterval());

        // Calculate at which percentage of the velocity vector we hit the plane.
        float scale = (planeHeight - pose(poseIndex).position[2]) / oldVel[2];

        // Calculate the position we hit the plane.
        CopyVector(oldVel, newVel);
        ScaleVector(newVel, scale);
        AddVectors(pose(poseIndex).position, newVel, result);
    }

    void UpdateRelease()
    {
        // Using UpdateOnGround doesn't work because
        // takeoff tick is calculated after leaving the ground.
        this.jumpoffTick = Movement_GetTakeoffTick(this.jumper);

        // We also check IN_BACK cause that happens for backwards ladderjumps
        if (Movement_GetButtons(this.jumper) & IN_FORWARD ||
            Movement_GetButtons(this.jumper) & IN_BACK)
        {
            this.lastWPressedTick = this.tickCount;
        }
        else if (this.jump.releaseW > 99)
        {
            this.jump.releaseW = this.lastWPressedTick - this.jumpoffTick + 1;
        }

        if (Movement_GetButtons(this.jumper) & IN_DUCK)
        {
            this.lastCrouchPressedTick = this.tickCount;
            this.nextCrouchRelease = 100;
        }
        else if (this.nextCrouchRelease > 99)
        {
            this.nextCrouchRelease = this.lastCrouchPressedTick - this.jumpoffTick - 95;
        }
    }

	void AlwaysFailstat()
	{
		bool foundBlock;
		int coordDist, distSign;
		float traceStart[3], traceEnd[3], tracePos[3], landingPos[3], orientation[3], failOrigin[3];

		// Check whether the jump was already handled
		if (this.jump.type == JumpType_FullInvalid || this.failstatValid)
		{
			return;
		}

		// Initialize the trace boxes
		float traceMins[3] = { 0.0, 0.0, 0.0 };
		float traceLongMaxs[3] = { 0.0, 0.0, 200.0 };
		float traceShortMaxs[3] = { 0.0, 0.0, 54.0 };

		// Clear the stats
		this.jump.miss = 0.0;
		this.jump.distance = 0.0;

		// Calculate the edge
		this.CalcAlwaysEdge();

		// We will search for the block based on the direction the player was looking
		CopyVector(pose(0).orientation, orientation);

		// Get the landing orientation
		coordDist = FloatAbs(orientation[0]) < FloatAbs(orientation[1]);
		distSign = orientation[coordDist] > 0 ? 1 : -1;

		// Initialize the traces
		CopyVector(this.position, traceStart);
		CopyVector(this.position, traceEnd);

		// Assume the miss is less than 100 units
		traceEnd[coordDist] += 100.0 * distSign;

		// Search for the end block with the long trace
		foundBlock = TraceHullPosition(traceStart, traceEnd, traceMins, traceLongMaxs, tracePos);

		// If not even the long trace finds the block, we're out of luck
		if (foundBlock)
		{
			// Search for the block height
			tracePos[2] = this.position[2];
			foundBlock = TryFindBlockHeight(tracePos, landingPos, coordDist, distSign);

			// Maybe there was a headbanger, try with the short trace instead
			if (!foundBlock)
			{
				if (TraceHullPosition(traceStart, traceEnd, traceMins, traceShortMaxs, tracePos))
				{
					// Search for the height again
					tracePos[2] = this.position[2];
					foundBlock = TryFindBlockHeight(tracePos, landingPos, coordDist, distSign);
				}
			}

			if (foundBlock)
			{
				// Search for the last tick the player was above the landing block elevation.
				for (int i = 0; i < JS_FAILSTATS_MAX_TRACKED_TICKS; i++)
				{
					Pose p;

					// This copies it, but it shouldn't be that much of a problem
					p = pose(-i);

					if(p.position[2] >= landingPos[2])
					{
						// Calculate the correct fail position
						this.GetFailOrigin(landingPos[2], failOrigin, -i);

						// Calculate all missing stats
						this.jump.miss = FloatAbs(failOrigin[coordDist] - landingPos[coordDist]) - 16.0;
						this.jump.distance = GetVectorHorizontalDistance(failOrigin, this.takeoffOrigin);
						this.jump.offset = failOrigin[2] - this.takeoffOrigin[2];
						this.jump.duration = p.duration;
						this.jump.overlap = p.overlap;
						this.jump.deadair = p.deadair;
						this.jump.sync = float(p.syncTicks) / float(this.jump.duration) * 100.0;
						break;
					}
				}
			}
		}

		// Notify everyone about the jump
		JumpReport_OnFailstatAlways(this.jump);

		// Fully invalidate the jump cause we failstatted it already
		this.jump.type = JumpType_FullInvalid;
	}

}

static JumpTracker jumpTrackers[MAXPLAYERS + 1];

public void JumpTracking_OnValidJump(int client, bool jumped, bool jumpbug)
{
	if (!validCmd[client])
	{
		return;
	}

	// Update: Takeoff speed should be always correct with the new MovementAPI.
	if (jumped)
	{
	    Chat_Debug(client, "JumpTracking_OnValidJump: jumped");
		jumpTrackers[client].lastJumpTick = jumpTrackers[client].tickCount;
	}

	jumpTrackers[client].Reset(jumped, jumpbug);
	jumpTrackers[client].Begin();
}

void JumpTracking_OnStartTouchGround(int client)
{
	if (!doFailstatAlways[client])
	{
		jumpTrackers[client].End();
	}
}

void JumpTracking_OnPlayerRunCmd(int client, int buttons, int tickcount)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	jumpTrackers[client].tickCount = tickcount;

	if (GetClientButtons(client) & IN_JUMP)
	{
		lastJumpButtonTime[client] = GetGameTime();
	}

	if (CheckNoclip(client))
	{
		lastNoclipTime[client] = GetGameTickCount();
	}

	// Don't bother checking if player is already in air and jumpstat is already invalid
	if (Movement_GetOnGround(client) ||
		jumpTrackers[client].jump.type != JumpType_FullInvalid)
	{
		UpdateValidCmd(client, buttons);
	}
}

void JumpTracking_OnStartTouch(int client)
{
	entityTouchCount[client]++;
	// Do not immediately invalidate jumps upon collision.
	// Give the player a few ticks of leniency for late ducking.
}

void JumpTracking_OnTouch(int client)
{
	if (entityTouchCount[client] > 0)
	{
		entityTouchDuration[client]++;
	}
	if (!Movement_GetOnGround(client) && entityTouchDuration[client] > JS_TOUCH_GRACE_TICKS)
	{
		jumpTrackers[client].Invalidate();
	}
}

void JumpTracking_OnEndTouch(int client)
{
	entityTouchCount[client]--;
	if (entityTouchCount[client] == 0)
	{
		entityTouchDuration[client] = 0;
	}
}


public void JumpTracking_OnPlayerRunCmdPost(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	// Check for always failstats
	if (doFailstatAlways[client])
	{
		doFailstatAlways[client] = false;
		// Prevent TP shenanigans that would trigger failstats
		//jumpTypeLast[client] = JumpType_Invalid;

		//todo: if (GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Enabled &&
		//todo: 	isInAir[client])
		//todo: {
		//todo: 	jumpTrackers[client].AlwaysFailstat();
		//todo: }
	}

	if (!Movement_GetOnGround(client))
	{
		isInAir[client] = true;
		jumpTrackers[client].Update();
	}

	if (Movement_GetOnGround(client))
	{
		isInAir[client] = false;
		jumpTrackers[client].UpdateOnGround();
	}

	// We always have to track this, no matter if in the air or not
	jumpTrackers[client].UpdateRelease();

	if (Movement_GetDuckbugged(client))
	{
		lastDuckbugTime[client] = GetGameTickCount();
	}
}

public void JumpTracking_OnClientPutInServer(int client)
{
	entityTouchCount[client] = 0;
	lastNoclipTime[client] = 0;
	lastDuckbugTime[client] = 0;
	lastJumpButtonTime[client] = 0.0;
	jumpTrackers[client].Init(client);
}

public void JumpTracking_OnTeleport(int client)
{
	// We want to synchronize all of that
	doFailstatAlways[client] = true;

	// gokz-core does that too, but for some reason we have to do it again
	InvalidateJumpstat(client);

	jumpTrackers[client].lastTeleportTick = jumpTrackers[client].tickCount;
}

static void UpdateValidCmd(int client, int buttons)
{
	if (!CheckGravity(client)
		 || !CheckBaseVelocity(client)
		 || !CheckInWater(client)
		 || !CheckTurnButtons(buttons))
	{
		InvalidateJumpstat(client);
		validCmd[client] = false;
	}
	else
	{
		validCmd[client] = true;
	}

	if (GetGameTickCount() - lastNoclipTime[client] < 4)
	{
		jumpTrackers[client].jump.type = JumpType_FullInvalid;
	}
}

static bool CheckGravity(int client)
{
	float gravity = Movement_GetGravity(client);
	// Allow 1.0 and 0.0 gravity as both values appear during normal gameplay
	if (FloatAbs(gravity - 1.0) > EPSILON && FloatAbs(gravity) > EPSILON)
	{
		return false;
	}
	return true;
}

static bool CheckBaseVelocity(int client)
{
	float baseVelocity[3];
	Movement_GetBaseVelocity(client, baseVelocity);
	if (FloatAbs(baseVelocity[0]) > EPSILON ||
		FloatAbs(baseVelocity[1]) > EPSILON ||
		FloatAbs(baseVelocity[2]) > EPSILON)
	{
		return false;
	}
	return true;
}

static bool CheckInWater(int client)
{
	int waterLevel = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	return waterLevel == 0;
}

static bool CheckTurnButtons(int buttons)
{
	// Don't allow +left or +right turns binds
	return !(buttons & (IN_LEFT | IN_RIGHT));
}

static bool CheckNoclip(int client)
{
	return Movement_GetMovetype(client) == MOVETYPE_NOCLIP;
}

void InvalidateJumpstat(int client)
{
	jumpTrackers[client].Invalidate();
}

float GetStrafeSync(Jump jump, int strafe)
{
	if (strafe < JS_MAX_TRACKED_STRAFES)
	{
		return float(jump.strafes_gainTicks[strafe])
			 / float(jump.strafes_ticks[strafe])
			 * 100.0;
	}
	else
	{
		return 0.0;
	}
}

float GetStrafeAirtime(Jump jump, int strafe)
{
	if (strafe < JS_MAX_TRACKED_STRAFES)
	{
		return float(jump.strafes_ticks[strafe])
			 / float(jump.duration)
			 * 100.0;
	}
	else
	{
		return 0.0;
	}
}