// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\SprintMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

SprintMixin = CreateMixin( SprintMixin )
SprintMixin.type = "Sprint"

// Max duration of sprint
SprintMixin.kMaxSprintTime = 12 // 2

// Rate at which max sprint time comes back when not sprinting (multiplier x time)
SprintMixin.kSprintRecoveryRate = .5 // 1

// Must have this much energy to start sprint
SprintMixin.kMinSprintTime = 5 // 1

// After this time, play extra sounds to indicate player is getting tired
SprintMixin.kSprintTiredTime = SprintMixin.kMaxSprintTime * 0.4

// Time it takes to get to top speed
SprintMixin.kSprintTime = 1.5 // 0.1

// Releasing the sprint key within this time after pressing it puts you in sprint mode 
SprintMixin.kSprintLockTime = .2

// Time it takes to come to rest
SprintMixin.kUnsprintTime = kMaxTimeToSprintAfterAttack

SprintMixin.kTiredSoundName = PrecacheAsset("sound/NS2.fev/marine/common/sprint_tired")

SprintMixin.expectedCallbacks =
{
    GetVelocity = "",
    GetActiveWeapon = "",
    GetOnGroundRecently = "",
    GetViewCoords = "",
}

SprintMixin.networkVars =
{
    // time left to sprint is calculated by the three variables sprinting, timeSprintChange and sprintTimeOnChange
    // time left = Clamp(sprintTimeOnChange + timn since sprint change * rateChange, 0, maxSprintTime
    sprinting                       = "private boolean",
    timeSprintChange                = "private time",
    sprintTimeOnChange              = "private float (0 to " .. SprintMixin.kMaxSprintTime .. " by 0.01)",
    
    desiredSprinting                = "private boolean",
    sprintingScalar                 = "private float (0 to 1 by 0.01)",

    
    // This is set to the current time whenever the key state changes to down
    sprintButtonDownTime            = "private time",
    sprintButtonUpTime              = "private time",
    sprintDownLastFrame             = "private boolean",
    sprintMode                      = "private boolean",
    requireNewSprintPress           = "private boolean",
}

function SprintMixin:__initmixin()

    self.sprinting = false
    self.timeSprintChange = Shared.GetTime()
    self.sprintTimeOnChange = SprintMixin.kMaxSprintTime

    self.desiredSprinting = false    
    self.sprintingScalar = 0
    
    self.sprintButtonDownTime = 0
    self.sprintButtonUpTime = 0
    self.sprintDownLastFrame = false
    self.sprintMode = false
    self.requireNewSprintPress = false

end

function SprintMixin:GetIsSprinting()
    return self.sprinting
end

function SprintMixin:GetSprintingScalar()
    return self.sprintingScalar
end

function SprintMixin:OnSprintQuickPress()

    if self.sprintMode then
        self.sprintMode = false
    else
    
        if self:GetSprintTime() > SprintMixin.kMinSprintTime then
            self.sprintMode = true
        end
        
    end
end

function SprintMixin:UpdateSprintMode(buttonDown)

    if buttonDown ~= self.sprintDownLastFrame then
    
        local time = Shared.GetTime()
        
        if buttonDown then
        
            self.sprintButtonDownTime = time
            self.requireNewSprintPress = false
            
        else
        
            if (time - self.sprintButtonDownTime) < SprintMixin.kSprintLockTime then
                self:OnSprintQuickPress()
            end
            self.sprintButtonUpTime = time                
            
        end
        
        self.sprintDownLastFrame = buttonDown
        
    end
    
end

