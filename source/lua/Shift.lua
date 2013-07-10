// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shift.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that allows commander to outmaneuver and redeploy forces. 
//
// Recall - Ability that lets players jump to nearest structure (or hive) under attack (cooldown 
// of a few seconds)
// Energize - Passive ability that gives energy to nearby players
// Echo - Targeted ability that lets Commander move a structure or drifter elsewhere on the map
// (even a hive or harvester!). 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/Alien/ShiftEcho.lua")
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
Script.Load("lua/FireMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Shift' (ScriptActor)

Shift.kMapName = "shift"

Shift.kModelName = PrecacheAsset("models/alien/shift/shift.model")

local kAnimationGraph = PrecacheAsset("models/alien/shift/shift.animation_graph")

Shift.kEchoTargetSound = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize")

Shift.kEnergizeSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize")
Shift.kEnergizeTargetSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize_player")
//Shift.kRecallSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/recall")


Shift.kEnergizeEffect = PrecacheAsset("cinematics/alien/shift/energize.cinematic")
Shift.kEnergizeSmallTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_small.cinematic")
Shift.kEnergizeLargeTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_large.cinematic")

Shift.kEchoMaxRange = 20

local kNumEggSpotsPerShift = 20

local networkVars =
{
    hydraInRange = "boolean",
    whipInRange = "boolean",
    cragInRange = "boolean",
    shadeInRange = "boolean",
    shiftInRange = "boolean",
    veilInRange = "boolean",
    spurInRange = "boolean",
    shellInRange = "boolean",
    hiveInRange = "boolean",
    eggInRange = "boolean",
    echoActive = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
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
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

local function GetIsTeleport(techId)

return techId == kTechId.TeleportHydra or
       techId == kTechId.TeleportWhip or
       techId == kTechId.TeleportCrag or
       techId == kTechId.TeleportShade or
       techId == kTechId.TeleportShift or
       techId == kTechId.TeleportVeil or
       techId == kTechId.TeleportSpur or
       techId == kTechId.TeleportShell or
       techId == kTechId.TeleportHive or
       techId == kTechId.TeleportEgg

end

local gTeleportClassnames = nil
local function GetTeleportClassname(techId)

    if not gTeleportClassnames then
    
        gTeleportClassnames = {}
        gTeleportClassnames[kTechId.TeleportHydra] = "Hydra"
        gTeleportClassnames[kTechId.TeleportWhip] = "Whip"
        gTeleportClassnames[kTechId.TeleportCrag] = "Crag"
        gTeleportClassnames[kTechId.TeleportShade] = "Shade"
        gTeleportClassnames[kTechId.TeleportShift] = "Shift"
        gTeleportClassnames[kTechId.TeleportVeil] = "Veil"
        gTeleportClassnames[kTechId.TeleportSpur] = "Spur"
        gTeleportClassnames[kTechId.TeleportShell] = "Shell"
        gTeleportClassnames[kTechId.TeleportHive] = "Hive"
        gTeleportClassnames[kTechId.TeleportEgg] = "Egg"
    
    end
    
    return gTeleportClassnames[techId]


end

local function ResetShiftButtons(self)

    self.hydraInRange = false
    self.whipInRange = false
    self.cragInRange = false
    self.shadeInRange = false
    self.shiftInRange = false
    self.veilInRange = false
    self.spurInRange = false
    self.shellInRange = false
    self.hiveInRange = false
    self.eggInRange = false
    
end

local function UpdateShiftButtons(self)

    ResetShiftButtons(self)

    local teleportAbles = GetEntitiesWithMixinForTeamWithinRange("TeleportAble", self:GetTeamNumber(), self:GetOrigin(), kEchoRange)    
    for _, teleportable in ipairs(teleportAbles) do
    
        if teleportable:isa("Hydra") then
            self.hydraInRange = true
        elseif teleportable:isa("Whip") then
            self.whipInRange = true
        elseif teleportable:isa("Crag") then
            self.cragInRange = true
        elseif teleportable:isa("Shade") then
            self.shadeInRange = true
        elseif teleportable:isa("Shift") then
            self.shiftInRange = true
        elseif teleportable:isa("Veil") then
            self.veilInRange = true
        elseif teleportable:isa("Spur") then
            self.spurInRange = true
        elseif teleportable:isa("Shell") then
            self.shellInRange = true
        elseif teleportable:isa("Hive") then
            self.hiveInRange = true
        elseif teleportable:isa("Egg") then
            self.eggInRange = true
        end
    
    end

end

function Shift:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
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
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, DissolveMixin)
    
    ResetShiftButtons(self)
    
    if Server then
    
        InitMixin(self, InfestationTrackerMixin)
        self.remainingFindEggSpotAttempts = 300
        self.eggSpots = {}
        
    elseif Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
    self.echoActive = false
    self.timeLastEcho = 0
    
end

function Shift:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shift.kModelName, kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
    
        self:AddTimedCallback(Shift.EnergizeInRange, 0.5)
        self.shiftEggs = {}
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

function Shift:EnergizeInRange()

    if self:GetIsBuilt() then
    
        local energizeAbles = GetEntitiesWithMixinForTeamWithinRange("Energize", self:GetTeamNumber(), self:GetOrigin(), kEnergizeRange)
        
        for _, entity in ipairs(energizeAbles) do
        
            if entity ~= self then
                entity:Energize(self)
            end
            
        end
    
    end
    
    return self:GetIsAlive()
    
end

function Shift:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Shift:GetReceivesStructuralDamage()
    return true
end

function Shift:GetMaturityRate()
    return kShiftMaturationTime
end

function Shift:GetMatureMaxHealth()
    return kMatureShiftHealth
end 

function Shift:GetMatureMaxArmor()
    return kMatureShiftArmor
end

function Shift:GetShowOrderLine()
    return true
end  

function Shift:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player) 
    
    allowed = allowed and not self.echoActive
    
    if allowed then
 
        if techId == kTechId.TeleportHydra then
            allowed = self.hydraInRange
        elseif techId == kTechId.TeleportWhip then
            allowed = self.whipInRange
        elseif techId == kTechId.TeleportCrag then
            allowed = self.cragInRange
        elseif techId == kTechId.TeleportShade then
            allowed = self.shadeInRange
        elseif techId == kTechId.TeleportShift then
            allowed = self.shiftInRange
        elseif techId == kTechId.TeleportVeil then
            allowed = self.veilInRange
        elseif techId == kTechId.TeleportSpur then
            allowed = self.spurInRange
        elseif techId == kTechId.TeleportShell then
            allowed = self.shellInRange
        elseif techId == kTechId.TeleportHive then
            allowed = self.hiveInRange
        elseif techId == kTechId.TeleportEgg then
            allowed = self.eggInRange
        end
    
    end
    
    return allowed, canAfford
    
