//=============================================================================
//
// lua\AiAttackType.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// This defines the basic working of all AI attack types
//
//=============================================================================

// Base class for all aiEntity attack types
class "AiAttackType"

/**
 * The basica AI attack type.
 * The aiEntity is the owning entity.
 * the animationStateName is the name of the boolean network variable for the aiEntity that 
 * must be set to true when the attack starts
 * energyCost can be set to zero if energy is not require to shoot
 * targetSelector can be set to null if AcquireTarget is overridden.
 */
function AiAttackType:Init(aiEntity, energyCost, targetSelector)

    self.aiEntity = aiEntity
    self.energyCost = energyCost
    self.nextAttackTime = Shared.GetTime()
    self.targetSelector = targetSelector
    self.targetId = Entity.invalidId
    self.targetLocation = nil
    // Default minimum time to next acquire target attempt if no target found.
    self.minScanInterval = 0.5
    self.enabled = true
    
    return self
    
end

function AiAttackType:SetIsEnabled(setEnabled)

    assert(type(setEnabled) == "boolean")
    
    self.enabled = setEnabled
    
end

function AiAttackType:GetIsEnabled()
    return self.enabled
end

/**
 * Return the current target point. Only valid if the attack is currently active. 
 */
function AiAttackType:GetTargetPoint()

    local target = self:GetTarget()
    return target and target:GetEngagementPoint() or self.targetLocation
    
end

function AiAttackType:GetTarget()
    return Shared.GetEntity(self.targetId)
end

/**
 * Must be called when the aiEntity has moved
 */
function AiAttackType:AttackerMoved()

    if self.targetSelector then
        self.targetSelector:AttackerMoved()
    end
    
end

/**
 * Triggers debug for this attack type
 */
function AiAttackType:Debug(cmd)

    Log("%s", self:GetClassName())
    
    self.targetSelector:Debug(cmd)
    
end

/**
 * Return true if we are attacking a location
 */
function AiAttackType:IsAttackingLocation() 
    return self.targetLocation ~= nil
end

/**
 * Try to attack according to the order.
 * 
 * If the order has a target, attack it, otherwise try to attack its location, if any
 */
function AiAttackType:TryAttackOnOrder(order, now)

    assert(self:GetIsEnabled())
    
    local target = Shared.GetEntity(order:GetParam())
    if target then
    
        if self:ValidateTarget(target) then
        
            self:StartAttackOnTarget(target)
            return true
            
        end
        
    end
    
    local location = order:GetLocation()
    if location then
    
        if self:ValidateLocation(location) then
        
            self:StartAttackOnLocation(location)
            return true
            
        end
        
    end
    
    return false
    
end

/**
 * True if this attack has a valid target or location
 */
function AiAttackType:IsValid()

    if self.targetLocation then
        return self:ValidateLocation(self.targetLocation)
    end
    
    return self:ValidateTarget(self:GetTarget())
    
end

/**
 * True if the location is valid
 */
function AiAttackType:ValidateLocation(location, rangeOverride)

    local range = (self.aiEntity:GetOrigin()- location):GetLength()
    return range < (rangeOverride or self.targetSelector.range)
    
end

/**
 * Return true if target is valid
 */
function AiAttackType:ValidateTarget(target)
    return self.targetSelector:ValidateTarget(target)
end

/**
 * An attack can be done if we have energy and the nextAttackTime has passed
 *
 * We first try to maintain our current target. If that's not possible, then 
 * we look for a new target.
 *
 * If we find one, we start the attack.
 */
function AiAttackType:TryAttackOnAny(now)

    assert(self:GetIsEnabled())
    
    local target = Shared.GetEntity(self.targetId)
    
    if now >= self.nextAttackTime then
    
        if not HasMixin(self.aiEntity, "Energy") or (self.aiEntity:GetEnergy() > self.energyCost) then
        
            if not self:ValidateTarget(target) then
                target = self:AcquireTarget(now)
            end
            
            if target then
            
                self:StartAttackOnTarget(target,now)
                return true
                
            end
            
        end
        
        self.nextAttackTime = now + self.minScanInterval
        
    end
    
    return false
    
end

function AiAttackType:StartAttackOnTarget(target, now)

    assert(self:GetIsEnabled())
    
    self.targetId = target:GetId()
    self.targetLocation = nil
    
    self.aiEntity:StartAiAttack(self)
    
end

function AiAttackType:StartAttackOnLocation(location, now)

    assert(self:GetIsEnabled())
    
    self.targetId = Entity.invalidId
    self.targetLocation = location
    
    self.aiEntity:StartAiAttack(self)
    
end

function AiAttackType:AcquireTarget(now)
    return self.targetSelector:AcquireTarget()
end

//
// The aiEntity animation will call us when the attack starts, hits and ends, using
// OnStart, OnHit and OnEnd respectively.
// Note that OnStart and OnHit will be called only if the attack is valid (ie, targetLocation or target is valid)
//

function AiAttackType:OnStart()
end

function AiAttackType:OnHit()
end

function AiAttackType:OnEnd()
end