#define EPSILON 0.000001

public void CopyVector(const any src[3], any dest[3])
{
	dest[0] = src[0];
	dest[1] = src[1];
	dest[2] = src[2];
}

public bool TraceRayPosition(const float traceStart[3], const float traceEnd[3], float position[3])
{
	Handle trace = TR_TraceRayFilterEx(traceStart, traceEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceRayNormal(const float traceStart[3], const float traceEnd[3], float rayNormal[3])
{
	Handle trace = TR_TraceRayFilterEx(traceStart, traceEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetPlaneNormal(trace, rayNormal);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceRayPositionNormal(const float traceStart[3], const float traceEnd[3], float position[3], float rayNormal[3])
{
	Handle trace = TR_TraceRayFilterEx(traceStart, traceEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		TR_GetPlaneNormal(trace, rayNormal);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceHullPosition(const float traceStart[3], const float traceEnd[3], const float mins[3], const float maxs[3], float position[3])
{
	Handle trace = TR_TraceHullFilterEx(traceStart, traceEnd, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public void GetCoordOrientation(const float vec1[3], const float vec2[3], int &coordDist, int &distSign)
{
	coordDist = FloatAbs(vec1[0] - vec2[0]) < FloatAbs(vec1[1] - vec2[1]);
	distSign = vec1[coordDist] > vec2[coordDist] ? 1 : -1;
}

public float FindBlockHeight(const float origin[3], float offset, int coord, float searchArea)
{
    float block[3], traceStart[3], traceEnd[3], normalVector[3];

    // Setup the trace.
    CopyVector(origin, traceStart);
    traceStart[coord] += offset;
    CopyVector(traceStart, traceEnd);
    traceStart[2] += searchArea;
    traceEnd[2] -= searchArea;

    // Find the block height.
    if (!TraceRayPositionNormal(traceStart, traceEnd, block, normalVector)
        || FloatAbs(normalVector[2] - 1.0) > EPSILON)
    {
        return -99999999999999999999.0; // Let's hope that's wrong enough
    }

    return block[2];
}

public bool BlockAreEdgesParallel(const float startBlock[3], const float endBlock[3], float deviation, int coordDist, int coordDev)
{
    float start[3], end[3], offset;

    // We use very short rays to find the blocks where they're supposed to be and use
    // their normals to determine whether they're parallel or not.
    offset = startBlock[coordDist] > endBlock[coordDist] ? 0.1 : -0.1;

    // We search for the blocks on both sides of the player, on one of the sides
    // there has to be a valid block.
    start[coordDist] = startBlock[coordDist] - offset;
    start[coordDev] = startBlock[coordDev] - deviation;
    start[2] = startBlock[2];

    end[coordDist] = startBlock[coordDist] + offset;
    end[coordDev] = startBlock[coordDev] - deviation;
    end[2] = startBlock[2];

    if (BlockTraceAligned(start, end, coordDist))
    {
        start[coordDist] = endBlock[coordDist] + offset;
        end[coordDist] = endBlock[coordDist] - offset;
        if (BlockTraceAligned(start, end, coordDist))
        {
            return true;
        }
        start[coordDist] = startBlock[coordDist] - offset;
        end[coordDist] = startBlock[coordDist] + offset;
    }

    start[coordDev] = startBlock[coordDev] + deviation;
    end[coordDev] = startBlock[coordDev] + deviation;

    if (BlockTraceAligned(start, end, coordDist))
    {
        start[coordDist] = endBlock[coordDist] + offset;
        end[coordDist] = endBlock[coordDist] - offset;
        if (BlockTraceAligned(start, end, coordDist))
        {
            return true;
        }
    }

    return false;
}

public bool BlockTraceAligned(const float origin[3], const float end[3], int coordDist)
{
    float normalVector[3];
    if (!TraceRayNormal(origin, end, normalVector))
    {
        return false;
    }
    return FloatAbs(FloatAbs(normalVector[coordDist]) - 1.0) <= EPSILON;
}


public bool TryFindBlockHeight(const float position[3], float result[3], int coordDist, int distSign)
{
    float traceStart[3], traceEnd[3];

    // Setup the trace points
    CopyVector(position, traceStart);
    traceStart[coordDist] += distSign;
    CopyVector(traceStart, traceEnd);

    // We search in 54 unit steps
    traceStart[2] += 54.0;

    // We search with multiple trace starts in case the landing block has a roof
    for (int i = 0; i < 3; i += 1)
    {
        if (TraceRayPosition(traceStart, traceEnd, result))
        {
            // Make sure the trace didn't get stuck right away
            if (FloatAbs(result[2] - traceStart[2]) > EPSILON)
            {
                result[coordDist] -= distSign;
                return true;
            }
        }

        // Try the next are to find the block. We use two different values to have
        // some overlap in case the block perfectly aligns with the trace.
        traceStart[2] += 54.0;
        traceEnd[2] += 53.0;
    }

    return false;
}

public float FloatMax(float value1, float value2)
{
	if (value1 >= value2)
	{
		return value1;
	}
	return value2;
}

/**
 * Calculates the lowest angle from angle A to angle B.
 * Input and result angles are between -180 and 180.
 *
 * @param angleA		Angle A.
 * @param angleB		Angle B.
 * @return				Delta angle.
 */
public float CalcDeltaAngle(float angleA, float angleB)
{
	float difference = angleB - angleA;

	if (difference > 180.0)
	{
		difference = difference - 360.0;
	}
	else if (difference <= -180.0)
	{
		difference = difference + 360.0;
	}

	return difference;
}
