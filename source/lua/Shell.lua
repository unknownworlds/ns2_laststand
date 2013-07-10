// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shell.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Alien structure that hosts Shell upgrades. 1 shell: level 1 upgrade, 2 shells: level 2 etc.
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
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Shell' (ScriptActor)

Shell.kMapName = "shell"

Shell.kModelName = PrecacheAsset("models/alien/shell/shell.model")

Shell.kAnimationGraph = PrecacheAsset("models/alien/shell/shell.animation_graph")

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
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Shell:OnCreate()

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
    InitMixin(self, DissolveMixin)
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

function Shell:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shell.kModelName, Shell.kAnimationGraph)
    
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

function Shell:GetMaturityRate()
    return kShellMaturationTime
end

function Shell:GetMatureMaxHealth()
    return kMatureShellHealth
end 

local kShellHealthbarOffset = Vector(0, 0.45, 0)
function Shell:GetHealthbarOffset()
    return kShellHealthbarOffset
end

function Shell:GetMatureMaxArmor()
    return kMatureShellArmor
end 

function Shell:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Shell:GetCanSleep()
    return true
end

function Shell:GetTechButtons(techId)

    if self:GetTechId() == kTechId.Shell then
        return { kTechId.UpgradeCarapaceShell, kTechId.UpgradeRegenerationShell }
    end    
    
end

function Shell:GetIsWallWalkingAllowed()
    return false
end 

function Shell:GetReceivesStructuralDamage()
    return true
end

if Server then

    function Shell:OnConstructionComplete()

        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberConstructed(self)
        end
    
    end
    
    function Shell:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)
        self:TriggerEffects("death")
        DestroyEntity(self)
    
    end
    
    function Shell:OnDestroy()
        
        local team = self:GetTeam()
        if team then
            team:OnUpgradeChamberDestroyed(self)
        end
        
        ScriptActor.OnDestroy(self)
    
    end
    
    function Shell:OnResearchComplete(researchId)

        local success = false

        if researchId == kTechId.UpgradeRegenerationShell then            
            success = self:UpgradeToTechId(kTechId.RegenerationShell)
        elseif researchId == kTechId.UpgradeCarapaceShell then 
            success = self:UpgradeToTechId(kTechId.CarapaceShell)
        end   

        if success then
            local team = self:GetTeam()
            if team then
                team:OnUpgradeChamberConstructed(self)
            end
        end   
        
    end

end

function Shell:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Shell:OverrideHintString(hintString)

    if self:GetIsUpgrading() then
        return "COMM_SEL_UPGRADING"
    end
    
    return hintString
    
end


Shared.LinkClassToMap("Shell", Shell.kMapName, networkVars)

class 'RegenerationShell' (Shell)
RegenerationShell.kMapName = "regenerationshell"
Shared.LinkClassToMap("RegenerationShell", RegenerationShell.kMapName, { })

class 'CarapaceShell' (Shell)
CarapaceShell.kMapName = "carapaceshell"
Shared.LinkClassToMap("CarapaceShell", CarapaceShell.kMapName, { })