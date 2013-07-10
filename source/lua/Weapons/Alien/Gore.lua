// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Gore.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com) and
//                  Urwalek Andreas (andi@unknownworlds.com)
//
// Basic goring attack. Can also be used to smash down locked or welded doors.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Gore' (Ability)

Gore.kMapName = "gore"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

Gore.kAttackType = enum({ "GoreLeft", "GoreRight", "Smash", "None" })

// when hitting marine his aim is interrupted
Gore.kAimInterruptDuration = 0.7

local networkVars =
{
    attackType = "enum Gore.kAttackType",
    attackButtonPressed = "boolean"
}

AddMixinNetworkVars(StompMixin, networkVars)

local kAttackRadius = 1.5
local kAttackOriginDistance = 2
local kAttackRange = 2.2
local kGoreSmashKnockbackForce = 590 // mass of a marine: 90
local kGoreSmashMinimumUpwardsVelocity = 9

// return false for left, true for right
local function GetAttackDirection(player, attackOrigin, engagementPoint)

    local directionToTarget = engagementPoint - attackOrigin
    if directionToTarget:DotProduct(player:GetViewCoords().xAxis) < 0 then
        return true
    end 
    return false
    
end

// checks in front of the onos in a radius for potential targets and returns the attack mode (randomized if no targets found)
local function GetAttackType(self, player)

    PROFILE("GetAttackType")

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kAttackOriginDistance, CollisionRep.Damage, PhysicsMask.Melee, EntityFilterAll())
    local attackOrigin = trace.endPoint
    
    local attackType = Gore.kAttackType.None
    
    local didHit, target, direction = CheckMeleeCapsule(self, player, 0, kAttackRange)
    
    if didHit then
    
        if target and HasMixin(target, "Live") then
        
            if ( target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage() or target:isa("Exo") ) and GetAreEnemies(player, target) then
                attackType = Gore.kAttackType.Smash         
            elseif GetAttackDirection(player, attackOrigin, target:GetEngagementPoint()) then
                attackType = Gore.kAttackType.GoreRight
            else
                attackType = Gore.kAttackType.GoreLeft
            end
            
        end
    
    end
    
    // randomize the attack if we hit nothing
    if attackType == Gore.kAttackType.None then
        local randomVar = math.random()
        if randomVar < 0.5 then
            attackType = Gore.kAttackType.GoreLeft
        else
            attackType = Gore.kAttackType.GoreRight
        end
    
    end
    
    if Server then
        self.lastAttackType = attackType
    end
    
    return attackType

end

local function GoreAttack(self, player, hitTarget, excludeTarget)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kAttackOriginDistance, CollisionRep.Damage, PhysicsMask.Melee, EntityFilterAll())
    local attackOrigin = trace.endPoint
    local didHit = false
    
    local targets = GetEntitiesWithMixinForTeamWithinRange ("Live", GetEnemyTeamNumber(player:GetTeamNumber()), attackOrigin, kAttackRadius)
    
    if hitTarget and HasMixin(hitTarget, "Live") then
        table.insertunique(targets, hitTarget)
    end
    
    if excludeTarget then
        table.removevalue(targets, excludeTarget)
    end
    
    local tableparams = {}
    tableparams[kEffectFilterSilenceUpgrade] = GetHasSilenceUpgrade(player)
    
    for index, target in ipairs(targets) do
        
        self:DoDamage(kGoreDamage, target, target:GetEngagementPoint(), direction)
        didHit = true
    
    end
    
    // since gore is aoe we need to manually trigger possibly hit effects
    if not didHit and trace.fraction ~= 1 then
        TriggerHitEffects(self, nil, trace.endPoint, trace.surface, tableparams)
    end
    
    return didHit, attackOrigin
    
end

local function GetEnergyCostForAttackType(attackType)

    return kGoreEnergyCost

end

// required here to deals different damage depending on if we are smashing or goring
function Gore:GetDamageType()

    if self:GetAttackType() == Gore.kAttackType.Smash then
        return kSmashDamageType
    else
        return kGoreDamageType
    end
    
end    

function Gore:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
    
    self.attackType = Gore.kAttackType.None
    if Server then
        self.lastAttackType = Gore.kAttackType.None
    end
    
end

function Gore:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
end

function Gore:GetSecondaryTechId()
    return kTechId.Stomp
end

function Gore:GetAnimationGraphName()
    return kAnimationGraph
end

function Gore:GetEnergyCost(player)
    return GetEnergyCostForAttackType(self.attackType)
end

function Gore:GetHUDSlot()
    return 1
end

function Gore:GetAttackType()
    return self.attackType
end

function Gore:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:OnAttackEnd()
    
end

function Gore:GetMeleeBase()
    return 1, 1.4
end

function Gore:Attack(player)

    local didHit = false
    local impactPoint = nil
    local target = nil
    local attackType = self.attackType
    
    if Server then
        attackType = self.lastAttackType
    end    
    
    local filter = EntityFilterOneAndIsa(player, "Babbler")
    
    if attackType == Gore.kAttackType.Smash then
        didHit, target, impactPoint = AttackMeleeCapsule(self, player, kSmashDamage, kAttackRange, nil, false, filter)
    else
    
        didHit, target, impactPoint = AttackMeleeCapsule(self, player, 0, kAttackRange, nil, false, filter)
        if didHit then
            didHit, impactPoint = GoreAttack(self, player, target)
        end
        
    end
    
    player:DeductAbilityEnergy(GetEnergyCostForAttackType(attackType))
    
    return didHit, impactPoint, target
    
end

function Gore:OnTag(tagName)

    PROFILE("Gore:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        local didHit, impactPoint, target = self:Attack(player)
        
        // play sound effects
        self:TriggerEffects("gore_attack")
        
        // play particle effects for smash
        if didHit and self:GetAttackType() == Gore.kAttackType.Smash and ( not target or (target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage()) ) then
        
            local effectCoords = player:GetViewCoords()
            effectCoords.origin = impactPoint
            self:TriggerEffects("smash_attack_hit", {effecthostcoords = effectCoords} )
            
        end
        
        if self.attackButtonPressed then
            self.attackType = GetAttackType(self, player)
        else
            self:OnAttackEnd()
        end
        
        if player:GetEnergy() >= GetEnergyCostForAttackType(self.attackType) or not self.attackButtonPressed then
            self:OnAttackEnd()
        end
        
    elseif tagName == "end" and not self.attackButtonPressed then
        self:OnAttackEnd()
    end    

end

function Gore:OnPrimaryAttack(player)

    local nextAttackType = self.attackType
    if nextAttackType == Gore.kAttackType.None then
        nextAttackType = GetAttackType(self, player)
    end

    if player:GetEnergy() >= GetEnergyCostForAttackType(nextAttackType) then
        self.attackType = nextAttackType
        self.attackButtonPressed = true
    else
        self:OnAttackEnd()
    end 

end

function Gore:OnPrimaryAttackEnd(player)
    
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
    
end

function Gore:OnAttackEnd()
    self.attackType = Gore.kAttackType.None
    self.attackButtonPressed = false
end

function Gore:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "gore"
    
    if self.attackButtonPressed then
    
        if self.attackType == Gore.kAttackType.GoreLeft or self.attackType == Gore.kAttackType.GoreRight then
            activityString = "primary"
        elseif self.attackType == Gore.kAttackType.Smash then
            activityString = "smash"
        end
        
    end
    
    modelMixin:SetAnimationInput("ability", abilityString)
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Gore", Gore.kMapName, networkVars)