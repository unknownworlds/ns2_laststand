// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//                  Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")
Script.Load("lua/Weapons/Alien/Parasite.lua")
Script.Load("lua/Weapons/Alien/XenocideLeap.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")
Script.Load("lua/RailgunTargetMixin.lua")

class 'Skulk' (Alien)

Skulk.kMapName = "skulk"

Skulk.kModelName = PrecacheAsset("models/alien/skulk/skulk.model")
local kViewModelName = PrecacheAsset("models/alien/skulk/skulk_view.model")
local kSkulkAnimationGraph = PrecacheAsset("models/alien/skulk/skulk.animation_graph")

if Server then
    Script.Load("lua/Skulk_Server.lua", true)
elseif Client then
    Script.Load("lua/Skulk_Client.lua", true)
end

local networkVars =
{
    wallWalking = "compensated boolean",
    timeLastWallWalkCheck = "private compensated time",
    leaping = "compensated boolean",
    timeOfLeap = "private compensated time",
    // wallwalking is enabled only after we bump into something that changes our velocity
    // it disables when we are on ground or after we jump or leap
    wallWalkingEnabled = "private compensated boolean",
    timeOfLastJumpLand = "private compensated time",
    timeLastWallJump = "private compensated time",
    jumpLandSpeed = "private compensated float"

}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)

// Balance, movement, animation
Skulk.kJumpRepeatTime = 0.1
Skulk.kViewOffsetHeight = .55
Skulk.kHealth = kSkulkHealth
Skulk.kArmor = kSkulkArmor
Skulk.kLeapVerticalVelocity = 8
Skulk.kLeapVerticalForce = 7
Skulk.kMinLeapVelocity = 12
Skulk.kLeapTime = 0.2
Skulk.kLeapForce = 6.5
Skulk.kMaxSpeed = 7.0

Skulk.kMaxWalkSpeed = Skulk.kMaxSpeed / 2
Skulk.kWallJumpInterval = 0.3

Skulk.kAcceleration = 64
Skulk.kGroundFriction = 9.15
Skulk.kGroundWalkFriction = 15

Skulk.kMass = 45 // ~100 pounds
Skulk.kWallWalkCheckInterval = .1
// This is how quickly the 3rd person model will adjust to the new normal.
Skulk.kWallWalkNormalSmoothRate = 4
// How big the spheres are that are casted out to find walls, "feelers".
// The size is calculated so the "balls" touch each other at the end of their range
Skulk.kNormalWallWalkFeelerSize = 0.25
Skulk.kNormalWallWalkRange = 0.3
Skulk.kNormalWallWalkPredictionRange = 2.5

// jump is valid when you are close to a wall but not attached yet at this range
Skulk.kJumpWallRange = 0.4
Skulk.kJumpWallFeelerSize = 0.1

// when we slow down to less than 97% of previous speed we check for walls to attach to
Skulk.kWallStickFactor = 1

Skulk.kXExtents = .45
Skulk.kYExtents = .45
Skulk.kZExtents = .45

Skulk.kJumpHeight = 1.3

// force added to skulk, depends on timing
Skulk.kWallJumpYBoost = 2.5
Skulk.kWallJumpYDirection = 5

Skulk.kMaxVerticalAirAccel = 12

Skulk.kWallJumpForce = 1.2
Skulk.kMinWallJumpSpeed = 9

Skulk.kAirZMoveWeight = 5
Skulk.kAirStrafeWeight = 2.5
Skulk.kAirAccelerationFraction = 0.5

function Skulk:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kSkulkFov })
    InitMixin(self, WallMovementMixin)
    
    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)
    InitMixin(self, BabblerClingMixin)
    InitMixin(self, TunnelUserMixin)
    
    if Client then
        InitMixin(self, RailgunTargetMixin)
    end
    
end

function Skulk:OnInitialized()

    Alien.OnInitialized(self)
    
    // Note: This needs to be initialized BEFORE calling SetModel() below
    // as SetModel() will call GetHeadAngles() through SetPlayerPoseParameters()
    // which will cause a script error if the Skulk is wall walking BEFORE
    // the Skulk is initialized on the client.
    self.currentWallWalkingAngles = Angles(0.0, 0.0, 0.0)
    
    self:SetModel(Skulk.kModelName, kSkulkAnimationGraph)
    
    self.wallWalking = false
    self.wallWalkingNormalGoal = Vector.yAxis
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        
        self:AddHelpWidget("GUIEvolveHelp", 2)
        self:AddHelpWidget("GUISkulkParasiteHelp", 1)
        self:AddHelpWidget("GUISkulkLeapHelp", 2)
        self:AddHelpWidget("GUIMapHelp", 1)
        
    end
    
    self.leaping = false
    
    self.timeLastWallJump = 0
    
