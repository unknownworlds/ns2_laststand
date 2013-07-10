// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPack.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    A buildable, potentially portable, marine power source.
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
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/DisruptMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerSourceMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

local kAnimationGraph = PrecacheAsset("models/marine/portable_node/portable_node.animation_graph")

class 'PowerPack' (ScriptActor)

PowerPack.kMapName = "powerpack"
PowerPack.kModelName = PrecacheAsset("models/marine/portable_node/portable_node.model")

PowerPack.kRange = 10

local networkVars = { }

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
AddMixinNetworkVars(DisruptMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(PowerSourceMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)

function PowerPack:OnCreate()

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
    InitMixin(self, DisruptMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, PowerSourceMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, UnitStatusMixin)
    InitMixin(self, VortexAbleMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function PowerPack:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(PowerPack.kModelName, kAnimationGraph)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
    
    end

end

function PowerPack:GetReceivesStructuralDamage()
    return true
end

function PowerPack:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function PowerPack:GetCanPower(consumer)

    local consumerIds = self:GetPowerConsumers()
    
    if ( #consumerIds == 0 or table.contains(consumerIds, consumer:GetId()) ) then
    
        local distance = GetPathDistance(self:GetOrigin(), consumer:GetOrigin())    
        local inRange = true
        if not distance or distance > PowerPack.kRange then
            inRange = false
        end
        
        return inRange, true
    
    end
    
    return false, false

end

function PowerPack:OnPowerConsumerChanged()
    FindNewPowerConsumers(self)
end

if Server then

    function PowerPack:OnKill()
        
        ScriptActor.OnKill(self) 
   
        if not self.consumed then
            self:TriggerEffects("death", {classname = self:GetClassName(), effecthostcoords = Coords.GetTranslation(self:GetOrigin()), doer = doerClassName})
        end
        
        DestroyEntity(self)
        
    end
    
    function PowerPack:OnVortex()
        self:SetPoweringState(false)
    end
    
    function PowerPack:OnVortexEnd()
    
        if self:GetIsBuilt() then
            self:SetPoweringState(true)
        end
        
    end

end

Shared.LinkClassToMap("PowerPack", PowerPack.kMapName, networkVars)