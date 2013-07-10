// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Spur.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Alien structure that hosts Spur upgrades. 1 Spur: level 1 upgrade, 2 Spurs: level 2 etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Spur' (ScriptActor)

Spur.kMapName = "spur"

Spur.kModelName = PrecacheAsset("models/alien/spur/spur.model")

Spur.kAnimationGraph = PrecacheAsset("models/alien/spur/spur.animation_graph")

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(TeleportMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Spur:OnCreate()

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
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, ObstacleMixin)    
    InitMixin(self, FireMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, TeleportMixin)    
    InitMixin(self, UmbraMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    
    if Server then
        InitMixin(self, InfestationTrackerMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Spur:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Spur.kModelName, Spur.kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

local kSpurHealthbarOffset = Vector(0, 0.6, 0)
function Spur:GetHealthbarOffset()
    return kSpurHealthbarOffset
end

function Spur:GetMaturityRate()
    return kSpurMaturationTime
end

function Spur:GetMatureMaxHealth()
    return kMatureSpurHealth
end 

function Spur:GetMatureMaxArmor()
    return kMatureSpurArmor
end 

function Spur:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Spur:GetReceivesStructuralDamage()
    return true
end

function Spur:GetCanSleep()
    return true
end

function Spur:GetTechButtons(techId)

    if self:GetTechId() == kTechId.Spur then
        return {kTechId.UpgradeCeleritySpur, kTechId.UpgradeAdrenalineSpur } // , kTechId.UpgradeHyperMutationSpur}
    end

end

function Spur:GetIsWallWalkingAllowed()
    return false
end 

if Server then

    function Spur:OnConstructionComplete()

        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberConstructed(self)
        end
    
    end
    
    function Spur:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)
        self:TriggerEffects("death")
        DestroyEntity(self)
    
    end
    
    function Spur:OnDestroy()
        
        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberDestroyed(self)
        end
        
        ScriptActor.OnDestroy(self)
    
    end
    
    function Spur:OnResearchComplete(researchId)

        local success = false

        if researchId == kTechId.UpgradeCeleritySpur then            
            success = self:UpgradeToTechId(kTechId.CeleritySpur)
        elseif researchId == kTechId.UpgradeHyperMutationSpur then 
            success = self:UpgradeToTechId(kTechId.HyperMutationSpur)
        elseif researchId == kTechId.UpgradeAdrenalineSpur then 
            success = self:UpgradeToTechId(kTechId.AdrenalineSpur)
        end    
        
        if success then
            local team = self:GetTeam()
            if team then
                team:OnUpgradeChamberConstructed(self)
            end
        end
        
    end

end

function Spur:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Spur:OverrideHintString(hintString)

    if self:GetIsUpgrading() then
        return "COMM_SEL_UPGRADING"
    end
    
    return hintString
    
end

Shared.LinkClassToMap("Spur", Spur.kMapName, networkVars)

class 'CeleritySpur' (Spur)
CeleritySpur.kMapName = "celerityspur"
Shared.LinkClassToMap("CeleritySpur", CeleritySpur.kMapName, { })

class 'HyperMutationSpur' (Spur)
HyperMutationSpur.kMapName = "hypermutationspur"
Shared.LinkClassToMap("HyperMutationSpur", HyperMutationSpur.kMapName, { })

class 'AdrenalineSpur' (Spur)
AdrenalineSpur.kMapName = "adrenalinespur"
Shared.LinkClassToMap("AdrenalineSpur", AdrenalineSpur.kMapName, { })