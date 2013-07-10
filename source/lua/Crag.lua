// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Crag.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that gives the commander defense and protection abilities.
//
// Passive ability - heals nearby players and structures
// Triggered ability - emit defensive umbra (8 seconds)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
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
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")

class 'Crag' (ScriptActor)

Crag.kMapName = "crag"

Crag.kModelName = PrecacheAsset("models/alien/crag/crag.model")

Crag.kAnimationGraph = PrecacheAsset("models/alien/crag/crag.animation_graph")

// Same as NS1
Crag.kHealRadius = 10
Crag.kHealAmount = 10
Crag.kHealWaveAmount = 50
Crag.kMaxTargets = 3
Crag.kThinkInterval = .25
Crag.kHealInterval = 2
Crag.kHealEffectInterval = 1

Crag.kHealWaveDuration = 8

Crag.kHealPercentage = 0.03
Crag.kMinHeal = 10
Crag.kMaxHeal = 40
Crag.kHealWaveMultiplier = 2.5

local networkVars =
{
    // For client animations
    healingActive = "boolean",
    healWaveActive = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
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
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Crag:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
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
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, TeleportMixin)    
    InitMixin(self, UmbraMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    
    self.healingActive = false
    self.healWaveActive = false
    
    self:SetUpdates(true)
    
    InitMixin(self, FireMixin)
    
    if Server then
        InitMixin(self, InfestationTrackerMixin)
    elseif Client then    
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Crag:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Crag.kModelName, Crag.kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        // TODO: USE TRIGGERS, see shade

        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
end

function Crag:GetMaturityRate()
    return kCragMaturationTime
end

function Crag:GetMatureMaxHealth()
    return kMatureCragHealth
end 

function Crag:GetMatureMaxArmor()
    return kMatureCragArmor
end 

function Crag:GetShowOrderLine()
    return true
end    

function Crag:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Crag:GetCanSleep()
    return not healingActive
end

function Crag:PerformHealing()

    PROFILE("Crag:PerformHealing")

    local targets = GetEntitiesWithMixinForTeamWithinRange("Live", self:GetTeamNumber(), self:GetOrigin(), Crag.kHealRadius)
    local entsHealed = 0
    
    for _, target in ipairs(targets) do
    
        local healAmount = self:TryHeal(target)
        entsHealed = entsHealed + ((healAmount > 0 and 1) or 0)
    
    end

    if entsHealed > 0 then   
        self.timeOfLastHeal = Shared.GetTime()        
    end
    
end

function Crag:TryHeal(target)

    local unclampedHeal = target:GetMaxHealth() * Crag.kHealPercentage
    local heal = Clamp(unclampedHeal, Crag.kMinHeal, Crag.kMaxHeal)
    
    if self.healWaveActive then
        heal = heal * Crag.kHealWaveMultiplier
    end
    
    if target:GetHealthScalar() ~= 1 and target:RegisterHealer(self, Shared.GetTime() + Crag.kHealInterval) then
        local amountHealed = target:AddHealth(heal)
        //if amountHealed > 0 then
        //    Print("Healing %s by %.2f (%d, %d) => %.2f", target:GetClassName(), unclampedHeal, Crag.kMinHeal, Crag.kMaxHeal, heal)
        //end
        return amountHealed
    else
        return 0
    end
    
end

function Crag:UpdateHealing()

    local time = Shared.GetTime()
    
    if self.timeOfLastHeal == nil or (time > self.timeOfLastHeal + Crag.kHealInterval) then    
        self:PerformHealing()        
    end
    
end

// Look for nearby friendlies to heal
function Crag:OnUpdate(deltaTime)

    PROFILE("Crag:OnUpdate")

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
    
        if not self.timeLastCragUpdate then
            self.timeLastCragUpdate = Shared.GetTime()
        end
        
        if self.timeLastCragUpdate + Crag.kThinkInterval < Shared.GetTime() then
        
            if self:GetIsBuilt() then
            
                self:UpdateHealing()
                
            end

            self.healingActive = self:GetIsHealingActive()
            self.healWaveActive = self:GetIsHealWaveActive()
            
            self.timeLastCragUpdate = Shared.GetTime()
            
        end
    
    elseif Client then
    
        if self.healWaveActive or self.healingActive then
        
            if not self.lastHealEffect or self.lastHealEffect + Crag.kHealEffectInterval < Shared.GetTime() then
            
                local localPlayer = Client.GetLocalPlayer()
                local showHeal = not HasMixin(self, "Cloakable") or not self:GetIsCloaked() or not GetAreEnemies(self, localPlayer)
        
                if showHeal then
                
                    if self.healWaveActive then
                        self:TriggerEffects("crag_heal_wave")
                    elseif self.healingActive then
                        self:TriggerEffects("crag_heal")
                    end
                    
                end
                
                self.lastHealEffect = Shared.GetTime()
            
            end
            
        end
    
    end
    
end

function Crag:GetTechButtons(techId)

    local techButtons = { kTechId.HealWave, kTechId.CragHeal, kTechId.None, kTechId.None, 
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    
    return techButtons
    
end

function Crag:GetIsHealWaveActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastHealWave ~= nil) and (Shared.GetTime() < (self.timeOfLastHealWave + Crag.kHealWaveDuration))
end

function Crag:GetIsHealingActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastHeal ~= nil) and (Shared.GetTime() < (self.timeOfLastHeal + Crag.kHealInterval))
end

function Crag:TriggerHealWave(commander)

    if not self:GetIsHealWaveActive() then
        self.timeOfLastHealWave = Shared.GetTime()
        return true
    end
    
    return false
    
end

function Crag:GetReceivesStructuralDamage()
    return true
end

function Crag:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)

    if techId == kTechId.HealWave then
        allowed = allowed and not self.healWaveActive
    end
    
    return allowed, canAfford

end

function Crag:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.HealWave then
        success = self:TriggerHealWave(commander)
    end
    
    return success, true
    
end

function Crag:OnUpdateAnimationInput(modelMixin)

    PROFILE("Crag:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("heal", self.healingActive or self.healWaveActive)
    
end

function Crag:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function Crag:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end


Shared.LinkClassToMap("Crag", Crag.kMapName, networkVars)