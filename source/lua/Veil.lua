// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Veil.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Alien structure that hosts Veil upgrades. 1 Veil: level 1 upgrade, 2 Veils: level 2 etc.
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
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Veil' (ScriptActor)

Veil.kMapName = "veil"

Veil.kModelName = PrecacheAsset("models/alien/veil/veil.model")

Veil.kAnimationGraph = PrecacheAsset("models/alien/veil/veil.animation_graph")

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

function Veil:OnCreate()

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

function Veil:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Veil.kModelName, Veil.kAnimationGraph)
    
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

function Veil:GetReceivesStructuralDamage()
    return true
end

function Veil:GetMaturityRate()
    return kVeilMaturationTime
end

function Veil:GetMatureMaxHealth()
    return kMatureVeilHealth
end 

function Veil:GetMatureMaxArmor()
    return kMatureVeilArmor
end 

function Veil:GetIsWallWalkingAllowed()
    return false
end

function Veil:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Veil:GetCanSleep()
    return true
end

function Veil:GetTechButtons(techId)

    if self:GetTechId() == kTechId.Veil then
        return { kTechId.UpgradeSilenceVeil, kTechId.UpgradeCamouflageVeil } //, kTechId.UpgradeFeintVeil }
    end    

end

if Server then

    function Veil:OnConstructionComplete()

        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberConstructed(self)
        end
    
    end
    
    function Veil:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)
        self:TriggerEffects("death")
        DestroyEntity(self)
    
    end

    function Veil:OnDestroy()
        
        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberDestroyed(self)
        end
        
        ScriptActor.OnDestroy(self)
    
    end
    
    function Veil:OnResearchComplete(researchId)

        local success = false

        if researchId == kTechId.UpgradeFeintVeil then            
            success = self:UpgradeToTechId(kTechId.FeintVeil)
        elseif researchId == kTechId.UpgradeSilenceVeil then 
            success = self:UpgradeToTechId(kTechId.SilenceVeil)
        elseif researchId == kTechId.UpgradeCamouflageVeil then            
            success = self:UpgradeToTechId(kTechId.CamouflageVeil)
        end    
    
        if success then
            local team = self:GetTeam()
            if team then
                team:OnUpgradeChamberConstructed(self)
            end
        end
        
    end    

end

local kVeilHealthbarOffset = Vector(0, 1, 0)
function Veil:GetHealthbarOffset()
    return kVeilHealthbarOffset
end

function Veil:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Veil:OverrideHintString(hintString)

    if self:GetIsUpgrading() then
        return "COMM_SEL_UPGRADING"
    end
    
    return hintString
    
end

Shared.LinkClassToMap("Veil", Veil.kMapName, networkVars)

class 'AuraVeil' (Veil)
AuraVeil.kMapName = "auraveil"
Shared.LinkClassToMap("AuraVeil", AuraVeil.kMapName, { })

class 'SilenceVeil' (Veil)
SilenceVeil.kMapName = "silenceveil"
Shared.LinkClassToMap("SilenceVeil", SilenceVeil.kMapName, { })

class 'FeintVeil' (Veil)
FeintVeil.kMapName = "feintveil"
Shared.LinkClassToMap("FeintVeil", FeintVeil.kMapName, { })

class 'CamouflageVeil' (Veil)
CamouflageVeil.kMapName = "camouflageveil"
Shared.LinkClassToMap("CamouflageVeil", CamouflageVeil.kMapName, { })