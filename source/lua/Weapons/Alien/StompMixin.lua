// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StompMixin.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Shockwave.lua")

StompMixin = CreateMixin( StompMixin  )
StompMixin.type = "Stomp"

local kMaxPlayerVelocityToStomp = 6
local kDisruptRange = kStompRange
local kStompVerticalRange = 1.5

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
StompMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "PerformSecondaryAttack"
}

StompMixin.networkVars = 
{
    stomping = "boolean"
}

function StompMixin:GetIsStomping()
    return self.stomping
end

function StompMixin:GetHasSecondary(player)
    return player:GetHasThreeHives()
end

function StompMixin:GetSecondaryEnergyCost(player)
    return kStompEnergyCost
end

function StompMixin:PerformStomp(player)

    if Server then

        local xZDirection = player:GetViewCoords().zAxis
        xZDirection.y = 0
        xZDirection:Normalize()
        local origin = player:GetOrigin() + Vector(0, 0.4, 0) + player:GetViewCoords().zAxis * 0.9
        
        local shockWave = CreateEntity(Shockwave.kMapName, origin, player:GetTeamNumber())
        local velocity = GetNormalizedVectorXZ(player:GetViewCoords().zAxis) * kShockwaveSpeed
        shockWave:Setup(player, velocity, false, nil, player)
        
    end
    
end

function StompMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= kStompEnergyCost and player:GetIsOnGround() then
        self.stomping = true
        Ability.OnSecondaryAttack(self, player)
    end

end

function StompMixin:OnSecondaryAttackEnd(player)
    
    Ability.OnSecondaryAttackEnd(self, player)    
    self.stomping = false
    
end

function StompMixin:OnTag(tagName)

    PROFILE("StompMixin:OnTag")

    if tagName == "stomp_hit" then
        
        local player = self:GetParent()
        
        if player then
                
            self:PerformStomp(player)

            self:TriggerEffects("stomp_attack", { effecthostcoords = player:GetCoords() })
            player:DeductAbilityEnergy(kStompEnergyCost)
            
        end
        
        if player:GetEnergy() < kStompEnergyCost then
            self.stomping = false
        end    
        
    end

end

function StompMixin:OnUpdateAnimationInput(modelMixin)

    if self.stomping then
        modelMixin:SetAnimationInput("activity", "secondary") 
    end
    
end