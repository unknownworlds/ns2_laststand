// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/SpitSpray.lua")
Script.Load("lua/Weapons/Alien/InfestationAbility.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/Weapons/Alien/BabblerAbility.lua")
Script.Load("lua/Weapons/Alien/BileBomb.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")
Script.Load("lua/RailgunTargetMixin.lua")

class 'Gorge' (Alien)

if Server then    
    Script.Load("lua/Gorge_Server.lua")
end

local networkVars =
{
    bellyYaw = "private float",
    timeSlideEnd = "private time",
    startedSliding = "private boolean",
    sliding = "boolean"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)

Gorge.kMapName = "gorge"

Gorge.kModelName = PrecacheAsset("models/alien/gorge/gorge.model")
local kViewModelName = PrecacheAsset("models/alien/gorge/gorge_view.model")
local kGorgeAnimationGraph = PrecacheAsset("models/alien/gorge/gorge.animation_graph")

Gorge.kSlideLoopSound = PrecacheAsset("sound/NS2.fev/alien/gorge/slide_loop")
Gorge.kBuildSoundInterval = .5
Gorge.kBuildSoundName = PrecacheAsset("sound/NS2.fev/alien/gorge/build")

Gorge.kXZExtents = 0.5
Gorge.kYExtents = 0.475

local kMass = 80
local kJumpHeight = 1.2
local kInfestationStartSlideForce = 7.5
local kStartSlideForce = 7
local kViewOffsetHeight = 0.6
local kMaxGroundSpeed = 5.1
local kMaxSlidingSpeed = 13
local kSlidingMoveInputScalar = 0.1
local kBuildingModeMovementScalar = 0.001
local kSlideCoolDown = 1.5

Gorge.kAirZMoveWeight = 2.5
Gorge.kAirStrafeWeight = 2.5
Gorge.kAirBrakeWeight = 0.1

local kGorgeBellyYaw = "belly_yaw"
local kGorgeLeanSpeed = 2

function Gorge:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kGorgeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, BabblerClingMixin)
    InitMixin(self, TunnelUserMixin)
    
    if Client then
        InitMixin(self, RailgunTargetMixin)
    end
    
    self.bellyYaw = 0
    self.timeSlideEnd = 0
    self.startedSliding = false
    self.sliding = false
    self.verticalVelocity = 0

end

function Gorge:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Gorge.kModelName, kGorgeAnimationGraph)
    
    if Server then
    
        self.slideLoopSound = Server.CreateEntity(SoundEffect.kMapName)
        self.slideLoopSound:SetAsset(Gorge.kSlideLoopSound)
        self.slideLoopSound:SetParent(self)
        
    elseif Client then
    
        self:AddHelpWidget("GUIGorgeHealHelp", 2)
        self:AddHelpWidget("GUIGorgeBellySlideHelp", 2)
        
    end
    
end

function Gorge:GetInfestationBonus()
    return kGorgeInfestationSpeedBonus
end

function Gorge:GetCeleritySpeedModifier()
    return kGorgeCeleritySpeedModifier
end

function Gorge:GetCarapaceSpeedReduction()
    return kGorgeCarapaceSpeedReduction
end

if Client then

    local kGorgeHealthbarOffset = Vector(0, 0.7, 0)
    function Gorge:GetHealthbarOffset()
        return kGorgeHealthbarOffset
    end  

    function Gorge:OverrideInput(input)

        // Always let the DropStructureAbility override input, since it handles client-side-only build menu

        local buildAbility = self:GetWeapon(DropStructureAbility.kMapName)

        if buildAbility then
            input = buildAbility:OverrideInput(input)
        end
        
        return Player.OverrideInput(self, input)
        
    end
    
end

function Gorge:GetBaseArmor()
    return kGorgeArmor
end

function Gorge:GetArmorFullyUpgradedAmount()
    return kGorgeArmorFullyUpgradedAmount
end

function Gorge:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Gorge:GetCrouchShrinkAmount()
    return 0
end

function Gorge:GetExtentsCrouchShrinkAmount()
    return 0
end

function Gorge:GetViewModelName()
    return kViewModelName
end

function Gorge:GetJumpHeight()
    return kJumpHeight
end

function Gorge:GetIsBellySliding()
    return self.sliding
