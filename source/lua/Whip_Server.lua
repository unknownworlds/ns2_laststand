// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Whip_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kUnrootSound = PrecacheAsset("sound/NS2.fev/alien/structures/whip/unroot")
local kRootedSound = PrecacheAsset("sound/NS2.fev/alien/structures/whip/root")
local kWalkingSound = PrecacheAsset("sound/NS2.fev/alien/structures/whip/walk")

Whip.kBombSpeed = 20

function Whip:UpdateOrders(deltaTime)

    if GetIsUnitActive(self) then
    
        // If we're moving
        local currentOrder = self:GetCurrentOrder()
        self.moving = false
        self.move_speed = 0
        
        if currentOrder and currentOrder:GetType() == kTechId.Move then
        
            if not self.rooted and self:GetIsUnblocked() then
            
                local moveSpeed = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnInfestation), Whip.kMoveSpeedOnInfestation, Whip.kMoveSpeed)
                local startOrigin = self:GetOrigin()
                self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), moveSpeed, deltaTime)
                self:UpdateControllerFromEntity()
                
                if self:IsTargetReached(currentOrder:GetLocation(), kAIMoveOrderCompleteDistance) then
                    self:CompletedCurrentOrder()
                else
                
                    self.moving = true
                    // Assumes parameter of 1 is a move speed of 10 meters/sec
                    self.move_speed = moveSpeed / Whip.kMaxMoveSpeedParam
                    
                end
                
            end
            
        end
        
        // Attack on our own
        if self.rooted then
            self:UpdateAiAttacks(deltaTime)
        end
        
        self:UpdateMovingSound(self.moving)
        
    end
    
end

function Whip:UpdateMovingSound(moving)

    if moving then
    
        if not self.movingSound then

            self.movingSound = Server.CreateEntity(SoundEffect.kMapName)
            self.movingSound:SetParent(self)
            self.movingSound:SetAsset(kWalkingSound)
            
        end
        
        if not self.movingSound:GetIsPlaying() then
            self.movingSound:Start()
        end
        
    elseif self.movingSound and self.movingSound:GetIsPlaying() then    
        self.movingSound:Stop()        
    end

end

function Whip:SetBlockTime(interval)

    assert(type(interval) == "number")
    assert(interval > 0)
    
    self.unblockTime = Shared.GetTime() + interval
    
end


function Whip:SetAttackYaw(toPoint)

    // Update our attackYaw to aim at our current target
    local attackDir = GetNormalizedVector(toPoint - self:GetModelOrigin())
    
    // This is negative because of how model is set up (spins clockwise)
    local attackYawRadians = -math.atan2(attackDir.x, attackDir.z)
    
    // Factor in the orientation of the whip.
    attackYawRadians = attackYawRadians + self:GetAngles().yaw
    
    self.attackYaw = DegreesTo360(math.deg(attackYawRadians))
    
    if self.attackYaw < 0 then
        self.attackYaw = self.attackYaw + 360
    end

end

/**
 * Called when we start an Ai attack. 
 *
 * Sets the required network variables to trigger correct animations
 */
function Whip:OnAiAttackStart(attackType)

    local target = attackType:GetTarget()
    assert(not target or HasMixin(target, "Target"))
    local point = target and target:GetEngagementPoint() or attackType.targetLocation
    self:SetAttackYaw(point)
    
    self.slapping = attackType.slapping == true
    self.bombarding = attackType.bombarding == true
    self.whacking = attackType.whacking == true
    
end

function Whip:OnAiAttackEnd(attackType)
    self:ResetAttackBits()
end

function Whip:OnAiAttackHit(attackType)

    // we reset the attack bits when we hit something to stop the attack looping.
    self:ResetAttackBits()
    
end

function Whip:OnAiAttackHitFail(attackType)

    // we reset the attack bits when we hit something to stop the attack looping.
    self:ResetAttackBits()
    
end

function Whip:ResetAttackBits()

    self.slapping = false
    self.bombarding = false
    self.whacking = false
    
end

function Whip:UpdateRootState()

    // Unroot whips if infestation recedes
    if self.rooted and not self:GetGameEffectMask(kGameEffect.OnInfestation) then
        self:Unroot()
    end
    
end

function Whip:Root()

    StartSoundEffectOnEntity(kRootedSound, self)
    
    self.rooted = true
    self:SetBlockTime(2.5)
    
    return true
    
end

function Whip:Unroot()

    StartSoundEffectOnEntity(kUnrootSound, self)
    
    self.slapping = false
    self.whacking = false
    self.bombarding = false
    
    // when we move, our static targets becomes invalid. As we can't attack until we are rooted again,
    // we don't need to do anything further
    self:AttackerMoved()
    
    self.rooted = false
    self:SetBlockTime(2.5)
    
    return true
    
end


function Whip:OnTeleportEnd()
    // invalidate static target table
    self:AttackerMoved()
end

function Whip:GetIsFuryActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastFury ~= nil) and (Shared.GetTime() < (self.timeOfLastFury + Whip.kFuryDuration))
end

/**
 * Setup the correct attacks depending on our maturity level.
 */
function Whip:UpdateAiAttacks()
    self.bombardAttack:SetIsEnabled(self:GetHasUpgrade(kTechId.WhipBombard))
end

function Whip:OnResearchComplete(researchId)

    // Transform into mature whip
    if researchId == kTechId.EvolveBombard then
    
        self:GiveUpgrade(kTechId.WhipBombard)
        self:UpdateAiAttacks()
                  
    end 
    
end

function Whip:TriggerFury()

    self:TriggerEffects("whip_trigger_fury")
    
    // Increase damage for players, whips (including self!), etc. in range
    self.timeOfLastFury = Shared.GetTime()
    
    return true
    
end

function Whip:PerformActivation(techId, position, normal, commander)

    local success = false
    local continue = false
    
    if techId == kTechId.WhipUnroot then
    
        if self.rooted then
            success = self:Unroot()
        end
        
        continue = true
        
    elseif techId == kTechId.WhipRoot then
    
        if not self.rooted and self:GetGameEffectMask(kGameEffect.OnInfestation) then
            success = self:Root()
        end
        
        continue = true
        
    end
    
    return success, continue
    
end

function Whip:PerformAction(techNode, position)

    local success = false
    
    if techNode:GetTechId() == kTechId.Cancel then
    
        self:ClearOrders()
        success = true
        
    end
    
    return success
    
end

function Whip:GetCanReposition()
    return self:GetIsBuilt() and not self.rooted
end

function Whip:OverrideRepositioningSpeed()
    return ConditionalValue(self:GetGameEffectMask(kGameEffect.OnInfestation), Whip.kMoveSpeedOnInfestation, Whip.kMoveSpeed)
end

// Required by ControllerMixin.
function Whip:GetControllerSize()
    return GetTraceCapsuleFromExtents(self:GetExtents())    
end

// Required by ControllerMixin.
function Whip:GetMovePhysicsMask()
    return PhysicsMask.Movement
end