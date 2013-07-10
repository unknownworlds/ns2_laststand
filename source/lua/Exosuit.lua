// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Exosuit.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com.at)
//
//    Pickupable entity.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LiveMixin.lua")

class 'Exosuit' (ScriptActor)

Exosuit.kMapName = "exosuit"

Exosuit.kModelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_spawn_only.animation_graph")

Exosuit.kThinkInterval = .5

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)

function Exosuit:OnCreate ()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, LiveMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
    // LS - so unoccupied suits can be damaged
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)

    local h = 400
    self.maxHealth = h
    self:SetHealth(h)

end
/*
function Exosuit:GetCheckForRecipient()
    return false
end    
*/
function Exosuit:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Exosuit.kModelName, kAnimationGraph)
    
end

function Exosuit:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:GetIsValidRecipient(player)      
end

function Exosuit:_GetNearbyRecipient()
end

function Exosuit:OnTouch(recipient)    
end

if Server then

    function Exosuit:OnKill(attacker, doer, point, direction)
    
        self:TriggerEffects("death", { classname = "Exo", effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })
        DestroyEntity(self)
        
    end
    

    function Exosuit:GetSuitTypeTechId()
        // subclasses should override this
        return kTechId.Exosuit
    end

    function Exosuit:OnUse(player, elapsedTime, useSuccessTable)
    
        if self:GetIsValidRecipient(player) then
        
            local techId = self:GetSuitTypeTechId()

            if techId == kTechId.Exosuit then
                player:GiveExo(self:GetOrigin(), "ClawMinigun", self:GetHealth())
            elseif techId == kTechId.DualMinigunExosuit then
                player:GiveExo(self:GetOrigin(), "MinigunMinigun", self:GetHealth())
            elseif techId == kTechId.ClawRailgunExosuit then
                player:GiveExo(self:GetOrigin(), "ClawRailgun", self:GetHealth())
            elseif techId == kTechId.DualRailgunExosuit then
                player:GiveExo(self:GetOrigin(), "RailgunRailgun", self:GetHealth())
            end
            
            DestroyEntity(self)

        end
        
    end
    
end

// only give Exosuits to standard marines
function Exosuit:GetIsValidRecipient(recipient)
    return not recipient:isa("Exo")
end

function Exosuit:GetIsPermanent()
    return true
end  

Shared.LinkClassToMap("Exosuit", Exosuit.kMapName, networkVars)

//----------------------------------------
//  LS Overrides
//----------------------------------------
class 'DualRailgunExosuit' (Exosuit)
DualRailgunExosuit.kMapName = "dual_railgun_exosuit"
Shared.LinkClassToMap("DualRailgunExosuit", DualRailgunExosuit.kMapName, {})
function DualRailgunExosuit:GetSuitTypeTechId()
    return kTechId.DualRailgunExosuit
end

class 'ClawRailgunExosuit' (Exosuit)
ClawRailgunExosuit.kMapName = "claw_railgun_exosuit"
Shared.LinkClassToMap("ClawRailgunExosuit", ClawRailgunExosuit.kMapName, {})
function ClawRailgunExosuit:GetSuitTypeTechId()
    return kTechId.ClawRailgunExosuit
end

class 'DualMinigunExosuit' (Exosuit)
DualMinigunExosuit.kMapName = "dual_minigun_exosuit"
Shared.LinkClassToMap("DualMinigunExosuit", DualMinigunExosuit.kMapName, {})
function DualMinigunExosuit:GetSuitTypeTechId()
    return kTechId.DualMinigunExosuit
end