end

function Skulk:GetInfestationBonus()
    return kSkulkInfestationSpeedBonus
end

function Skulk:GetCeleritySpeedModifier()
    return kSkulkCeleritySpeedModifier
end

function Skulk:GetCarapaceSpeedReduction()
    return kSkulkCarapaceSpeedReduction
end

function Skulk:GetBaseArmor()
    return Skulk.kArmor
end

function Skulk:GetArmorFullyUpgradedAmount()
    return kSkulkArmorFullyUpgradedAmount
end

function Skulk:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

function Skulk:GetCrouchShrinkAmount()
    return 0
end

function Skulk:GetExtentsCrouchShrinkAmount()
    return 0
end

// required to trigger wall walking animation
function Skulk:GetIsJumping()
    return Player.GetIsJumping(self) and not self.wallWalking
end

// The Skulk movement should factor in the vertical velocity
// only when wall walking.
function Skulk:GetMoveSpeedIs2D()
    return not self:GetIsWallWalking()
end

function Skulk:OnLeap()

    local velocity = self:GetVelocity() * 0.5
    local minSpeed = math.max(0, Skulk.kMinLeapVelocity - velocity:GetLengthXZ() - Skulk.kLeapVerticalForce) * self:GetMovementSpeedModifier()

    local forwardVec = self:GetViewAngles():GetCoords().zAxis
    local newVelocity = (velocity + GetNormalizedVectorXZ(forwardVec) * (Skulk.kLeapForce * self:GetMovementSpeedModifier() + minSpeed))
    
    // Add in vertical component.
    newVelocity.y = Skulk.kLeapVerticalVelocity * forwardVec.y + Skulk.kLeapVerticalForce * self:GetMovementSpeedModifier() + ConditionalValue(velocity.y < 0, velocity.y, 0)
    
    self:SetVelocity(newVelocity)
    
    self.leaping = true
    self.wallWalkingEnabled = false

    self.onGround = false
    self.onGroundNeedsUpdate = true
    
    self.timeOfLeap = Shared.GetTime()
    self.timeOfLastJump = Shared.GetTime()
    
end

function Skulk:GetRecentlyWallJumped()
    return self.timeLastWallJump + Skulk.kWallJumpInterval > Shared.GetTime()
end

function Skulk:GetCanWallJump()
    return self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(Skulk.kJumpWallRange, Skulk.kJumpWallFeelerSize) ~= nil)
end

function Skulk:GetViewModelName()
    return kViewModelName
end

function Skulk:GetCanJump()
    return Alien.GetCanJump(self) or self:GetCanWallJump()    
end

function Skulk:GetIsWallWalking()
    return self.wallWalking
end

function Skulk:GetIsLeaping()
    return self.leaping
end

// Skulks do not respect ladders due to their wall walking superiority.
function Skulk:GetIsOnLadder()
    return false
end

function Skulk:GetIsWallWalkingPossible() 
    return not self.crouching and not self:GetRecentlyJumped()
end

local function PredictGoal(self, velocity)

    local goal = self.wallWalkingNormalGoal
    if velocity:GetLength() > 1 and not self:GetIsOnSurface() then

        local movementDir = GetNormalizedVector(velocity)
        local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(movementDir * 2.5, 3, nil, false)

        if averageSurfaceNormal then        
            goal = averageSurfaceNormal    
        end

    end

    return goal

end

// Update wall-walking from current origin
function Skulk:PreUpdateMove(input, runningPrediction)

    PROFILE("Skulk:PreUpdateMove")
    
    self.moveButtonPressed = input.move:GetLength() ~= 0
    
    if not self.wallWalkingEnabled or not self:GetIsWallWalkingPossible() then
    
        self.wallWalking = false
        
    else

        // Don't check wall walking every frame for performance    
        if (Shared.GetTime() > (self.timeLastWallWalkCheck + Skulk.kWallWalkCheckInterval)) then

            // Most of the time, it returns a fraction of 0, which means
            // trace started outside the world (and no normal is returned)           
            local goal = self:GetAverageWallWalkingNormal(Skulk.kNormalWallWalkRange, Skulk.kNormalWallWalkFeelerSize)
            
            if goal ~= nil then
            
                self.wallWalkingNormalGoal = goal
                self.wallWalking = true
                       
            else
                self.wallWalking = false                
            end
            
            self.timeLastWallWalkCheck = Shared.GetTime()
            
        end 
        
    end
    
    // When not wall walking, the goal is always directly up (running on ground).
    if not self:GetIsWallWalking() then
    
        self.wallWalkingNormalGoal = Vector.yAxis
        
        if self:GetIsOnGround() then
            self.wallWalkingEnabled = false
        end
        
    end
    
    if self.leaping and (Alien.GetIsOnGround(self) or self.wallWalking) and (Shared.GetTime() > self.timeOfLeap + Skulk.kLeapTime) then
        self.leaping = false
    end
    
    self.currentWallWalkingAngles = self:GetAnglesFromWallNormal(PredictGoal(self, self:GetVelocity()) or Vector.yAxis) or self.currentWallWalkingAngles
    
