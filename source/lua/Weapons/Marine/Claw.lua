// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\Claw.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponSlotMixin.lua")
Script.Load("lua/TechMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'Claw' (Entity)

Claw.kMapName = "claw"

local networkVars =
{
    clawAttacking = "private boolean"
}

local kClawRange = 2.2

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ExoWeaponSlotMixin, networkVars)

function Claw:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, TechMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, ExoWeaponSlotMixin)
    
    self.clawAttacking = false
    
end

function Claw:GetMeleeBase()
    return 1, 0.8
end

function Claw:GetMeleeOffset()
    return 0.0
end

function Claw:OnPrimaryAttack(player)
    self.clawAttacking = true
end

function Claw:OnPrimaryAttackEnd(player)
    self.clawAttacking = false
end

function Claw:GetDeathIconIndex()
    return kDeathMessageIcon.Claw
end

function Claw:ProcessMoveOnWeapon(player, input)
end

function Claw:GetWeight()
    return kClawWeight
end

function Claw:OnTag(tagName)

    PROFILE("Claw:OnTag")

    local player = self:GetParent()
    if player then
    
        if tagName == "hit" then
            AttackMeleeCapsule(self, player, kClawDamage, kClawRange)
        elseif tagName == "claw_attack_start" then
            player:TriggerEffects("claw_attack")
        end
        
    end
    
end

function Claw:OnUpdateAnimationInput(modelMixin)
    modelMixin:SetAnimationInput("activity_" .. self:GetExoWeaponSlotName(), self.clawAttacking)
end

Shared.LinkClassToMap("Claw", Claw.kMapName, networkVars)