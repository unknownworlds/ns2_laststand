// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//
// lua\PathingMixin.lua    
//
// Created by: Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PathingUtility.lua")

PathingMixin = CreateMixin( PathingMixin )
PathingMixin.type = "Pathing"

local pi2 = math.pi * 2

kDefaultTurnSpeed = math.pi // 180 degrees per second
kDefaultMaxSpeedAngle = math.pi / 18 // 10 degrees
kDefaultNoSpeedAngle = math.pi / 4 // 45 degrees

PathingMixin.expectedCallbacks =
{
    GetIsFlying = "Required to allow vertical paths."
}

function PathingMixin:__initmixin()

    // the current path
    self.points = nil
    // the current cursor along that path
    self.cursor = nil
    
end

function PathingMixin:GetPoints()
    return self.points
end

function PathingMixin:GetNumPoints()
    return (self.points and #(self.points)) or 0
end

function PathingMixin:GetPath(src, dst)
    return GeneratePath(src, dst, false, 0.5, 2, self:GetIsFlying())
end

local function DebugDrawPoints(points, lifetime, r, g, b, a)
    
    for index = 2, table.count(points) do
        DebugLine(points[index - 1], points[index], lifetime, r, g, b, a)    
    end
        
end

function PathingMixin:GetMoveDirection()

    if self.cursor then
        return self.cursor:GetDirection()
    end
    
    return self:GetCoords().zAxis
    
end

function PathingMixin:NormalizeYaw(yaw)

    yaw = yaw % pi2
    return yaw < 0 and (yaw + pi2) or yaw
    
end

function PathingMixin:GetTurnSpeed()

    local result = kDefaultTurnSpeed
    if self.GetTurnSpeedOverride then
        result = self:GetTurnSpeedOverride()
    end
    
    return result
    
end

//
// Return a pair of speed limit angles used when determining how fast you can turn when moving. 
// The first angle is the angle when you can go at maximum speed, the second is the angle at
// which you have to stop completly while waiting for the unit to turn.
//
function PathingMixin:GetSpeedLimitAngles()

    local result = { kDefaultMaxSpeedAngle, kDefaultNoSpeedAngle }
    if self.GetSpeedLimitAnglesOverride then
        result = self:GetSpeedLimitAnglesOverride()
    end
    
    return result
    
end

function PathingMixin:GetDeltaYaw(yawFrom, yawTo)

    // dYaw is how much yaw we want to turn.
    local dYaw = (yawFrom - yawTo)
    // make sure we turn the shortest direction
    dYaw = dYaw < math.pi and dYaw or (dYaw - pi2)
    dYaw = dYaw > -math.pi and dYaw or (dYaw + pi2) 
    
    return dYaw
    
end

//
// returns the turning amount during the given time and turnspeed when 
// turning towards desiredYaw from currentYaw
//
function PathingMixin:CalcTurnAmount(desiredYaw, currentYaw, turnSpeed, time)

    local dYaw = self:GetDeltaYaw(desiredYaw,currentYaw)
    local turnAmount = math.min(math.abs(dYaw), time * turnSpeed) * (dYaw < 0 and -1 or 1)
    turnAmount = math.abs(turnAmount) > 0.001 and turnAmount or 0 
    return turnAmount,dYaw - turnAmount
    
end

// fraction of max speed that the yaw results in.
// yaw < maxSpeed -> 1
// yaw > minSpeed -> 0
// otherwise linear scaling between them
function PathingMixin:CalcYawSpeedFraction(yaw, maxSpeedAngle, minSpeedAngle)
    return (1 - math.max(0, math.min(1, (math.abs(yaw) - maxSpeedAngle) / ( minSpeedAngle - maxSpeedAngle))))
end

//
// Turn smoothly towards the goal direction.
// Returns the movespeed that the turn allows.
// Can be improved to take momentum into consideration.
//
function PathingMixin:SmoothTurn(time, direction, moveSpeed)

    assert(time)
    assert(direction)
    assert(moveSpeed)
    
    // smooth turning
    local angles = self:GetAngles()
    local currentYaw = self:NormalizeYaw(angles.yaw)
    local desiredYaw = self:NormalizeYaw(GetYawFromVector(direction))
    local turnAmount,remainingYaw = self:CalcTurnAmount(desiredYaw, currentYaw, self:GetTurnSpeed(), time)
    
    angles.yaw = self:NormalizeYaw(currentYaw + turnAmount)
    self:SetAngles(angles)
    // speed is maximum inside the maxSpeedAngle, and zero at noSpeedAngle, and vary constantly between them
    local maxSpeedAngle,minSpeedAngle = unpack(self:GetSpeedLimitAngles())
    moveSpeed = moveSpeed * self:CalcYawSpeedFraction(remainingYaw, maxSpeedAngle, minSpeedAngle)
    if self.SmoothTurnOverride then
        moveSpeed = self:SmoothTurnOverride(time, direction, moveSpeed)
    end
    
    // a turn limit may never limit the speed below 10% of speed, as speed zero would just stop us completly...
    return moveSpeed
    
end

function PathingMixin:IsTargetReached(endPoint, requiredDistanceToTarget)
    
    if not self:CheckTarget(endPoint) then
        return false
    end
    
    return self.cursor:GetRemainingDistance() < requiredDistanceToTarget
    
end

//
// make sure we have a path to the target
// returns false if no path found.
//
function PathingMixin:CheckTarget(endPoint)

    // if we don't have a cursor, or the targetPoint differs, create a new path
    if self.cursor == nil or (self.targetPoint - endPoint):GetLengthXZ() > 0.1 then
    
        // our current cursor is invalid or pointing to another endpoint, so build a new one
        self.points = GeneratePath(self:GetOrigin(), endPoint, false, 0.5, 2, self:GetIsFlying())
        if self.points == nil then
        
            // Can't reach the endPoint.
            return false
            
        end
        self.targetPoint = endPoint
        // the list of points does not include our current origin. Simplify the remaining code
        // by adding our origin to the list of points
        table.insert(self.points, 1, self:GetOrigin())
        
        self.cursor = PathCursor():Init(self.points)
        
    end
    
    return true
    
end

function PathingMixin:SetCurrentPositionValid(position)

    if self.cursor then
    
        self.cursor = nil
        self.points = nil
        self:CheckTarget(self.targetPoint)
        
    end
    
end

function PathingMixin:OnObstacleChanged()
    self.resetAtTime = Shared.GetTime() + 0.2
end

// hack, there seems to be a delay when an obstacle is added and the pathing mesh updated
function PathingMixin:ResetPathing()
    self.cursor = nil
    self.points = nil
    self.targetPoint = nil
end

//
// Move towards the given endPoint at given speed and time.
// Return true if we have gone as far as we can, which can indicate that we can't reach the target
//
function PathingMixin:MoveToTarget(physicsGroupMask, endPoint, movespeed, time)

    PROFILE("PathingMixin:MoveToTarget")
    
    if self.resetAtTime and self.resetAtTime < Shared.GetTime() then
        self:ResetPathing()
        self.resetAtTime = nil
    end
    
    if not self:CheckTarget(endPoint) then
        return true
    end
    
    // save the cursor in case we need to slow down
    local origCursor = PathCursor():Clone(self.cursor)
    self.cursor:Advance(movespeed, time)
    
    local maxSpeed = moveSpeed
    
    maxSpeed = self:SmoothTurn(time, self.cursor:GetDirection(), movespeed)
    // Don't move during repositioning
    if HasMixin(self, "Repositioning") and self:GetIsRepositioning() then
    
        maxSpeed = 0
        return false
        
    end
    
    if maxSpeed < movespeed then
        // use the copied cursor and discard the current cursor
        self.cursor = origCursor
        self.cursor:Advance(maxSpeed, time)
    end
    
    // update our position to the cursors position, after adjusting for ground or hover
    local newLocation = self.cursor:GetPosition()          
    if self:GetIsFlying() then        
        newLocation = GetHoverAt(self, newLocation, EntityFilterMixinAndSelf(self, "Repositioning"))
    else
        newLocation = GetGroundAt(self, newLocation, PhysicsMask.Movement, EntityFilterMixinAndSelf(self, "Repositioning"))
    end
    self:SetOrigin(newLocation)
         
    // we are done if we have reached the last point in the path or we have a close-enough condition
    local done = self.cursor:TargetReached()
    if done then
    
        self.cursor = nil
        self.points = nil
        
    end
    return done
    
end

//
// the PathCursor class is responsible for moving along a list of point.
// It tracks what point is is on and how far it has moved along the vector to the next point, 
// and what direction is is travelling in, and if it has reached its target yet. 
// 
// The state is the points, the index of the current point and the fraction moved to the next point.
// 
class 'PathCursor'

function PathCursor:Init(points)

    ASSERT(points ~= nil)
    ASSERT(#points >= 1)
    
    self.points = points
    self.remainingDistance = GetPointDistance(self.points)
    self:StartOnSegment(1)
    return self
    
end

// clone another cursor
function PathCursor:Clone(other)

    self.points = other.points
    self:StartOnSegment(other.index)
    self.segmentFraction = other.segmentFraction
    self.remainingDistance = other.remainingDistance
    return self
    
end

function PathCursor:GetRemainingDistance()
    return self.remainingDistance
end

function PathCursor:TargetReached()
    return self.index == #self.points
end

function PathCursor:SetPositionValid(position)
    
    self.points[self.index] = position
    
    if self.index ~= 1 then
    
        for i = 1, self.index - 1 do
            table.remove(self.points, i)
        end
        
    end
    
    self.remainingDistance = GetPointDistance(self.points)
    self:StartOnSegment(1)
    
    return self.points
    
end

function PathCursor:GetPosition()
    return self.points[self.index] + self.segment * self.segmentFraction
end

function PathCursor:GetDirection()

    assert(self.segmentDirection)
    return self.segmentDirection
    
end

// setup to start on a particular segment.
// we cache the segment itself, its length and its direction
function PathCursor:StartOnSegment(index)

    local numPoints = #self.points
    assert(index <= numPoints)
    assert(index >= 1)    
    
    self.index = index
    if index < numPoints then
    
        self.segment = self.points[index+1]-self.points[index]
        self.segmentDirection = Vector(self.segment)
        self.segmentDirection:Normalize()
        
    else
    
        self.segment = Vector(0, 0, 0)
        // Keep the previous direction unless there was not a previous one.
        if not self.segmentDirection then
            self.segmentDirection = Vector(0, 1, 0)
        end
        
    end
    
    self.segmentLength = self.segment:GetLength()
    self.segmentFraction = 0
    
end


// advance the position
function PathCursor:Advance(speed, deltaTime)

    local distanceToMove = deltaTime * speed
    while not self:TargetReached() and distanceToMove > 0 do
    
        local amountLeftOnThisSegment = self.segmentLength * (1-self.segmentFraction)    
        local used = math.min(amountLeftOnThisSegment, distanceToMove)
        
        distanceToMove = distanceToMove - used
        self.remainingDistance = self.remainingDistance - used
        self.segmentFraction = self.segmentFraction + used / self.segmentLength
        
        if distanceToMove > 0 then
            self:StartOnSegment(self.index + 1) 
        end
        
    end
    
end 