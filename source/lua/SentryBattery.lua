// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\SentryBattery.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Powers up to three sentries. Required for building them.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")

class 'SentryBattery' (ScriptActor)
SentryBattery.kMapName = "sentrybattery"
SentryBattery.kRange = 4.0

SentryBattery.kModelName = PrecacheAsset("models/marine/portable_node/portable_node.model")
local kAnimationGraph = PrecacheAsset("models/marine/portable_node/portable_node.animation_graph")

local networkVars =
{
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)

AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function SentryBattery:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, PowerConsumerMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function SentryBattery:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)
    
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
    end
    
    self:SetModel(SentryBattery.kModelName, kAnimationGraph)

end

function SentryBattery:GetReceivesStructuralDamage()
    return true
end

function SentryBattery:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function SentryBattery:GetRequiresPower()
    return false
end

function GetRoomHasNoSentryBattery(techId, origin, normal, commander)

    local location = GetLocationForPoint(origin)
    local locationName = location and location:GetName() or nil
    local validRoom = false
    
    if locationName then
    
        validRoom = true
    
        for index, sentryBattery in ientitylist(Shared.GetEntitiesWithClassname("SentryBattery")) do
            
            if sentryBattery:GetLocationName() == locationName then
                validRoom = false
                break
            end
            
        end
    
    end
    
    return validRoom

end

if Server then

    function SentryBattery:OnKill()

        self:TriggerEffects("death")
        DestroyEntity(self)

    end

end

Shared.LinkClassToMap("SentryBattery", SentryBattery.kMapName, networkVars)