end
/*
function Gorge:GetCanJump()
    return not self:GetIsBellySliding()
end
*/
local function GetIsSlidingDesired(self, input)

    if bit.band(input.commands, Move.MovementModifier) == 0 then
        return false
    end
    
    if self.crouching then
        return false
    end
    
    if self:GetVelocity():GetLengthXZ() < 3 or self:GetIsJumping() then
    
        if self:GetIsBellySliding() then    
            return false
        end 
           
    else
        
        local zAxis = self:GetViewCoords().zAxis
        zAxis.y = 0
        zAxis:Normalize()
        
        if GetNormalizedVectorXZ(self:GetVelocity()):DotProduct( zAxis ) < 0.2 then
            return false
        end
    
    end
    
    return true

end

// Handle transitions between starting-sliding, sliding, and ending-sliding
local function UpdateGorgeSliding(self, input)

    PROFILE("Gorge:UpdateGorgeSliding")
    
    local slidingDesired = GetIsSlidingDesired(self, input)
    if slidingDesired and not self.sliding and self.timeSlideEnd + kSlideCoolDown < Shared.GetTime() and self:GetIsOnGround() and self:GetEnergy() >= kBellySlideCost then
    
        self.sliding = true
        self.startedSliding = true
        
        if Server then
            if not GetHasSilenceUpgrade(self) then
                self.slideLoopSound:Start()
            end
        end
        
        self:DeductAbilityEnergy(kBellySlideCost)
        self:PrimaryAttackEnd()
        self:SecondaryAttackEnd()
        
    end
    
    if not slidingDesired and self.sliding then
    
        self.sliding = false
        
        if Server then
            self.slideLoopSound:Stop()
        end
        
        self.timeSlideEnd = Shared.GetTime()
    
    end

    // Have Gorge lean into turns depending on input. He leans more at higher rates of speed.
    if self:GetIsBellySliding() then

        local desiredBellyYaw = 2 * (-input.move.x / kSlidingMoveInputScalar) * (self:GetVelocity():GetLength() / self:GetMaxSpeed())
        self.bellyYaw = Slerp(self.bellyYaw, desiredBellyYaw, input.time * kGorgeLeanSpeed)
        
    end
    
end

function Gorge:GetCanRepairOverride(target)
    return true
end

function Gorge:HandleButtons(input)

    PROFILE("Gorge:HandleButtons")
    
    Alien.HandleButtons(self, input)
    
    UpdateGorgeSliding(self, input)
    
end

function Gorge:OnUpdatePoseParameters(viewModel)

    PROFILE("Gorge:OnUpdatePoseParameters")
    
    Alien.OnUpdatePoseParameters(self, viewModel)
    
    self:SetPoseParam(kGorgeBellyYaw, self.bellyYaw * 45)
    
end

function Gorge:ConstrainMoveVelocity(moveVelocity)   

    Alien.ConstrainMoveVelocity(self, moveVelocity)
    
    if self:GetIsBellySliding() then
        moveVelocity:Scale(0)
    end
    
end

function Gorge:GetGroundFrictionForce()

    if self:GetIsBellySliding() then
        return ConditionalValue(self:GetGameEffectMask(kGameEffect.OnInfestation), 0.1, 0.3)
    elseif self.crouching then
        return 14
    end    

    return Alien.GetGroundFrictionForce(self)
end

function Gorge:SetCrouchState(newCrouchState)
    self.crouching = newCrouchState
end

function Gorge:GetMaxSpeed(possible)

    if possible then
        return kMaxGroundSpeed
    end
    
    return kMaxGroundSpeed * self:GetMovementSpeedModifier()
    
end

function Gorge:GetMass()
    return kMass
end