function SprintMixin:UpdateSprintingState(input)

    PROFILE("SprintMixin:UpdateSprintingState")
    
    local velocity = self:GetVelocity()
    local speed = velocity:GetLength()
    
    local weapon = self:GetActiveWeapon()
    local deployed = not weapon or not weapon.GetIsDeployed or weapon:GetIsDeployed()
    local sprintingAllowedByWeapon = not deployed or not weapon or weapon:GetSprintAllowed()    

    local attacking = false
    if weapon and weapon.GetTryingToFire then
        attacking = weapon:GetTryingToFire(input)    
    end
    
    local onGroundRecently = self:GetOnGroundRecently()

    local buttonDown = (bit.band(input.commands, Move.MovementModifier) ~= 0)
    if not weapon or (not weapon.GetIsReloading or not weapon:GetIsReloading()) then
        self:UpdateSprintMode(buttonDown)
    end
    
    // Allow small little falls to not break our sprint (stairs)    
    self.desiredSprinting = (buttonDown or self.sprintMode) and sprintingAllowedByWeapon and speed > 1 and not self.crouching and onGroundRecently and not attacking and not self.requireNewSprintPress
    
    if input.move.z < kEpsilon then
        self.desiredSprinting = false
    else
    
        // Only allow sprinting if we're pressing forward and moving in that direction
        local normMoveDirection = GetNormalizedVectorXZ(self:GetViewCoords():TransformVector(input.move))
        local normVelocity = GetNormalizedVectorXZ(velocity)
        local viewFacing = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)
        
        if normVelocity:DotProduct(normMoveDirection) < 0.3 or normMoveDirection:DotProduct(viewFacing) < 0.2 then
            self.desiredSprinting = false
        end
        
    end
    
    if self.desiredSprinting ~= self.sprinting then
    
        // Only allow sprinting to start if we have some minimum energy (so we don't start and stop constantly)
        if not self.desiredSprinting or (self:GetSprintTime() >= SprintMixin.kMinSprintTime) then
    
            self.sprintTimeOnChange = self:GetSprintTime()
            self.timeSprintChange = Shared.GetTime()
            self.sprinting = self.desiredSprinting
            
            if self.sprinting then
            
                if self.OnSprintStart then
                    self:OnSprintStart()
                end
            
            else
            
                if self.OnSprintEnd then
                    self:OnSprintEnd()
                end
                
            end
            
        end
        
    end
    
    // Some things break us out of sprint mode
    if self.sprintMode and (attacking or speed <= 1 or not onGroundRecently or self.crouching) then
        self.sprintMode = false
        self.requireNewSprintPress = attacking
    end
    
    if self.desiredSprinting then
        self.sprintingScalar = Clamp((Shared.GetTime() - self.timeSprintChange) / SprintMixin.kSprintTime, 0, 1) // * self:GetSprintTime() / SprintMixin.kMaxSprintTime
    else
        self.sprintingScalar = 1 - Clamp((Shared.GetTime() - self.timeSprintChange) / SprintMixin.kUnsprintTime, 0, 1)
    end
            
end

function SprintMixin:OnUpdate(deltaTime)

    if self.OnUpdateSprint then
        self:OnUpdateSprint(self.sprinting)
    end

end

function SprintMixin:OnProcessMove(input)

    local deltaTime = input.time
    
    if self.OnUpdateSprint then
        self:OnUpdateSprint(self.sprinting)
    end
    
    if self.sprinting then
        
        if self:GetSprintTime() == 0 then
        
            self.sprintTimeOnChange = 0
            self.timeSprintChange = Shared.GetTime()
            self.sprinting = false

            if self.OnSprintEnd then
                self:OnSprintEnd()
            end
            
            // Play local sound when we're tired (max 1 playback)
            if Client and (Client.GetLocalPlayer() == self) then
                Shared.PlaySound(self, SprintMixin.kTiredSoundName)
            end
            
            self.sprintMode = false
          
            if self.sprintDownLastFrame then
                self.requireNewSprintPress = true
            end
            
        end

    else
    

        
    end
    
end

function SprintMixin:GetSprintTime()
    local dt = Shared.GetTime() - self.timeSprintChange
    local rate = self.sprinting and -1 or SprintMixin.kSprintRecoveryRate
    return Clamp(self.sprintTimeOnChange + dt * rate , 0, SprintMixin.kMaxSprintTime)
end

function SprintMixin:GetTiredScalar()
    return Clamp( (1 - (self:GetSprintTime() / SprintMixin.kMaxSprintTime) ) * 2, 0, 1)
end