end

function Skulk:GetAngleSmoothRate()

    if self:GetIsWallWalking() then
        return 1.5
    end

    return 7
    
end

function Skulk:GetRollSmoothRate()
    return 4
end

function Skulk:GetPitchSmoothRate()
    return 3
end

function Skulk:GetSlerpSmoothRate()
    return 5
end

function Skulk:GetDesiredAngles(deltaTime)
    return self.currentWallWalkingAngles
end 

function Skulk:GetHeadAngles()

    if self:GetIsWallWalking() then
        return self.currentWallWalkingAngles
    else
        return self:GetViewAngles()
    end

end

function Skulk:GetAngleSmoothingMode()

    if self:GetIsWallWalking() then
        return "quatlerp"
    else
        return "euler"
    end

end

function Skulk:GetIsUsingBodyYaw()

    return not self:GetIsWallWalking()

end


local kUpVector = Vector(0, 1, 0)
function Skulk:UpdatePosition(velocity, time)

    PROFILE("Skulk:UpdatePosition")

    local requestedVelocity = Vector(velocity)
    local moveDirection = GetNormalizedVector(velocity)
    local storeSpeed = false
    local hitEntities = nil
    
    if self.adjustToGround then
        velocity.y = 0
        self.adjustToGround = false
    end
    
    local wasOnGround = self:GetIsOnGround()
    local oldSpeed = velocity:GetLengthXZ()
    velocity, hitEntities, self.averageSurfaceNormal = Alien.UpdatePosition(self, velocity, time)
    local newSpeed = velocity:GetLengthXZ()
    
    // temp hack for skulks to easier maintain momentum. make second on ground check here and store the velocity
    local nextOnGround = self:GetIsCloseToGround(Player.kOnGroundDistance)

    if not self.wallWalkingEnabled then

        // we enable wallwalk if our new velocity is significantly smaller than the requested velocity
        if newSpeed < oldSpeed * Skulk.kWallStickFactor then
            self.wallWalkingEnabled = self:GetIsWallWalkingPossible()
        end

    end
    
    if not wasOnGround and nextOnGround then

        self.timeOfLastJumpLand = Shared.GetTime()
        self.jumpLandSpeed = requestedVelocity:GetLengthXZ()

    end
    
    // prevent jumping against the same wall constantly as a method to ramp up speed
    local steepImpact = self.averageSurfaceNormal ~= nil and hitEntities == nil and moveDirection:DotProduct(self.averageSurfaceNormal) < -.6
    // never lose speed on ground
    local groundSurface = self.averageSurfaceNormal ~= nil and kUpVector:DotProduct(self.averageSurfaceNormal) > .4
    
    //Print("steepImpact %s, groundSurface %s ",ToString(steepImpact), ToString(groundSurface))

    if steepImpact and not groundSurface then
        SetSpeedDebugText("flup %s", ToString(Shared.GetTime()))
        return velocity
    else
        return requestedVelocity
    end

end

function Skulk:UpdateCrouch()

    // Skulks cannot crouch!
    
end

function Skulk:GetMaxSpeed(possible)

    if possible then
        return Skulk.kMaxSpeed
    end

    local maxspeed = ConditionalValue(self.movementModiferState and self:GetIsOnSurface(), Skulk.kMaxWalkSpeed, Skulk.kMaxSpeed)    
    return maxspeed + (self:GetMovementSpeedModifier() - 1) * Skulk.kMaxSpeed
    
end

function Skulk:GetAcceleration()
    return Skulk.kAcceleration * self:GetMovementSpeedModifier()    
end

function Skulk:GetMass()
    return Skulk.kMass
end

function Skulk:GetRecentlyJumped()
    return not (self.timeOfLastJump == nil or (Shared.GetTime() > (self.timeOfLastJump + Skulk.kJumpRepeatTime)))
end

