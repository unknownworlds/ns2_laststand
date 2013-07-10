//=============================================================================
//
// lua\AiSlapAttackType.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)
//
// A slap attack as used by the aiEntity
//
//=============================================================================

Script.Load("lua/AiAttackType.lua")

class "AiSlapAttackType" (AiAttackType)

function AiSlapAttackType:Init(aiEntity)

    local range = LookupTechData(kTechId.Whip, kVisualRange)
    local types = { kAlienStaticTargets, kAlienMobileTargets }
    
    local selector = TargetSelector():Init( aiEntity, range, true, types)   
    local energyCost = 0 // slaps don't cost energy?
    
    AiAttackType.Init(self, aiEntity, energyCost, selector)
    self.slapping = true
    
    return self
    
end

// work-around
function AiSlapAttackType:GetClassName()
    return "AiSlapAttackType"
end

// find the place where we hit the target.
function AiSlapAttackType:CalcHitPosDir(targetPoint)

    local attackOrigin = self.aiEntity:GetEyePos()
    local toTarget = targetPoint - attackOrigin
    toTarget:Normalize()
    
    // fudge a bit - put the point of attack 0.5m short of the target
    local attackPoint = targetPoint - toTarget * 0.5
    
    return attackPoint, toTarget
    
end


function AiSlapAttackType:OnHit()

    local target = self:GetTarget()
    local targetPoint = self:GetTargetPoint()
    
    // where we hit on the main target and the direction we hit it from
    local hitPosition,hitDirection = self:CalcHitPosDir(targetPoint) 
    
    // If we havea target, hit it  
    if target then
        self.aiEntity:DoDamage(Whip.kDamage, target, hitPosition, hitDirection, nil, true)
        didDamage = true
    end
    
    if didDamage then
        self.aiEntity:TriggerEffects("whip_attack")
    end
    
end

function AiSlapAttackType:OnStart()
end