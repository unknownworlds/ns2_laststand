//=============================================================================
//
// lua\Ballistics.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// Utility functions regarding ballistics calculations.
//
//=============================================================================


Ballistics = {}

Ballistics.kGravity = 9.81

/**
 * Calculate the direction you want to aim at if you want to hit targetPos from 
 * startPos at the given speed. 
 */
function Ballistics.GetAimDirection(startPos, targetPos, speed)

    local direction = targetPos - startPos
    local xzRangeToTarget =  direction:GetLengthXZ()
    local xzSpeed = (GetNormalizedVectorXY(direction) * speed):GetLength()
    local timeToTarget = xzRangeToTarget / xzSpeed
    local gravityDrop =  Ballistics.kGravity * timeToTarget * timeToTarget / 2
    direction.y = direction.y + gravityDrop
    direction:Normalize()
    return direction
    
end

/**
 * Find the direction and speed to shoot for if you want to hit targetPos from startPos with the
 * given maxSpeed AND you must shoot above the given blockPos.
 * blockPos may be nil.
 * May return nil if no solution exists, otherwise returns teh direction,speed tuple.
 */
function Ballistics.GetBlockAvoidanceDirectionSpeed(startPos, targetPos, maxSpeed, blockPos)

    local speed = maxSpeed
    local resultDir = Ballistics.GetAimDirection(startPos, targetPos, speed)
    
    if blockPos then
    
        local blockDir = Ballistics.GetAimDirection(startPos, blockPos, speed)
        //Log("blockPos %s, r %s, b %s", blockPos, resultDir, blockDir)
        if blockDir.y > resultDir.y then
        
            // Adjust speed and direction to avoid the blocking position.
            local targetVec = (targetPos - startPos)
            local xzRangeToTarget = targetVec:GetLengthXZ() 
            // we fudge a bit here; we draw a line from the start to the block,
            // and from the target to the block, then calculate the height at
            // the midpoint for both of them, and take the max height for them
            // to figure out how much upvards velocity we need, and then we 
            // figure out how long it will take us to reach that height, and
            // that will give us the initial speed and direction
            local startToBlockVec = GetNormalizedVector(blockPos - startPos)
            local startToBlockTop = startToBlockVec * xzRangeToTarget / 2
            local targetToBlockVec = GetNormalizedVector(blockPos - targetPos)
            local targetToBlockTop = targetToBlockVec * xzRangeToTarget / 2
            
            local height = math.max(startToBlockTop.y, targetToBlockTop.y)
            // vertical initial speed
            local tPeak = math.sqrt( 2 * height / Ballistics.kGravity)
            local v0 = Ballistics.kGravity * tPeak

            // speed 
            local xzSpeed = xzRangeToTarget / (2 * tPeak)     
            speed = math.sqrt(v0 * v0 + xzSpeed * xzSpeed)
            local aimPoint = targetVec / 2
            aimPoint.y = height
            aimPoint = aimPoint + startPos
            resultDir = Ballistics.GetAimDirection(startPos, aimPoint, speed)
            
        end
        
    end
    
    if speed > maxSpeed then
        return nil, nil
    end
    
    return resultDir,speed
    
end
