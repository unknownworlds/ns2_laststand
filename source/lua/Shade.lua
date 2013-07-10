// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides cloaking abilities and confuse and deceive capabilities.
//
// Disorient (Passive) - Enemy structures and players flicker in and out when in range of Shade, 
// making it hard for Commander and team-mates to be able to support each other. Extreme reverb 
// sounds for enemies (and slight reverb sounds for friendlies) enhance the effect.
//
// Cloak (Triggered) - Instantly cloaks self and all enemy structures and aliens in range
// for a short time. Mutes or changes sounds too? Cleverly used, this would ideally allow a 
// team to get a stealth hive built. Allow players to stay cloaked for awhile, until they attack
// (even if they move out of range - great for getting by sentries).
//
// Hallucination - Allow Commander to create fake Fade, Onos, Hive (and possibly 
// ammo/medpacks). They can be pathed around and used to create tactical distractions or divert 
// forces elsewhere.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
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
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/CommAbilities/Alien/ShadeInk.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Shade' (ScriptActor)

Shade.kMapName = "shade"

Shade.kModelName = PrecacheAsset("models/alien/shade/shade.model")
Shade.kAnimationGraph = PrecacheAsset("models/alien/shade/shade.animation_graph")

local kCloakTriggered = PrecacheAsset("sound/NS2.fev/alien/structures/shade/cloak_triggered")
local kCloakTriggered2D = PrecacheAsset("sound/NS2.fev/alien/structures/shade/cloak_triggered_2D")

Shade.kCloakRadius = 14

Shade.kCloakUpdateRate = 0.2

local networkVars = { }

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
        
function Shade:OnCreate()

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
    InitMixin(self, FireMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, TeleportMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    
    if Server then
    
        //InitMixin(self, TriggerMixin, {kPhysicsGroup = PhysicsGroup.TriggerGroup, kFilterMask = PhysicsMask.AllButTriggers} )    
        InitMixin(self, InfestationTrackerMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)            
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Shade:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shade.kModelName, Shade.kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)

        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
    
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

function Shade:GetMaturityRate()
    return kShadeMaturationTime
end

function Shade:GetMatureMaxHealth()
    return kMatureShadeHealth
end 

function Shade:GetMatureMaxArmor()
    return kMatureShadeArmor
end 

function Shade:GetShowOrderLine()
    return true
end    

function Shade:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Shade:OverrideCreateManufactureEntity(techId)

    local emulatedTechId = GetTechIdToEmulate(techId)
    
    if emulatedTechId then

        local spawnPoint = self:GetOrigin() + Vector(0, 0.2, 0)
        
        local hallucination = CreateEntity(Hallucination.kMapName, spawnPoint, self:GetTeamNumber())
        hallucination:SetEmulation(techId)
        hallucination:SetOwner(self:GetIssuedCommander())
        hallucination:ProcessRallyOrder(self)
        
        return hallucination
    
    end

end

function Shade:OverrideBuildEntity(techId, position, commander)

    local emulatedTechId = GetTechIdToEmulate(techId)
    
    local newEnt = nil
    
    if emulatedTechId then
    
        local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, 0)
        local spawnHeightPosition = Vector(position.x,
                                           position.y + spawnHeight,
                                           position.z)

        newEnt = CreateEntity(Hallucination.kMapName, spawnHeightPosition, self:GetTeamNumber())
        newEnt:SetOwner(commander)
        
        // Hook it up to attach entity
        local attachEntity = GetAttachEntity(techId, position)    
        if attachEntity then    
            newEnt:SetAttached(attachEntity)        
        end
        
        newEnt:SetEmulation(techId)
        
    end
    
    return newEnt

end

function Shade:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then 
    
        techButtons = { kTechId.ShadeInk, kTechId.ShadeCloak, kTechId.None, kTechId.None,  // kTechId.ShadeDisorient, 
                        kTechId.None, kTechId.None, kTechId.None, kTechId.None}

        if not self:GetHasUpgrade(kTechId.ShadePhantomMenu) then
            techButtons[5] = kTechId.EvolveHallucinations
        else
        
            techButtons[5] = kTechId.ShadePhantomMenu
            techButtons[6] = kTechId.ShadePhantomStructuresMenu
        
        end
        
    elseif techId == kTechId.ShadePhantomMenu then
    
        techButtons = { kTechId.HallucinateDrifter, kTechId.HallucinateSkulk, kTechId.HallucinateGorge, kTechId.HallucinateLerk, 
                        kTechId.HallucinateFade, kTechId.HallucinateOnos }
                        
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu

    elseif techId == kTechId.ShadePhantomStructuresMenu then
    
        techButtons = { kTechId.HallucinateHive, kTechId.HallucinateHarvester, kTechId.HallucinateWhip, kTechId.HallucinateCrag, 
                        kTechId.HallucinateShade, kTechId.HallucinateShift }
                        
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
    
    end
    
    return techButtons
    
end

function Shade:OnResearchComplete(researchId)

    // Transform into mature shade
    if researchId == kTechId.EvolveHallucinations then
        success = self:GiveUpgrade(kTechId.ShadePhantomMenu)
    end
    
end

function Shade:TriggerInk()

    // Create ShadeInk entity in world at this position with a small offset
    CreateEntity(ShadeInk.kMapName, self:GetOrigin() + Vector(0, 0.2, 0), self:GetTeamNumber())
    return true

end

if Server then

    local function OnConsoleInk()
    
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        
            local shades = Shared.GetEntitiesWithClassname("Shade")
            for i, shade in ientitylist(shades) do
                shade:TriggerInk()
            end
            
        end
        
    end
    
    Event.Hook("Console_ink", OnConsoleInk)
    
end

function Shade:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.ShadeInk then
        success = self:TriggerInk()
    end
    
    return success, true
    
end

function Shade:GetReceivesStructuralDamage()
    return true
end

function Shade:OnUpdateAnimationInput(modelMixin)

    PROFILE("Shade:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("cloak", true)
    
end

function Shade:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

if Server then
    
    function Shade:OnConstructionComplete()    
        self:AddTimedCallback(Shade.UpdateCloaking, Shade.kCloakUpdateRate)    
    end
    
    function Shade:UpdateCloaking()
    
        for _, cloakable in ipairs( GetEntitiesWithMixinForTeamWithinRange("Cloakable", self:GetTeamNumber(), self:GetOrigin(), Shade.kCloakRadius) ) do
            cloakable:TriggerCloak()
        end
        
        return self:GetIsAlive()
    
    end

end

function Shade:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Shade:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)
    
    // prevent spamming of that ability, too many ink clouds at one place cause FPS problems
    if allowed and canAfford and techId == kTechId.ShadeInk then    
        allowed = #GetEntitiesForTeamWithinRange("ShadeInk", self:GetTeamNumber(), self:GetOrigin(), 8) == 0    
    end
    
    return allowed, canAfford
    
end

Shared.LinkClassToMap("Shade", Shade.kMapName, networkVars)