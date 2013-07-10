// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\AttackOrderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * AttackOrderMixin handles processing attack orders.
 */
AttackOrderMixin = CreateMixin( AttackOrderMixin )
AttackOrderMixin.type = "AttackOrder"

AttackOrderMixin.expectedMixins =
{
    Orders = "Needed for calls to GetCurrentOrder().",
    Pathing = "Needed for calls to MoveToTarget().",
    Damage = "Requires to deal damage."
}

if Server then

    AttackOrderMixin.expectedCallbacks =
    {
        GetMeleeAttackDamage = "Returns the amount of damage each melee hit does.",
        GetMeleeAttackInterval = "Returns how often this Entity melee attacks.",
        GetMeleeAttackOrigin = "Returns where the melee attack originates from.",
        TriggerEffects = "The melee_attack effect will be triggered through this callback.",
        GetOwner = "Returns the owner, if any, of this Entity."
    }

end

AttackOrderMixin.networkVars =
{
    timeOfLastAttackOrder = "float"
}

function AttackOrderMixin:__initmixin()
    self.timeOfLastAttackOrder = 0
end

if Server then

    /**
     * Returns valid taret within attack distance, if any.
     */
    local function FindTarget(self, attackDistance)

        // Find enemy in range
        local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local potentialTargets = GetEntitiesWithMixinForTeamWithinRange("Live", enemyTeamNumber, self:GetOrigin(), attackDistance)
        
        local nearestTarget = nil
        local nearestTargetDistance = 0
        
        // Get closest target
        for index, currentTarget in ipairs(potentialTargets) do
        
            if currentTarget ~= self and currentTarget ~= nil then
            
                local distance = self:GetDistance(currentTarget)
                if nearestTarget == nil or distance < nearestTargetDistance then
                
                    nearestTarget = currentTarget
                    nearestTargetDistance = distance
                    
                end    
                
            end
            
        end

        return nearestTarget    
        
    end

    local function OrderMeleeAttack(self, target)
    
        PROFILE("OrderMeleeAttack")

        local meleeAttackInterval = self:GetMeleeAttackInterval()
        
        if Shared.GetTime() > (self.timeOfLastAttackOrder + meleeAttackInterval) then
        
            self:TriggerEffects(string.format("%s_melee_attack", string.lower(self:GetClassName())))

            // Traceline from us to them
            local trace = Shared.TraceRay(self:GetMeleeAttackOrigin(), target:GetOrigin(), CollisionRep.Damage, PhysicsMask.AllButPCs, EntityFilterTwo(self, target))

            local direction = target:GetOrigin() - self:GetOrigin()
            direction:Normalize()
            
            // Use player or owner (in the case of MACs, Drifters, etc.)
            local attacker = self:GetOwner()
            if self:isa("Player") then
                attacker = self
            end
            
            if HasMixin(self, "Cloakable") then
                self:TriggerUncloak()
            end
            
            self:DoDamage(self:GetMeleeAttackDamage(), target, trace.endPoint, direction, trace.surface)

            self.timeOfLastAttackOrder = Shared.GetTime()
            
        end

    end

    // This is an "attack-move" from RTS. Attack the entity specified in our current attack order, if any. 
    // Otherwise, move to the location specified in the attack order and attack anything along the way.
    function AttackOrderMixin:ProcessAttackOrder(targetSearchDistance, moveSpeed, time)

        // If we have a target, attack it.
        local currentOrder = self:GetCurrentOrder()
        if currentOrder ~= nil then
        
            local target = Shared.GetEntity(currentOrder:GetParam())
            
            // Different targets can be attacked from different ranges, depending on size
            local attackDistance = GetEngagementDistance(currentOrder:GetParam())
            
            // If we are close enough to target, attack it    
            local targetPosition = target and Vector(target:GetOrigin()) or Vector()
            if self.GetHoverHeight then
                targetPosition.y = targetPosition.y + self:GetHoverHeight()
            end
            local distanceToTarget = (targetPosition - self:GetOrigin()):GetLength()
            // Factor in the size of the target.
            local sizeOfTarget = (target and HasMixin(target, "Extents")) and target:GetExtents() or Vector()
            sizeOfTarget.y = 0
            distanceToTarget = distanceToTarget - sizeOfTarget:GetLength()
            local withinAttackDistance = distanceToTarget <= attackDistance
            
            if target then
            
                // How do you kill that which has no life?
                if not HasMixin(target, "Live") or not target:GetIsAlive() then
                    self:CompletedCurrentOrder()
                // If the target is not sighted, it cannot be killed.
                elseif HasMixin(target, "LOS") and not target:GetIsSighted() then
                    self:CompletedCurrentOrder()
                elseif not withinAttackDistance then
                
                    local targetLocation = target:GetEngagementPoint()
                    if self:GetIsFlying() then
                        targetLocation = GetHoverAt(self, targetLocation)
                    end
                    
                    self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time)
                    
                end
                
            else
            
                // Check for a nearby target. If not found, move towards destination.
                target = FindTarget(self, targetSearchDistance)
                
            end
            
            if target and HasMixin(target, "Live") then
            
                if withinAttackDistance and target:GetIsAlive() then
                    OrderMeleeAttack(self, target)
                end
                
            else
            
                // otherwise move towards attack location and end order when we get there
                local targetLocation = currentOrder:GetLocation()
                if self:GetIsFlying() then
                    targetLocation = GetHoverAt(self, targetLocation)
                end
                                
                if self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time) then
                    self:CompletedCurrentOrder()
                end
     
            end
            
        end
        
    end
    AddFunctionContract(AttackOrderMixin.ProcessAttackOrder, { Arguments = { "Entity", "number", "number", "number" }, Returns = { } })

end

function AttackOrderMixin:GetTimeOfLastAttackOrder()
    return self.timeOfLastAttackOrder
end
AddFunctionContract(AttackOrderMixin.GetTimeOfLastAttackOrder, { Arguments = { "Entity" }, Returns = { "number" } })