function Skulk:ModifyVelocity(input, velocity)

    local viewCoords = self:GetViewCoords()

    if self.jumpLandSpeed and self.timeOfLastJumpLand + 0.3 > Shared.GetTime() and input.move:GetLength() ~= 0 then
    
        // check if the current move is in the same direction as the requested move
        local moveXZ = GetNormalizedVectorXZ( viewCoords:TransformVector(input.move) )
        
        if moveXZ:DotProduct(GetNormalizedVectorXZ(velocity)) > 0.75 then
        
            local currentSpeed = velocity:GetLength()
            local prevY = velocity.y
            
            local scale = math.max(1, self.jumpLandSpeed / currentSpeed)        
            velocity:Scale(scale)
            velocity.y = prevY
        
        else
            self.jumpLandSpeed = 0
            self.timeOfLastJumpLand = 0
        end
    
    end

    Alien.ModifyVelocity(self, input, velocity)


    if not self:GetIsOnSurface() and input.move:GetLength() ~= 0 then

        local moveLengthXZ = velocity:GetLengthXZ()
        local previousY = velocity.y
        local adjustedZ = false

        if input.move.z ~= 0 then
        
            local redirectedVelocityZ = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * input.move.z
            redirectedVelocityZ.y = 0
            redirectedVelocityZ:Normalize()
            
            if input.move.z < 0 then
            
                if viewCoords:TransformVector(input.move):DotProduct(velocity) > 0 then
                
                    redirectedVelocityZ = redirectedVelocityZ + GetNormalizedVectorXZ(velocity) * 8
                    redirectedVelocityZ:Normalize()
                    
                    local xzVelocity = Vector(velocity)
                    xzVelocity.y = 0
                    
                    VectorCopy(velocity - (xzVelocity * input.time * 2), velocity)
                    
                end
                
            else
            
                redirectedVelocityZ = redirectedVelocityZ * input.time * Skulk.kAirZMoveWeight + GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()                
                redirectedVelocityZ:Scale(moveLengthXZ)
                redirectedVelocityZ.y = previousY
                
                adjustedZ = true
                
                VectorCopy(redirectedVelocityZ,  velocity)
            
            end
        
        end
        
        if input.move.x ~= 0  then
        
            local redirectedVelocityX = GetNormalizedVectorXZ(self:GetViewCoords().xAxis) * input.move.x
            redirectedVelocityX.y = 0
            redirectedVelocityX:Normalize()
            
            redirectedVelocityX = redirectedVelocityX * input.time * Skulk.kAirStrafeWeight + GetNormalizedVectorXZ(velocity)
            
            redirectedVelocityX:Normalize()            
            redirectedVelocityX:Scale(moveLengthXZ)
            redirectedVelocityX.y = previousY            
            VectorCopy(redirectedVelocityX,  velocity)
        
        end
        
    end

    // accelerate XZ speed when falling down
    if not self:GetIsOnSurface() and velocity:GetLengthXZ() < Skulk.kMaxVerticalAirAccel then
    
        local acceleration = 9
        local accelFraction = Clamp( (-velocity.y - 3.5) / 7, 0, 1)
        
        local addAccel = GetNormalizedVectorXZ(velocity) * accelFraction * input.time * acceleration

        velocity.x = velocity.x + addAccel.x
        velocity.z = velocity.z + addAccel.z
        
    end
    
end

function Skulk:ConstrainMoveVelocity(moveVelocity)

    // allow acceleration in air for skulks   
    if not self:GetIsOnSurface() then
    
        local speedFraction = Clamp(self:GetVelocity():GetLengthXZ() / self:GetMaxSpeed(), 0, 1)
        speedFraction = 1 - (speedFraction * speedFraction)
        moveVelocity:Scale(speedFraction * Skulk.kAirAccelerationFraction)
        
        if self:GetVelocity():GetLengthXZ() > 30 then
            Print("system crash!")
        end
        
    end
 
end

function Skulk:GetGroundFrictionForce()   

    local groundFriction = ConditionalValue(self.movementModiferState or self.crouching, Skulk.kGroundWalkFriction, Skulk.kGroundFriction ) 
    return groundFriction
    
end

function Skulk:GetAirFrictionForce()
    return 0.25
end 

function Skulk:GetFrictionForce(input, velocity)

    local friction = Player.GetFrictionForce(self, input, velocity)
    if self:GetIsWallWalking() then
        friction.y = -self:GetVelocity().y * self:GetGroundFrictionForce()
    end
    
    return friction

end

function Skulk:GetGravityAllowed()
    return not self:GetIsWallWalking()
end

function Skulk:GetIsOnSurface()
    return Alien.GetIsOnSurface(self) or self:GetIsWallWalking()
end

function Skulk:GetIsAffectedByAirFriction()
    return not self:GetIsOnSurface()
end

