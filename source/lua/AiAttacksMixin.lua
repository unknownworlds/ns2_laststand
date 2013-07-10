// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\AiAttacksMixin.lua    
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// Collects all AI-targeting code in one place. Supports commander-ordered targeting
// and multiple attack types.
// 
// The user must call AddAiAttackType() to add attacks to the list of attack types the ai can use.
//
// ==============================================================================================

AiAttacksMixin = CreateMixin( AiAttacksMixin )
AiAttacksMixin.type = "AiAttacks"

AiAttacksMixin.optionalCallbacks =
{
}

AiAttacksMixin.expectedMixins =
{
}

function AiAttacksMixin:__initmixin()

    assert(Server)
    
    self.nextAttackUpdateTime = Shared.GetTime()
    self.currentAttack = nil
    self.stickyAttackTarget = false
    self.attackTypes = { }
    
end

function AiAttacksMixin:AddAiAttackType(attackType)
    table.insert(self.attackTypes, attackType)
end

/**
 * Called when the attacker moves. Notifies all that attack types that is has
 * moved, so they can clear any target selectors. 
 */
function AiAttacksMixin:AttackerMoved()

    for _, attack in ipairs(self.attackTypes) do
    
        if attack:GetIsEnabled() then
            attack:AttackerMoved()
        end
        
    end
    
    self.currentAttack = nil
    
end

function AiAttacksMixin:StartAiAttack(attackType)

    if self.OnAiAttackStart then
        self:OnAiAttackStart(attackType)
    end
    
end

/**
 * Try to attack with all attack types in order, until one can attack. 
 */
function AiAttacksMixin:TryAttackOnAny(now)

    // so we can use math.min() inside the loop
    local nextTime = now + 10000
    local currentAttack = nil
    
    for _, attack in ipairs(self.attackTypes) do
    
        if attack:GetIsEnabled() then
        
            if attack:TryAttackOnAny(now) then
                currentAttack = attack
            end
            
            nextTime = math.min(nextTime, attack.nextAttackTime) 
            
            if currentAttack then
                break
            end
            
        end
        
    end
    
    return nextTime, currentAttack
    
end

/**
 * Try to find an attack that can fullfill the order
 */
function AiAttacksMixin:TryAttackOnOrder(order, now)

    // so we can use math.min() inside the loop
    local nextTime = now + 10000
    local currentAttack = nil
    
    for _, attack in ipairs(self.attackTypes) do
    
        if attack:GetIsEnabled() then
        
            if attack:TryAttackOnOrder(order, now) then
                currentAttack = attack
            end
            
            nextTime = math.min(nextTime, attack.nextAttackTime)
            
            if currentAttack then
                break
            end
            
        end
        
    end
    
    return nextTime, currentAttack
    
end

function AiAttacksMixin:OnOrderGiven(order)
    order.allowLocationAttack = true
end

function AiAttacksMixin:UpdateAiAttacks(deltaTime)

    local now = Shared.GetTime()
    
    // nextAttackUpdateTime is when we next can attack. This is controlled by either the animation,
    // if we are attacking, or the lowest of all the possible attacks
    if now >= self.nextAttackUpdateTime then
    
        local wasAttacking = self.currentAttack ~= nil
        
        self.currentAttack = nil
        
        if HasMixin(self, "Orders") then
        
            // first try to attack according to any order
            local order = self:GetCurrentOrder()
            
            if order then
            
                // clear any order if its on a target that is no longer sighted
                if order:GetType() == kTechId.Attack then
                
                    local target = Shared.GetEntity(order:GetParam())
                    
                    if target and HasMixin(target, "LOS") and not target:GetIsSighted() then
                        self:ClearOrders()
                    else
                    
                        // try to attack the using the given order
                        self.nextAttackUpdateTime, self.currentAttack = self:TryAttackOnOrder(order, now)
                        
                    end
                    
                else
                
                    // also clear any other orders
                    self:ClearOrders()
                    
                end
                
            end
            
        end
        
        // Search for any target to attack
        if not self.currentAttack then
            self.nextAttackUpdateTime, self.currentAttack = self:TryAttackOnAny(now)
        end    
        
        // if we attacked, we wait until the animation tells us its over or five seconds (the latter just to be safe)
        if self.currentAttack then
            self.nextAttackUpdateTime = now + 5 
        elseif wasAttacking then
        
            if self.OnAiAttackEnd then
                self:OnAiAttackEnd()
            end
            
        end
        
    end
    
end

function AiAttacksMixin:UpdateNextAiAttackTime()

    // Update nextAttackUpdateTime to the least of all the attack times.
    local time = self.nextAttackUpdateTime
    for _, attack in ipairs(self.attackTypes) do
    
        if attack:GetIsEnabled() then
            time = math.min(time, attack.nextAttackTime)
        end
        
    end
    
    self.nextAttackUpdateTime = time
    
end


function AiAttacksMixin:OnTag(tagName)

    PROFILE("AiAttacksMixin:OnTag")

    if self.currentAttack then
    
        // note that all the OnStart and OnHit is only called if the target or location is valid
        
        if tagName == "start" then
        
            if self.currentAttack:IsValid()  then
            
                // uncloak 
                if HasMixin(self, "Cloakable") then
                    self:TriggerUncloak() 
                end
                
                // pay for any energy
                if HasMixin(self, "Energy") then
                    self:SetEnergy(self:GetEnergy() - self.currentAttack.energyCost)
                end
                
                if self.OnAiAttackStart then
                    self:OnAiAttackStart(self.currentAttack)
                end
                
                self.currentAttack:OnStart()
                
            end
            
        end
        
        if tagName == "hit" then
        
            if self.currentAttack:IsValid() then
            
                if self.OnAiAttackHit then
                    self:OnAiAttackHit(self.currentAttack)
                end
                
                self.currentAttack:OnHit()
                
            else
            
                // notify that the target wasn't valid at the hit
                if self.OnAiAttackHitFail then
                    self:OnAiAttackHitFail(self.currentAttack)
                end
                
            end
            
        end
        
        if tagName == "end" then
        
            self:UpdateNextAiAttackTime()
            
            if self.OnAiAttackEnd then
                self:OnAiAttackEnd(self.currentAttack)
            end
            
            self.currentAttack:OnEnd()
            
        end
        
    end
    
end

function AiAttacksMixin:OnEntityChange(oldId, newId)

    // Check if an entity was destroyed.
    if oldId ~= nil and newId == nil then
    
        // Check if any of our attacks are targetting this entity.
        for _, attack in ipairs(self.attackTypes) do
        
            if oldId == attack.targetId then
                attack.targetId = Entity.invalidId
            end
            
        end
        
    end
    
end

function AiAttacksMixin:AiAttacksDebug(cmd)

    for _, attack in ipairs(self.attackTypes) do
        attack:Debug(cmd)
    end
    
end