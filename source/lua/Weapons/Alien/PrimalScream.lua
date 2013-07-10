// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\PrimalScream.lua
//
//    Created by:   Andreas Urwale (andi@unknownworlds.com)
//
//    Primal Scream buffs friendly players
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'PrimalScream' (Ability)

PrimalScream.kMapName = "primalscream"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local kPrimalScreamRange = 15
local kPrimalScreamDuration = 1.5

PrimalScream.networkVars =
{
    attackButtonPressed = "boolean",
}

PrepareClassForMixin(Smash, StompMixin)

local kPrimalScreamRange = 20   

function PrimalScream:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
    
    self.attackButtonPressed = false
    
end

// remove? primal scream cannot damage players
function PrimalScream:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
end

function PrimalScream:GetAnimationGraphName()
    return kAnimationGraph
end

function PrimalScream:GetEnergyCost(player)
    return kPrimalScreamEnergyCost
end

function PrimalScream:GetHUDSlot()
    return 2
end

function PrimalScream:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:OnAttackEnd()
    
end

function PrimalScream:GetIconOffsetY(secondary)
    return kAbilityOffset.PrimalScream
end

local function PerformPrimalScream(self, player)
    
    if Server then
    
        Print("PerformPrimalScream")
        player:TriggerEffects("primal_scream")
        player:DeductAbilityEnergy(kPrimalScreamEnergyCost)
    
        for _, alien in ipairs( GetEntitiesForTeamWithinRange("Alien", player:GetTeamNumber(), player:GetOrigin(), kPrimalScreamRange) ) do
            
            if alien:GetIsAlive() then
                alien:SetPrimalScream(kPrimalScreamDuration)
            end
        
        end
        
    end
    
end

function PrimalScream:OnTag(tagName)

    if tagName == "stomp_hit" then
    
        local player = self:GetParent()
        
        if player then
    
            PerformPrimalScream(self, player)
        
            if player:GetEnergy() < kPrimalScreamEnergyCost then
                self.attackButtonPressed = false
            end
        
        end
        
    end    

end

function PrimalScream:OnPrimaryAttack(player)

    if player:GetEnergy() >= kPrimalScreamEnergyCost then
        self.attackButtonPressed = true
    else
        self:OnAttackEnd()
    end 

end

function PrimalScream:OnPrimaryAttackEnd(player)
    
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
    
end

function PrimalScream:OnAttackEnd()
    self.attackButtonPressed = false
end

function PrimalScream:OnUpdateAnimationInput(modelMixin)

    local abilityString = "stomp"
    local activityString = "none"
    
    if self.attackButtonPressed then
    
        activityString = "primary"
        
    end
   
    modelMixin:SetAnimationInput("ability", abilityString) 
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("PrimalScream", PrimalScream.kMapName, PrimalScream.networkVars)
