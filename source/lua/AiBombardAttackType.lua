//=============================================================================
//
// lua\AiAiBombardAttackType.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// A bombard attack as used by the Whip
//
//=============================================================================

Script.Load("lua/AiAttackType.lua")
Script.Load("lua/Ballistics.lua")

class "AiBombardAttackType" (AiAttackType)

// if we don't hit this close to our intended target, we try to adjust our targeting
local kTriggerBombardClimbRange = 1.5
local kBombardSameTargetRange = 2
local kBombardClimbAmount = 1

function AiBombardAttackType:Init(aiEntity)

    local range = Whip.kBombardRange
    local types = { kAlienMobileTargets, kAlienStaticTargets }
    local selector = TargetSelector():Init( aiEntity, range, true, types, { })   
    local energyCost = LookupTechData(kTechId.Whip, kTechDataCostKey)
    
    AiAttackType.Init(self, aiEntity, energyCost, selector)
    
    self.bombarding = true
    
    return self
    
end

// work-around
function AiBombardAttackType:GetClassName()
    return "AiBombardAttackType"
end

function AiBombardAttackType:OnStart()
    self.aiEntity:TriggerEffects("whip_bombard")
end

function AiBombardAttackType:TryAttackOnAny(now)

    self.ordered = false
    return AiAttackType.TryAttackOnAny(self, now)
    
end

function AiBombardAttackType:TryAttackOnOrder(order,now)

    self.ordered = true
    local result = AiAttackType.TryAttackOnOrder(self, order, now)
    
    if not result then
        self.ordered = false
    end
    
    return result
    
end


function AiBombardAttackType:ValidateTarget(target)

    if target then
    
        local range = (target:GetOrigin() - self.aiEntity:GetOrigin()):GetLength()
        if self.ordered and target then
        
            // Keep target as long as it is inside range
            return range < self.targetSelector.range
            
        end
        
        // As we can lob on the target, we keep shooting as long as its inside range and detected
        // should probably stop and detarget after a few balls if we don't do any damage?
        if target and target:GetIsSighted() then
            return range < self.targetSelector.range
        end
        
    end
    
    return AiAttackType.ValidateTarget(self, target)
    
end

function AiBombardAttackType:OnHit()

    local targetPos = self:GetTargetPoint()
    
    local bombStart = self.aiEntity:GetAttachPointOrigin("Whip_Ball")
    // figure out if we should change our aim because something is blocking us
    local blockPos = nil
    
    if self.bombardBlockPosition then
    
        if (targetPos - self.bombardBlockTargetPosition):GetLength() < kBombardSameTargetRange then
            blockPos = self.bombardBlockPosition
        else
        
            self.bombardBlockPosition = nil
            self.bombardBlockTargetPosition = nil
            
        end
        
    end
    
    local direction, speed = Ballistics.GetBlockAvoidanceDirectionSpeed(bombStart, targetPos, Whip.kBombSpeed, blockPos)
    if direction then
        self:FlingBomb(bombStart, targetPos, direction, speed)
    end
    
end

function AiBombardAttackType:FlingBomb(bombStart, targetPos, direction, speed)

    local bomb = CreateEntity(WhipBomb.kMapName, bombStart, self.aiEntity:GetTeamNumber())
    
    // For callback purposes so we can adjust our aim
    bomb.intendedTargetPosition = targetPos
    bomb.shooter = self
    
    SetAnglesFromVector(bomb, direction)

    local startVelocity = direction * speed
    bomb:Setup( self.aiEntity:GetOwner(), startVelocity, true, nil, self.aiEntity)
    
    bomb:SetLifetime(self:CalcLifetime(bombStart, targetPos, startVelocity))
    
end

function AiBombardAttackType:CalcLifetime(bombStart, targetPos, startVelocity)

    local xzRange = (targetPos - bombStart):GetLengthXZ()
    local xzVelocity = Vector(startVelocity)
    xzVelocity.y = 0
    xzVelocity:Normalize()
    xzVelocity = xzVelocity:DotProduct(startVelocity)
    
    // Randomize the lifetime a little to make it look cooler. Also add a little bit of time to allow it to drop to the ground
    local lifetime = xzRange / xzVelocity + math.random() * 0.2 
    
    return lifetime
    
end

function AiBombardAttackType:OnBombDetonation(bomb)

    local eyePos = self.aiEntity:GetEyePos()
    
    local r1 = (bomb:GetOrigin() - eyePos):GetLength()
    local r2 = (bomb.intendedTargetPosition - eyePos):GetLength()
    if (r2 - r1) > kTriggerBombardClimbRange then
    
        // We were blocked by something ahead of the target. Try to climb over it
        self.bombardBlockPosition = bomb:GetOrigin()
        self.bombardBlockPosition.y = self.bombardBlockPosition.y + kBombardClimbAmount
        self.bombardBlockTargetPosition = bomb.intendedTargetPosition
        
    end
    
end