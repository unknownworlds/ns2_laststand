// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\TargettingMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Manages a list of entities in a trigger, sorts them (pass optional sort function) and
//    some other common settings relevant for targetting:
//
//    SwitchTarget: Always switch to better target, even when already having one.
//    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TargettingMixin = { }
TargettingMixin.type = "Targetting"

local kTriggerRangeOffset = 3

TargettingMixin.expectedMixins =
{
    Trigger = "To track targets in range.",
    EntityChange = "To update trigger list."
}

// would make sense to implement OnUpdateAttack, optionally you can poll the current target (not recommended)
TargettingMixin.optionalCallbacks =
{
    OnUpdateAttack = "Target is passed in that function, called once per frame (deal with timings here).",
    OnTargetChanged = "Called whenever target changes."
}

TargettingMixin.expectedConstants =
{
    kFov = "Required to know fov.",
    kAttackRange = "Required to know attack range.",
}

TargettingMixin.optionalConstants =
{
    kSwitchTargets = "Pass true when switching targets is allowed.",
    kIgnoreWalls = "Set to true to validate targets through walls"
}

function TargettingMixin:__initmixin()

    // Make trigger range bigger to ensure we fire in the moment something is in attack range.
    self:SetSphere(self:GetMixinConstants().kAttackRange + kTriggerRangeOffset)
    self.currentTargetId = Entity.invalidId
    self.findBestTargetTime = 0
    
end

local function ValidateTarget(self, target)

    PROFILE("TargettingMixin:ValidateTarget")
    
    if not target then
        return false
    end
    
    // 'cheap' checks at first: target has to be enemy, target needs to be alive
    if GetAreEnemies(self, target) and HasMixin(target, "Live") and target:GetIsAlive() and target:GetCanTakeDamage() then
    
        local targetOrigin = (HasMixin(target, "Target") and target:GetEngagementPoint()) or target:GetOrigin()
        local eyePos = GetEntityEyePos(self)
        local fov = self:GetMixinConstants().kFov
        
        //Print("check target %s", ToString(target))
        
        // check if target is in range
        if (eyePos - targetOrigin):GetLength() < self:GetMixinConstants().kAttackRange then
        
            local toTarget = eyePos - targetOrigin
            toTarget:Normalize()
            
            //Print("target %s is in range", ToString(target))
            
            local dotProduct = self:GetCoords().zAxis:DotProduct(toTarget)
            
            // target is enemy, alive, in range and in fov
            if fov == 360 or math.acos(dotProduct) >= math.rad(self:GetMixinConstants().kFov / 2) then
            
                //Print("target %s is in fov", ToString(target))
            
                //check if we can see the entity unless we are an ARC or another unit which can shoot trough walls
                if self:GetMixinConstants().kIgnoreWalls then
                    return true
                else
                
                    // check for geometry or entities blocking
                    local trace = Shared.TraceRay(eyePos, targetOrigin, CollisionRep.Damage, PhysicsMask.All, EntityFilterOne(seeingEntity))
                    if trace.entity == target then
                        //Print("no obstacles to %s", ToString(target))
                        return true
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return false
    
end

local kRangePriority = 1
local kAttackTimePriority = 0.1

local function FindBestTarget(self)

    PROFILE("TargettingMixin:FindBestTarget")
    
    local targets = self:GetEntitiesInTrigger()
    local attacker = self
    
    local function SortTargets(target1, target2)
        
        local priority1 = 0
        local priority2 = 0
        
        if (target1:GetOrigin() - attacker:GetOrigin()):GetLengthSquared() <= (target2:GetOrigin() - attacker:GetOrigin()):GetLengthSquared() then
            priority1 = priority1 + kRangePriority
        else
            priority2 = priority2 + kRangePriority
        end
        
        if HasMixin(target1, "Combat") and HasMixin(target2, "Combat") then
        
            if target1:GetTimeLastDamageDealt() >= target2:GetTimeLastDamageDealt() then
                priority1 = priority1 + kAttackTimePriority   
            else
                priority2 = priority2 + kAttackTimePriority
            end
            
        elseif HasMixin(target1, "Combat") then
            priority1 = priority1 + kAttackTimePriority
        elseif HasMixin(target2, "Combat") then
            priority2 = priority2 + kAttackTimePriority
        end
        
        local fov = attacker:GetMixinConstants().kFov
        
        if fov ~= 360 then
        
            local toEnt1 = attacker:GetOrigin() - target1:GetOrigin()
            toEnt1:Normalize()
            
            local toEnt2 = attacker:GetOrigin() - target2:GetOrigin()
            toEnt2:Normalize()
            
            local dot1 = attacker:GetCoords().zAxis:DotProduct(toEnt1)
            local dot2 = attacker:GetCoords().zAxis:DotProduct(toEnt2)
            
            priority1 = priority1 * dot1 * (360 / fov)
            priority2 = priority2 * dot2 * (360 / fov)
            
        end
        
        return priority1 < priority2
        
    end
    
    table.sort(targets, SortTargets)
    
    // Find the first valid target.
    for t = 1, #targets do

        if ValidateTarget(self, targets[t]) then
            return targets[t]:GetId()
        end
        
    end
    
    return Entity.invalidId
    
end

// only track enemies which are alive, range and fov are checked later since we use a sphere as trigger we should not filter out not inFov or not inRange
function TargettingMixin:GetTrackEntity(enterEnt)
    return GetAreEnemies(self, enterEnt) and HasMixin(enterEnt, "Live") and enterEnt:GetIsAlive()
end

// entities can change but still be valid (gestating players). continue tracking if they changed into a valid target
function TargettingMixin:OnEntityChange(oldId, newId)

    if oldId == self.currentTargetId then
    
        if newId and newId ~= Entity.invalidId then
        
            local newTarget = Shared.GetEntity(newId)
            if ValidateTarget(self, newTarget) then
            
                // new entity is still valid target
                self.currentTargetId = newId
                return
                
            end
            
        end
        
        self.currentTargetId = Entity.invalidId
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    PROFILE("TargettingMixin:SharedUpdate")
    
    // Validate the current target on every tick.
    local currentTarget = Shared.GetEntity(self.currentTargetId)
    if not currentTarget or not ValidateTarget(self, currentTarget) then
        self.currentTargetId = Entity.invalidId
    end
    
    local now = Shared.GetTime()
    // Switch target if a better one exists or the previous became invalid.
    local switchTarget = self:GetMixinConstants().kSwitchTargets and now - self.findBestTargetTime > 1
    local targetInvalid = self.currentTargetId == Entity.invalidId
    if switchTarget or targetInvalid then
    
        self.findBestTargetTime = now
        
        local bestTargetId = FindBestTarget(self)
        if bestTargetId ~= self.currentTargetId then
        
            self.currentTargetId = bestTargetId
            currentTarget = Shared.GetEntity(self.currentTargetId)
            
            if self.OnTargetChanged then
                self:OnTargetChanged(currentTarget)
            end
            
        end
        
    end
    
    if self.OnUpdateAttack and self.currentTargetId ~= Entity.invalidId then
        self:OnUpdateAttack(currentTarget)
    end
    
end

function TargettingMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function TargettingMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function TargettingMixin:GetIsEnemyNearby()
    return #self:GetEntitiesInTrigger() > 0
end

function TargettingMixin:GetCurrentTarget()

    if self.currentTargetId ~= Entity.invalidId then
        return Shared.GetEntity(self.currentTargetId)
    end
    
    return nil
    
end