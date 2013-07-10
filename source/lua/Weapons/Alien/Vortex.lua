// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Vortex.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)  
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Blink.lua")
Script.Load("lua/Weapons/Alien/EtherealGate.lua")
Script.Load("lua/EntityChangeMixin.lua")

class 'Vortex' (Blink)

Vortex.kMapName = "vortex"

local networkVars =
{
    primaryBlocked = "boolean"
}

// Balance
Vortex.kDamage = 0
Vortex.kPrimaryEnergyCost = kVortexEnergyCost
local kRange = 5
Vortex.kStabDuration = 1

kVortexDuration = 4

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/vortex.surface_shader")

function Vortex:OnCreate()

    Blink.OnCreate(self)
    
    self.primaryBlocked = false
    self.primaryAttacking = false
    
    if Server then
    
        self.vortexTargetId = Entity.invalidId
        InitMixin(self, EntityChangeMixin)
        
    end

end

function Vortex:OnEntityChange(oldId, newId)

    if oldId == self.vortexTargetId then
        self.vortexTargetId = Entity.invalidId
    end
    
end

function Vortex:FreeOldTarget()

    if self.vortexTargetId ~= Entity.invalidId then
    
        local oldTarget = Shared.GetEntity(self.vortexTargetId)
        if oldTarget and HasMixin(oldTarget, "VortexAble") then
            oldTarget:FreeVortexed()
        end
        
        self.vortexTargetId = Entity.invalidId
        
    end

end

function Vortex:GetAnimationGraphName()
    return kAnimationGraph
end

function Vortex:GetEnergyCost(player)
    return Vortex.kPrimaryEnergyCost
end

function Vortex:GetPrimaryEnergyCost(player)
    return Vortex.kPrimaryEnergyCost
end

function Vortex:GetHUDSlot()
    return 2
end

function Vortex:GetDeathIconIndex()
    return kDeathMessageIcon.Swipe
end

function Vortex:GetSecondaryTechId()
    return kTechId.Blink
end

function Vortex:GetBlinkAllowed()
    return not self.primaryBlocked
end

// prevent jumping during stab to prevent exploiting
function Vortex:GetCanJump()
    return not self.primaryBlocked
end

function Vortex:GetCanShadowStep()
    return not self.primaryBlocked
end

function Vortex:OnProcessMove(input)

    Blink.OnProcessMove(self, input)
    
    // We need to clear this out in OnProcessMove (rather than ProcessMoveOnWeapon)
    // since this will get called after the view model has been updated from
    // Player:OnProcessMove. 
    self.primaryAttacking = false

end

function Vortex:OnPrimaryAttack(player)

    if not self:GetIsBlinking() and player:GetEnergy() >= self:GetPrimaryEnergyCost() then
    
        self.primaryAttacking = true
        self.primaryBlocked = true
        
    end
    
end

function Vortex:OnHolster(player)

    Blink.OnHolster(self, player)
    
    self.primaryAttacking = false
    self.primaryBlocked = false
    
end

local function PerformVortex(self)

    local player = self:GetParent()
    if player and Server then
        
        local vortexAbles = GetEntitiesWithMixinForTeamWithinRange("VortexAble", GetEnemyTeamNumber(player:GetTeamNumber()), player:GetEyePos(), kRange)
        Shared.SortEntitiesByDistance(player:GetEyePos(), vortexAbles)
        
        for _, vortexAble in ipairs(vortexAbles) do
        
            if not vortexAble:GetIsVortexed() and (not HasMixin(vortexAble, "NanoShieldAble") or not vortexAble:GetIsNanoShielded()) then   
 
                self:FreeOldTarget()
                vortexAble:SetVortexDuration(kVortexDuration)
                self.vortexTargetId = vortexAble:GetId()
                break
                
            end    
        
        end
        
    end
    
end

function Vortex:OnTag(tagName)

    PROFILE("Vortex:OnTag")

    if self.primaryBlocked then
    
        if tagName == "start" then
        
            local player = self:GetParent()
            if player then
                player:DeductAbilityEnergy(self:GetPrimaryEnergyCost())
            end
            
            self:TriggerEffects("stab_attack")
            
        elseif tagName == "attack_end" then
            self.primaryBlocked = false
        end
        
    end
    
    if Server and tagName == "hit" then
        PerformVortex(self)
    end
    
end

function Vortex:OnUpdateAnimationInput(modelMixin)

    PROFILE("Vortex:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "vortex")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Vortex", Vortex.kMapName, networkVars)