function Gorge:OnUpdateAnimationInput(modelMixin)

    PROFILE("Gorge:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsBellySliding() then
        modelMixin:SetAnimationInput("move", "belly")
    end
    
end

function Gorge:GetAirMoveScalar()
    return 0
end

Gorge.kSlideControl = 1

function Gorge:ModifyVelocity(input, velocity)

    Alien.ModifyVelocity(self, input, velocity)

    if not self:GetIsOnGround() and input.move:GetLength() ~= 0 or self:GetIsBellySliding() then
    
        local moveLengthXZ = velocity:GetLengthXZ()
        local previousY = velocity.y
        local adjustedZ = false
        local bellySliding = self:GetIsBellySliding()

        if input.move.z ~= 0 then
        
            local redirectedVelocityZ = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * input.move.z
            
            if input.move.z < 0 then
            
                redirectedVelocityZ = GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()
                
                local xzVelocity = Vector(velocity)
                xzVelocity.y = 0
                
                VectorCopy(velocity - (xzVelocity * input.time * Gorge.kAirBrakeWeight), velocity)
                
            else
            
                redirectedVelocityZ = redirectedVelocityZ * input.time * ConditionalValue(bellySliding, Gorge.kSlideControl, Gorge.kAirZMoveWeight) + GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()
                redirectedVelocityZ:Scale(moveLengthXZ)
                redirectedVelocityZ.y = previousY
                VectorCopy(redirectedVelocityZ,  velocity)
                adjustedZ = true
            
            end
        
        end
    
        if input.move.x ~= 0  then
    
            local redirectedVelocityX = GetNormalizedVectorXZ(self:GetViewCoords().xAxis) * input.move.x
        
            if adjustedZ then
                redirectedVelocityX = redirectedVelocityX * input.time * ConditionalValue(bellySliding, Gorge.kSlideControl, Gorge.kAirStrafeWeight) + GetNormalizedVectorXZ(velocity)
            else
                redirectedVelocityX = redirectedVelocityX * input.time * ConditionalValue(bellySliding, Gorge.kSlideControl, 2) + GetNormalizedVectorXZ(velocity)
            end
            
            redirectedVelocityX:Normalize()            
            redirectedVelocityX:Scale(moveLengthXZ)
            redirectedVelocityX.y = previousY            
            VectorCopy(redirectedVelocityX,  velocity)
            
        end    
    
    end
    
    // Give a little push forward to make sliding useful
    if self.startedSliding then
    
        if self:GetIsOnGround() then
    
            local pushDirection = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)
            local force = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnInfestation), kInfestationStartSlideForce, kStartSlideForce) * self:GetSlowSpeedModifier()
            
            local impulse = pushDirection * force

            velocity.x = velocity.x * 0.5 + impulse.x
            velocity.y = velocity.y * 0.5 + impulse.y
            velocity.z = velocity.z * 0.5 + impulse.z
        
        end
        
        self.startedSliding = false

    end
    
end

function Gorge:GetPitchSmoothRate()
    return 1
end

function Gorge:GetPitchRollRate()
    return 3
end

local kMaxSlideRoll = math.rad(20)

function Gorge:GetDesiredAngles()

    local desiredAngles = Alien.GetDesiredAngles(self)
    
    if self:GetIsBellySliding() then
        desiredAngles.pitch = - self.verticalVelocity / 10 
        desiredAngles.roll = GetNormalizedVectorXZ(self:GetVelocity()):DotProduct(self:GetViewCoords().xAxis) * kMaxSlideRoll
    end
    
    return desiredAngles

end

function Gorge:PreUpdateMove(input, runningPrediction)

    self.prevY = self:GetOrigin().y

end

function Gorge:PostUpdateMove(input, runningPrediction)

    if self:GetIsBellySliding() and self:GetIsOnGround() then
    
        local velocity = self:GetVelocity()
    
        local yTravel = self:GetOrigin().y - self.prevY
        local xzSpeed = velocity:GetLengthXZ()
        
        xzSpeed = xzSpeed + yTravel * -4
        
        if xzSpeed < kMaxSlidingSpeed or yTravel > 0 then
        
            local directionXZ = GetNormalizedVectorXZ(velocity)
            directionXZ:Scale(xzSpeed)

            velocity.x = directionXZ.x
            velocity.z = directionXZ.z
            
            self:SetVelocity(velocity)
            
        end

        self.verticalVelocity = yTravel / input.time
    
    end

end

if Client then

    function Gorge:GetShowGhostModel()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetShowGhostModel()
        end
        
        return false
        
    end    

    function Gorge:GetGhostModelTechId()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelTechId()
        end
        
    end

    function Gorge:GetGhostModelCoords()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelCoords()
        end

    end
    
    function Gorge:GetLastClickedPosition()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon.lastClickedPosition
        end
        
    end

    function Gorge:GetIsPlacementValid()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetIsPlacementValid()
        end
    
    end

end

function Gorge:GetCanAttack()
    return Alien.GetCanAttack(self) and not self:GetIsBellySliding()
end

function Gorge:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.28, 0)
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars)