function Skulk:AdjustGravityForce(input, gravity)

    // No gravity when we're sticking to a wall.
    if self:GetIsWallWalking() then
        gravity = 0
    end
    
    return gravity
    
end

function Skulk:GetMoveDirection(moveVelocity)

    // Don't constrain movement to XZ so we can walk smoothly up walls
    if self:GetIsWallWalking() then
        return GetNormalizedVector(moveVelocity)
    end
    
    return Alien.GetMoveDirection(self, moveVelocity)
    
end

// Normally players moving backwards can't go full speed, but wall-walking skulks can
function Skulk:GetMaxBackwardSpeedScalar()
    return ConditionalValue(self:GetIsWallWalking(), 1, Alien.GetMaxBackwardSpeedScalar(self))
end

function Skulk:GetIsCloseToGround(distanceToGround)

    if self:GetIsWallWalking() then
        return false
    end
    
    return Alien.GetIsCloseToGround(self, distanceToGround)
    
end

function Skulk:GetPlayFootsteps()
    
    // Don't play footsteps when we're walking
    return self:GetVelocityLength() > .75 and not self.movementModiferState and not GetHasSilenceUpgrade(self) and not self:GetIsCloaked() and self:GetIsOnSurface() and self:GetIsAlive()
    
end

function Skulk:GetIsOnGround()
    return Alien.GetIsOnGround(self) and not self:GetIsWallWalking()    
end

function Skulk:GetJumpHeight()
    return Skulk.kJumpHeight
end

function Skulk:PerformsVerticalMove()
    return self:GetIsWallWalking()
end

function Skulk:GetJumpVelocity(input, velocity)

    local viewCoords = self:GetViewAngles():GetCoords()
    
    local soundEffectName = "jump"
    
    // we add the bonus in the direction the move is going
    local move = input.move
    move.x = move.x * 0.01
    
    if input.move:GetLength() ~= 0 then
        self.bonusVec = viewCoords:TransformVector(move)
    else
        self.bonusVec = viewCoords.zAxis
    end

    self.bonusVec.y = 0
    self.bonusVec:Normalize()
    
    if self:GetCanWallJump() then
    
        if not self:GetRecentlyWallJumped() then
        
            local previousVelLength = self:GetVelocityLength()
    
            velocity.x = velocity.x + self.bonusVec.x * Skulk.kWallJumpForce
            velocity.z = velocity.z + self.bonusVec.z * Skulk.kWallJumpForce
            
            local speedXZ = velocity:GetLengthXZ()
            if speedXZ < Skulk.kMinWallJumpSpeed then
            
                velocity.y = 0
                velocity:Normalize()
                velocity:Scale(Skulk.kMinWallJumpSpeed)
                
            end
            
            velocity.y = viewCoords.zAxis.y * Skulk.kWallJumpYDirection + Skulk.kWallJumpYBoost

        end
        
        // spamming jump against a wall wont help
        self.timeLastWallJump = Shared.GetTime()
        
    else
        
        velocity.y = math.sqrt(math.abs(2 * self:GetJumpHeight() * self:GetMixinConstants().kGravity))
        
    end
    
    self:TriggerEffects(soundEffectName, {surface = self:GetMaterialBelowPlayer()})
    
end

// skulk handles jump sounds itself
function Skulk:GetPlayJumpSound()
    return false
end

function Skulk:HandleJump(input, velocity)

    local success = Alien.HandleJump(self, input, velocity)
    
    if success then
    
        self.wallWalking = false
        self.wallWalkingEnabled = false
    
    end
        
    return success
    
end

function Skulk:OnUpdateAnimationInput(modelMixin)

    PROFILE("Skulk:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsLeaping() then
        modelMixin:SetAnimationInput("move", "leap")
    end
    
    modelMixin:SetAnimationInput("onwall", self:GetIsWallWalking() and not self:GetIsJumping())
    
end

// quick fix to prevent insane velocity values for skulk
function Skulk:OnClampSpeed(input, velocity)

    PROFILE("Skulk:OnClampSpeed")
    
    /*
    if self:GetIsOnSurface() then
    
        local moveSpeed = velocity:GetLength()
        if moveSpeed > 15 then
            velocity:Scale(15 / moveSpeed)            
        end
        
    end
    */
    
end

local kSkulkEngageOffset = Vector(0, 0.28, 0)
function Skulk:GetEngagementPointOverride()
    return self:GetOrigin() + kSkulkEngageOffset
end

function Skulk:GetCelerityAllowed()
    return Alien.GetCelerityAllowed(self) and not self.movementModiferState
end

Shared.LinkClassToMap("Skulk", Skulk.kMapName, networkVars)
