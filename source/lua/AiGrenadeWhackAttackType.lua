//=============================================================================
//
// lua\AiGrenadeWhackAttackType.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// This attacks whacks away grenades headed for the whip
//
//=============================================================================

Script.Load("lua/AiAttackType.lua")

class "AiGrenadeWhackAttackType" (AiAttackType)

kGrenadeScanTime = 0.25
kAttackWindupTime = 0.6

function AiGrenadeWhackAttackType:Init(aiEntity)

    AiAttackType.Init(self, aiEntity, 0, nil)
    
    self.whacking = true
    self.minScanInterval = kGrenadeScanTime
    return self
    
end

// work-around
function AiGrenadeWhackAttackType:GetClassName()
    return "AiGrenadeWhackAttackType"
end

function AiGrenadeWhackAttackType:IsValid()
    return ( not HasMixin(self.aiEntity, "Fire") or not self.aiEntity:GetIsOnFire() ) and self:ValidateTarget(self:GetTarget())
end

function AiGrenadeWhackAttackType:ValidateTarget(target)

    if target and target:GetClassName() == "Grenade" and not target:IsWhacked() then
    
        local whacker = target:GetWhacker()
        return not whacker or whacker == self.aiEntity
        
    end
    
    return false
    
end

function AiGrenadeWhackAttackType:UpdateGrenadeScan(now)

    self.targetId, self.grenadeAttackTime = self:ScanForGrenades()
    if self.grenadeAttackTime then
        self.nextAttackTime = self.grenadeAttackTime
    end
    
end

// No ordering around grenade whacking 
function AiGrenadeWhackAttackType:TryAttackOnOrder(order, now)
    return false
end

function AiGrenadeWhackAttackType:TryAttackOnAny(now)

    if now >= self.nextAttackTime then
        self:UpdateGrenadeScan(now)
    end
    
    if not self.grenadeAttackTime then
    
        self.nextAttackTime = now + self.minScanInterval
        return false
        
    end
    
    return AiAttackType.TryAttackOnAny(self, now)  
    
end

function AiGrenadeWhackAttackType:AcquireTarget(now)

    self:UpdateGrenadeScan(now)
    return Shared.GetEntity(self.targetId)
    
end

function AiGrenadeWhackAttackType:StartAttackOnTarget(target)

    target:PrepareToBeWhackedBy(self.aiEntity)  
    
    AiAttackType.StartAttackOnTarget(self, target)
    
end

local function GetWhackDirection(whip, grenadePos, grenadeVel)

    local returnDirection = Vector(-grenadeVel)
    
    local addRandom = Vector( (math.random() - .5) * .1, 0, (math.random() - .5) * .1)

    returnDirection.y = 0
    returnDirection = returnDirection + addRandom
    returnDirection = GetNormalizedVector(returnDirection)
    returnDirection.y = 0.4
    
    return returnDirection

end

local kMinWhackSpeed = 12
local kWhackSpeed = 16

function AiGrenadeWhackAttackType:OnHit()

    local grenade = self:GetTarget()
    if grenade and grenade:isa("Grenade") and GetCanSeeEntity(self.aiEntity, grenade) then
    
        local range = (grenade:GetOrigin() - self.aiEntity:GetOrigin()):GetLength() 

        // fling it away from friendly units
        local awayFromFriendlies = GetWhackDirection(self.aiEntity, grenade:GetOrigin(), grenade:GetVelocity())
        local whackVelocity = awayFromFriendlies * grenade:GetVelocity():GetLength()
        
        if whackVelocity:GetLength() < kMinWhackSpeed then
        
            // need to fling it back with enough speed
            local player = grenade:GetOwner()
            if player then 
                whackVelocity = Ballistics.GetAimDirection(grenade:GetOrigin(), player:GetEngagementPoint(), kWhackSpeed) * kWhackSpeed
            end
            
        end
        
        grenade:Whack(whackVelocity)
        
    end
    
end

/**
 * Calculate when the grenade will arrive inside our kWhackRange, and subtract our attack wind-up time
 * Return nil if not an interesting grenade.
 *
 * This will not take into consideration any bouncing, so smart marines will be able to bounce the grenades into unsuspecting
 * aiEntitys.
 * 
 * Google line sphere intersection for algorithm 
 */
function AiGrenadeWhackAttackType:CalcWhenToWhack(grenade)

    // translate our origin to 0,0,0 and our velocity to 1 to simplify
    local origin = self.aiEntity:GetOrigin() - grenade:GetOrigin()
    local direction = grenade:GetVelocity()
    direction:Normalize()
    
    local a = direction:DotProduct(origin)
    local b = origin:GetLengthSquared()
    local c = Whip.kWhackRange * Whip.kWhackRange
    local discriminant = a*a - b + c
    
    if discriminant < 0 then 
        return nil
    end
    
    local distance = direction:DotProduct(origin) - math.sqrt(discriminant)
    local timeToIntersect = distance / grenade:GetVelocity():GetLength()
    local timeOfIntersect = Shared.GetTime() + timeToIntersect
    local timeToWhack = timeOfIntersect - kAttackWindupTime 
    return timeToWhack
    
end

/**
 * Scan for grenades around us
 */
function AiGrenadeWhackAttackType:ScanForGrenades()

    local nextAttackTime = nil
    local targetId = Entity.invalidId
    // Look for any grenades flying around in our vicinity and check when we should start whacking it
    local grenades = GetEntitiesWithinRange("Grenade", self.aiEntity:GetOrigin(), Whip.kWhackInterrestRange)
    
    for index, grenade in ipairs(grenades) do
    
        local attackTime = self:CalcWhenToWhack(grenade)
        if attackTime and (nextAttackTime == nil or attackTime < nextAttackTime) then
        
            // ignore grenades already getting whacked
            if not grenade:GetWhacker() and GetCanSeeEntity(self.aiEntity, grenade) then
                targetId, nextAttackTime = grenade:GetId(), attackTime
            end
            
        end
        
    end
    
    return targetId, nextAttackTime
    
end

function AiGrenadeWhackAttackType:OnStart()
     self.aiEntity:TriggerEffects("whip_attack")
end