end

local function GetEchoButtons()

    return {
    
        kTechId.TeleportCrag, kTechId.TeleportShade, kTechId.TeleportShift, kTechId.TeleportWhip,
        kTechId.TeleportShell, kTechId.TeleportVeil, kTechId.TeleportSpur, kTechId.RootMenu
    
    }

end

function Shift:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then 
    
        techButtons = { kTechId.ShiftHatch, kTechId.ShiftEnergize, kTechId.None, kTechId.None,
                        kTechId.ShiftEcho, kTechId.None, kTechId.None, kTechId.None }

        if not self:GetHasUpgrade(kTechId.ShiftEcho) then
            techButtons[5] = kTechId.EvolveEcho
        end

    elseif techId == kTechId.ShiftEcho then
    
        return GetEchoButtons()
    
    end

    return techButtons

end

function Shift:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetTeleport)
    end

end

function Shift:OnOrderGiven(order)

    local distance = GetPathDistance(self:GetOrigin(), order:GetLocation())
    
    if not distance or distance >= Shift.kEchoMaxRange then
        self:ClearOrders()
    end  

end

if Server then

    function Shift:OnTeleportEnd()
    
        self.remainingFindEggSpotAttempts = 300
        self.eggSpots = {}
    
    end

    function Shift:OnUpdate(deltaTime)
    
        PROFILE("Shift:OnUpdate")
    
        ScriptActor.OnUpdate(self, deltaTime)
    
        if not self.timeLastButtonCheck or self.timeLastButtonCheck + 2 < Shared.GetTime() then
        
            self.timeLastButtonCheck = Shared.GetTime()
            UpdateShiftButtons(self)
            
        end
        
        self.echoActive = self.timeLastEcho + TeleportMixin.kDefaultDelay > Shared.GetTime()
        
        if self.remainingFindEggSpotAttempts > 0 and #self.eggSpots < kNumEggSpotsPerShift then
        
            local extents = LookupTechData(kTechId.Skulk, kTechDataMaxExtents, nil)
            local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)  
            local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, self:GetOrigin() + Vector(0, 0.4, 0), 2, 13, EntityFilterAll())
            
            if spawnPoint ~= nil then
            
                spawnPoint = GetGroundAtPosition(spawnPoint, nil, PhysicsMask.AllButPCs, extents)
                table.insert(self.eggSpots, spawnPoint)
                
            end
            
            self.remainingFindEggSpotAttempts = self.remainingFindEggSpotAttempts - 1
        
        end
            
    end

    function Shift:OnResearchComplete(researchId)

        // Transform into mature shift
        if researchId == kTechId.EvolveEcho then
            self:GiveUpgrade(kTechId.ShiftEcho)
        end
        
    end

    function Shift:TriggerEcho(techId, position)
    
        local teleportClassname = GetTeleportClassname(techId)
        local teleportCost = LookupTechData(techId, kTechDataCostKey, kShiftEchoCost)
        
        local success = false
        
        local validPos = GetIsBuildLegal(techId, position, 0, kStructureSnapRadius, self:GetOwner(), self)
        
        if validPos then
        
            local teleportAbles = GetEntitiesForTeamWithinRange(teleportClassname, self:GetTeamNumber(), self:GetOrigin(), kEchoRange)
            Shared.SortEntitiesByDistance(self:GetOrigin(), teleportAbles)
            
            for _, teleportAble in ipairs(teleportAbles) do
            
                if teleportAble:GetCanTeleport() then
                
                    teleportAble:TriggerTeleport(5, self:GetId(), position, teleportCost)
                    self:TriggerEffects("shift_echo")
                    success = true
                    self.echoActive = true
                    self.timeLastEcho = Shared.GetTime()
                    break
                    
                end
            
            end
        
        end
        
        return success
        
    end

    function Shift:TriggerHatch()
    
        if not self:GetIsBuilt() then
            return false
        end    
    
        if #self.eggSpots == 0 then
            return false
        end 
        
        local position = nil
        local egg = nil
        
        for j = 1, kEggsPerHatch do
        
            for i = 1, #self.eggSpots do
                
                position = self.eggSpots[i]

                local validForEgg = GetIsPlacementForTechId(position, true, kTechId.Egg)
                local validForSkulk = GetIsPlacementForTechId(position, true, kTechId.Skulk)
                local notNearResourcePoint = #GetEntitiesWithinRange("ResourcePoint", position, 2) == 0
                
                if validForEgg and validForSkulk and notNearResourcePoint then
                
                    egg = CreateEntity(Egg.kMapName, position, self:GetTeamNumber())
                    if egg then

                        // Randomize starting angles
                        local angles = self:GetAngles()
                        angles.yaw = math.random() * math.pi * 2
                        egg:SetAngles(angles)
                        
                        // To make sure physics model is updated without waiting a tick
                        egg:UpdatePhysicsModel()
                        
                        // prioritizes as a spawn point
                        self:RegisterEgg(egg)
                        
                        // completely breaks the whole code
                        break
                        
                    end 
                    
                end 
            
            end
            
        end    

        return egg ~= nil 
            
    end
    
    function Shift:RegisterEgg(egg)
    
        if egg and egg:isa("Egg") then
            table.insertunique(self.shiftEggs, egg:GetId())
        end
    
    end

    function Shift:GetNumEggs()
        return #self.shiftEggs
    end
    
    // returns first egg from the list
    function Shift:GetEgg()
    
        local eggId = self.shiftEggs[1]
        if eggId then
            return Shared.GetEntity(eggId)
        end    
        
    end
    
    function Shift:PerformActivation(techId, position, normal, commander)
    
        local success = false
        local continue = true
        
        if GetIsTeleport(techId) then
        
            success = self:TriggerEcho(techId, position)
            if success then
                UpdateShiftButtons(self)
            end

        elseif techId == kTechId.ShiftHatch then
            success = self:TriggerHatch()
            continue = false
        end
        
        return success, continue
        
    end
    
    function Shift:OnEntityChange(oldId, newId)
        
        if table.contains(self.shiftEggs, oldId) then
            table.removevalue(self.shiftEggs, oldId)
        end
        
    end

end

function GetShiftIsBuilt(techId, origin, normal, commander)

    // check if there is a built command station in our team
    if not commander then
        return false
    end    
    
    local attachRange = LookupTechData(kTechId.ShiftHatch, kStructureAttachRange, 1)
    
    local shifts = GetEntitiesForTeamWithinRange("Shift", commander:GetTeamNumber(), origin, attachRange)
    for _, shift in ipairs(shifts) do
        
        if shift:GetIsBuilt() then
            return true
        end    
        
    end
    
    return false
    
end

function GetShiftHatchGhostGuides(commander)

    local shifts = GetEntitiesForTeam("Shift", commander:GetTeamNumber())
    local attachRange = LookupTechData(kTechId.ShiftHatch, kStructureAttachRange, 1)
    local result = { }
    
    for _, shift in ipairs(shifts) do
        if shift:GetIsBuilt() then
            result[shift] = attachRange
        end
    end
    
    return result

end

function Shift:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

Shared.LinkClassToMap("Shift", Shift.kMapName, networkVars)