// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\AlienTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechData.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/UpgradeStructureManager.lua")
Script.Load("lua/LSGameEntities.lua")
Script.Load("lua/LSAlienDeck.lua")

class 'AlienTeam' (PlayingTeam)

// Innate alien regeneration
AlienTeam.kAutoHealInterval = 2
AlienTeam.kStructureAutoHealInterval = 0.5
AlienTeam.kAutoHealUpdateNum = 20 // number of structures to update per autoheal update

AlienTeam.kOrganicStructureHealRate = kHealingBedStructureRegen     // Health per second
AlienTeam.kInfestationUpdateRate = 2

AlienTeam.kSupportingStructureClassNames = {[kTechId.Hive] = {"Hive"} }
AlienTeam.kUpgradeStructureClassNames = {[kTechId.Crag] = {"Crag", "MatureCrag"}, [kTechId.Shift] = {"Shift", "MatureShift"}, [kTechId.Shade] = {"Shade", "MatureShift"} }
AlienTeam.kUpgradedStructureTechTable = {[kTechId.Crag] = {kTechId.MatureCrag}, [kTechId.Shift] = {kTechId.MatureShift}, [kTechId.Shade] = {kTechId.MatureShade}}

AlienTeam.kTechTreeIdsToUpdate = {} // {kTechId.Crag, kTechId.MatureCrag, kTechId.Shift, kTechId.MatureShift, kTechId.Shade, kTechId.MatureShade}

function AlienTeam:GetTeamType()
    return kAlienTeamType
end

function AlienTeam:GetIsAlienTeam()
    return true
end

function AlienTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = AlienSpectator.kMapName

    // List stores all the structures owned by builder player types such as the Gorge.
    // This list stores them based on the player platform ID in order to maintain structure
    // counts even if a player leaves and rejoins a server.
    self.clientOwnedStructures = { }
    self.lastAutoHealIndex = 1
    
    self.updateAlienArmorInTicks = nil
    
    self.cloakables = {}
    self.cloakableCloakCount = {}
    self.timeLastWave = 0
        
end

function AlienTeam:OnInitialized()

    PlayingTeam.OnInitialized(self)
    
    self.lastAutoHealIndex = 1
    
    self.clientOwnedStructures = { }
    
    self.cloakables = { }
    self.cloakableCloakCount = { }
    
    self.timeLastWave = 0
    
end

function AlienTeam:GetTeamInfoMapName()
    return AlienTeamInfo.kMapName
end

local function RemoveGorgeStructureFromClient(self, techId, clientId)

    local structureTypeTable = self.clientOwnedStructures[clientId]
    
    if structureTypeTable then
    
        if not structureTypeTable[techId] then
        
            structureTypeTable[techId] = { }
            return
            
        end    
        
        local removeIndex = 0
        local structure = nil
        for index, id in ipairs(structureTypeTable[techId])  do
        
            if id then
            
                removeIndex = index
                structure = Shared.GetEntity(id)
                break
                
            end
            
        end
        
        if structure then
        
            table.remove(structureTypeTable[techId], removeIndex)
            structure.consumed = true
            if structure:GetCanDie() then
                structure:Kill()
            else
                DestroyEntity(structure)
            end
            
        end
        
    end
    
end

function AlienTeam:AddGorgeStructure(player, structure)

    if player ~= nil and structure ~= nil then
    
        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()

        if not self.clientOwnedStructures[clientId] then
            self.clientOwnedStructures[clientId] = { }
        end
        
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if not structureTypeTable[techId] then
            structureTypeTable[techId] = { }
        end
        
        table.insertunique(structureTypeTable[techId], structureId)
        
        local numAllowedStructure = LookupTechData(techId, kTechDataMaxAmount, -1) //* self:GetNumHives()
        
        if numAllowedStructure >= 0 and table.count(structureTypeTable[techId]) > numAllowedStructure then
            RemoveGorgeStructureFromClient(self, techId, clientId)
        end
        
    end
    
end

function AlienTeam:GetDroppedGorgeStructures(player, techId)

    local owner = Server.GetOwner(player)

    if owner then
    
        local clientId = owner:GetUserId()
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if structureTypeTable then
            return structureTypeTable[techId]
        end
    
    end
    
end

function AlienTeam:GetNumDroppedGorgeStructures(player, techId)

    local structureTypeTable = self:GetDroppedGorgeStructures(player, techId)
    return (not structureTypeTable and 0) or #structureTypeTable
    
end

function AlienTeam:UpdateClientOwnedStructures(oldEntityId)

    if oldEntityId then
    
        for clientId, structureTypeTable in pairs(self.clientOwnedStructures) do
        
            for techId, structureList in pairs(structureTypeTable) do
            
                for i, structureId in ipairs(structureList) do
                
                    if structureId == oldEntityId then
                    
                        if newEntityId then
                            structureList[i] = newEntityId
                        else
                        
                            table.remove(structureList, i)
                            break
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end

end

function AlienTeam:OnEntityChange(oldEntityId, newEntityId)

    PlayingTeam.OnEntityChange(self, oldEntityId, newEntityId)

    // Check if the oldEntityId matches any client's built structure and
    // handle the change.
    
    self:UpdateClientOwnedStructures(oldEntityId)

end

local function CreateCysts(hive, harvester, teamNumber)

    local hiveOrigin = hive:GetOrigin()
    local harvesterOrigin = harvester:GetOrigin()
    
    // Spawn all the Cyst spawn points close to the hive.
    local dist = (hiveOrigin - harvesterOrigin):GetLength()
    for c = 1, #Server.cystSpawnPoints do
    
        local spawnPoint = Server.cystSpawnPoints[c]
        if (spawnPoint - hiveOrigin):GetLength() <= (dist * 1.5) then
        
            local cyst = CreateEntityForTeam(kTechId.Cyst, spawnPoint, teamNumber, nil)
            cyst:SetConstructionComplete()
            cyst:SetInfestationFullyGrown()
            cyst:SetImmuneToRedeploymentTime(1)
            
        end
        
    end
    
end

function AlienTeam:SpawnInitialStructures(techPoint)

    local tower, hive = PlayingTeam.SpawnInitialStructures(self, techPoint)
    
    hive:SetFirstLogin()
    hive:SetInfestationFullyGrown()
    
    // It is possible there was not an available tower if the map is not designed properly.
    if tower then
        CreateCysts(hive, tower, self:GetTeamNumber())
    end
    
    return tower, hive
    
end

function AlienTeam:GetHasAbilityToRespawn()

    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    return table.count(hives) > 0
    
end

local function AssignPlayerToEgg(self, player, enemyTeamPosition)

    local success = false
    
    // prioritize shift eggs first
    if not success then
    
        local shifts = GetEntitiesForTeam("Shift", self:GetTeamNumber())
        Shared.SortEntitiesByDistance(player:GetOrigin(), shifts)
        
        for _, shift in ipairs(shifts) do
        
            local egg = shift:GetEgg()
            if egg and egg:GetIsFree() then
            
                egg:SetQueuedPlayerId(player:GetId())
                success = true
                break
                
            end
            
        end
        
    end
    
    // if no shift eggs found, use non-preevolved eggs sorted by "critical hives position"
    if not success then
    
        local lifeFormEgg = nil
    
        if not enemyTeamPosition then
            enemyTeamPosition = player:GetOrigin()
        end
    
        local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())        
        Shared.SortEntitiesByDistance(enemyTeamPosition, eggs)
        
        // Find the closest egg, doesn't matter which Hive owns it.
        for _, egg in ipairs(eggs) do
        
            // Any unevolved egg is fine as long as it is free.
            if egg:GetIsFree() then
            
                if egg:GetGestateTechId() == kTechId.Skulk then
            
                    egg:SetQueuedPlayerId(player:GetId())
                    success = true
                    break
                
                elseif lifeFormEgg == nil then
                    lifeFormEgg = egg
                end
                
            end
            
        end
        
        // use life form egg
        if not success and lifeFormEgg then
        
            lifeFormEgg:SetQueuedPlayerId(player:GetId())
            success = true

        end
        
    end
    
    return success
    
end

local function GetCriticalHivePosition(self)

    // get position of enemy team, ignore commanders
    local numPositions = 0
    local teamPosition = Vector(0, 0, 0)
    
    for _, player in ipairs( GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber())) ) do

        if (player:isa("Marine") or player:isa("Exo")) and player:GetIsAlive() then
        
            numPositions = numPositions + 1
            teamPosition = teamPosition + player:GetOrigin()
        
        end

    end
    
    if numPositions > 0 then    
        return teamPosition / numPositions    
    end

end

local function UpdateSpawnWave(self)

    if self.timeLastWave + 2 > Shared.GetTime() then
        return
    end
    
    if self.timeNextWave == nil and self:GetNumPlayersInQueue() > 0 then
        self.timeNextWave = kAlienWaveSpawnInterval + Shared.GetTime()
    end
    
    if self.timeNextWave ~= nil and self.timeNextWave < Shared.GetTime() then
    
        local alienSpectators = self:GetSortedRespawnQueue()
        local enemyTeamPosition = GetCriticalHivePosition(self)
        
        for i = 1, #alienSpectators do
        
            local alienSpectator = alienSpectators[i]
            // Do not spawn players waiting in the auto team balance queue.
            if alienSpectator:isa("AlienSpectator") and not alienSpectator:GetIsWaitingForTeamBalance() then
            
                // Consider min death time.
                if alienSpectator:GetRespawnQueueEntryTime() + kAlienMinDeathTime < Shared.GetTime() then
                
                    local egg = nil
                    if alienSpectator.GetHostEgg then
                        egg = alienSpectator:GetHostEgg()
                    end
                    
                    // Player has no egg assigned, check for free egg.
                    if egg == nil then
                    
                        local success = AssignPlayerToEgg(self, alienSpectator, enemyTeamPosition)
                        
                        // We have no eggs currently, makes no sense to check for every spectator now.
                        if not success then
                            break
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
        self.timeNextWave = nil
        self.timeLastWave = Shared.GetTime()
        
    end
    
end

function AlienTeam:Update(timePassed)

    PROFILE("AlienTeam:Update")
    
    if self.updateAlienArmorInTicks then
    
        if self.updateAlienArmorInTicks == 0 then
        
            for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
                alien:UpdateArmorAmount()
            end
            
            self.updateAlienArmorInTicks = nil
        
        else
            self.updateAlienArmorInTicks = self.updateAlienArmorInTicks - 1
        end
        
    end

    PlayingTeam.Update(self, timePassed)
    
    self:UpdateTeamAutoHeal(timePassed)
    self:UpdateCloakables()
    UpdateSpawnWave(self)
    
end

function AlienTeam:OnTechTreeUpdated()

    if self.updateAlienArmor then
        
        self.updateAlienArmor = false
        self.updateAlienArmorInTicks = 100
        
    end

end

// update every tick but only a small amount of structures
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil then
        self.timeOfLastAutoHeal = Shared.GetTime()
    end
    
    if time > (self.timeOfLastAutoHeal + AlienTeam.kStructureAutoHealInterval) then
        
        local intervalLength = time - self.timeOfLastAutoHeal
        local gameEnts = GetEntitiesWithMixinForTeam("InfestationTracker", self:GetTeamNumber())
        local numEnts = table.count(gameEnts)
        local toIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum - 1
        toIndex = ConditionalValue(toIndex <= numEnts , toIndex, numEnts)
        local hasHealingBedUpgrade = GetHasHealingBedUpgrade(self:GetTeamNumber())
        
        for index = self.lastAutoHealIndex, toIndex do

            local entity = gameEnts[index]
            
            // players update the auto heal on their own
            if not entity:isa("Player") then
            
                // we add whips as an exception here. construction should still be restricted to onInfestation, we only don't want whips to take damage off infestation
                local requiresInfestation   = ConditionalValue(entity:isa("Whip"), false, LookupTechData(entity:GetTechId(), kTechDataRequiresInfestation))
                local isOnInfestation       = entity:GetGameEffectMask(kGameEffect.OnInfestation)
                local isHealable            = entity:GetIsHealable()
                local deltaTime             = 0
                
                if not entity.timeLastAutoHeal then
                    entity.timeLastAutoHeal = Shared.GetTime()
                else
                    deltaTime = Shared.GetTime() - entity.timeLastAutoHeal
                    entity.timeLastAutoHeal = Shared.GetTime()
                end

                if requiresInfestation and not isOnInfestation then
                    // Take damage!
                    local damage = entity:GetMaxHealth() * kBalanceInfestationHurtPercentPerSecond/100 * deltaTime
                    entity:DeductHealth(damage)
                    
                elseif isOnInfestation and isHealable and hasHealingBedUpgrade then
                    entity:AddHealth(math.min(AlienTeam.kOrganicStructureHealRate * deltaTime, 0.02*entity:GetMaxHealth()), true)                
                end
            
            end
        
        end
        
        if self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum >= numEnts then
            self.lastAutoHealIndex = 1
        else
            self.lastAutoHealIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum
        end 

        self.timeOfLastAutoHeal = Shared.GetTime()

   end
    
end

function AlienTeam:InitTechTree()

    PlayingTeam.InitTechTree(self)
    
    // Add special alien menus
    self.techTree:AddMenu(kTechId.MarkersMenu)
    self.techTree:AddMenu(kTechId.UpgradesMenu)
    self.techTree:AddMenu(kTechId.ShadePhantomMenu)
    self.techTree:AddMenu(kTechId.ShadePhantomStructuresMenu)
    self.techTree:AddMenu(kTechId.ShiftEcho)
    self.techTree:AddMenu(kTechId.LifeFormMenu)
    
    self.techTree:AddPassive(kTechId.Infestation)
    self.techTree:AddPassive(kTechId.SpawnAlien)
    self.techTree:AddPassive(kTechId.GrenadeWhack)
    self.techTree:AddPassive(kTechId.CollectResources)
    
    // Add markers (orders)
    self.techTree:AddSpecial(kTechId.ThreatMarker, true)
    self.techTree:AddSpecial(kTechId.LargeThreatMarker, true)
    self.techTree:AddSpecial(kTechId.NeedHealingMarker, true)
    self.techTree:AddSpecial(kTechId.WeakMarker, true)
    self.techTree:AddSpecial(kTechId.ExpandingMarker, true)
    
    // Gorge specific orders
    self.techTree:AddOrder(kTechId.AlienMove)
    self.techTree:AddOrder(kTechId.AlienAttack)
    //self.techTree:AddOrder(kTechId.AlienDefend)
    self.techTree:AddOrder(kTechId.AlienConstruct)
    self.techTree:AddOrder(kTechId.Heal)
    
    // Commander abilities
    self.techTree:AddBuildNode(kTechId.Cyst,                      kTechId.None,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.NutrientMist,              kTechId.None,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.BoneWall,                  kTechId.TwoHives,           kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.EnzymeCloud,      kTechId.None,           kTechId.None)
    self.techTree:AddActivation(kTechId.Rupture,                  kTechId.None,           kTechId.None)
           
    // Hive types
    self.techTree:AddBuildNode(kTechId.Hive,                    kTechId.None,           kTechId.None)
    self.techTree:AddPassive(kTechId.HiveHeal)
    self.techTree:AddBuildNode(kTechId.CragHive,                kTechId.Hive,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShadeHive,               kTechId.Hive,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShiftHive,               kTechId.Hive,                kTechId.None)
    
    self.techTree:AddUpgradeNode(kTechId.UpgradeToCragHive,     kTechId.Hive,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeToShadeHive,    kTechId.Hive,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeToShiftHive,    kTechId.Hive,                kTechId.None)
    
    // infestation upgrades
    self.techTree:AddResearchNode(kTechId.HealingBed,            kTechId.CragHive,            kTechId.None)
    self.techTree:AddResearchNode(kTechId.MucousMembrane,        kTechId.ShiftHive,           kTechId.None)
    self.techTree:AddResearchNode(kTechId.BacterialReceptors,    kTechId.ShadeHive,           kTechId.None)
    
    // Tier 1
    self.techTree:AddResearchNode(kTechId.GorgeTunnelTech,        kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Harvester,                 kTechId.None,                kTechId.None)
    self.techTree:AddManufactureNode(kTechId.Drifter,             kTechId.None,                kTechId.None)
    self.techTree:AddPassive(kTechId.DrifterCamouflage)

    // Whips
    self.techTree:AddBuildNode(kTechId.Whip,                      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.EvolveBombard,             kTechId.None,                kTechId.None)

    self.techTree:AddActivation(kTechId.WhipBombard)
    self.techTree:AddActivation(kTechId.WhipBombardCancel)
    self.techTree:AddActivation(kTechId.WhipUnroot)
    self.techTree:AddActivation(kTechId.WhipRoot)
    
    // Tier 1 lifeforms
    self.techTree:AddAction(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Gorge,                     kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Lerk,                      kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Fade,                      kTechId.None,                kTechId.None)
    self.techTree:AddAction(kTechId.Onos,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Egg,                      kTechId.None,                kTechId.None)
    
    self.techTree:AddUpgradeNode(kTechId.GorgeEgg,          kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.LerkEgg,          kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.FadeEgg,          kTechId.TwoHives,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.OnosEgg,          kTechId.ThreeHives,                kTechId.None)
    
    // Special alien structures. These tech nodes are modified at run-time, depending when they are built, so don't modify prereqs.
    self.techTree:AddBuildNode(kTechId.Crag,                      kTechId.CragHive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shift,                     kTechId.ShiftHive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shade,                     kTechId.ShadeHive,          kTechId.None)
    
    // Alien upgrade structure
    self.techTree:AddBuildNode(kTechId.Shell, kTechId.CragHive, kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeRegenerationShell, kTechId.CragHive, kTechId.None)
    self.techTree:AddBuildNode(kTechId.RegenerationShell, kTechId.None, kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Shell, kTechId.RegenerationShell)
    self.techTree:AddUpgradeNode(kTechId.UpgradeCarapaceShell, kTechId.CragHive, kTechId.None)
    self.techTree:AddBuildNode(kTechId.CarapaceShell, kTechId.None, kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Shell, kTechId.CarapaceShell)
    
    self.techTree:AddBuildNode(kTechId.Spur,                     kTechId.ShiftHive,          kTechId.None)    
    self.techTree:AddUpgradeNode(kTechId.UpgradeCeleritySpur,    kTechId.ShiftHive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.CeleritySpur,             kTechId.None,          kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Spur, kTechId.CeleritySpur) 
    self.techTree:AddUpgradeNode(kTechId.UpgradeAdrenalineSpur,    kTechId.ShiftHive,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.AdrenalineSpur,             kTechId.None,          kTechId.None)  
    self.techTree:AddTechInheritance(kTechId.Spur, kTechId.AdrenalineSpur)  
    //self.techTree:AddUpgradeNode(kTechId.UpgradeHyperMutationSpur, kTechId.ShiftHive,        kTechId.None) 
    //self.techTree:AddBuildNode(kTechId.HyperMutationSpur,          kTechId.None,        kTechId.None)  
    self.techTree:AddTechInheritance(kTechId.Spur, kTechId.HyperMutationSpur)   
    
    self.techTree:AddBuildNode(kTechId.Veil,                     kTechId.ShadeHive,        kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeSilenceVeil,     kTechId.ShadeHive,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.SilenceVeil,              kTechId.None,        kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Veil, kTechId.SilenceVeil)
    self.techTree:AddUpgradeNode(kTechId.UpgradeCamouflageVeil,  kTechId.ShadeHive,        kTechId.None) 
    self.techTree:AddBuildNode(kTechId.CamouflageVeil,           kTechId.None,        kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Veil, kTechId.CamouflageVeil)   
    //self.techTree:AddUpgradeNode(kTechId.UpgradeAuraVeil,  kTechId.ShadeHive,        kTechId.None) 
    //self.techTree:AddBuildNode(kTechId.AuraVeil,           kTechId.None,        kTechId.None) 
    //self.techTree:AddUpgradeNode(kTechId.UpgradeFeintVeil,  kTechId.ShadeHive,        kTechId.None) 
    //self.techTree:AddBuildNode(kTechId.FeintVeil,           kTechId.None,        kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Veil, kTechId.FeintVeil)

    // Crag
    self.techTree:AddPassive(kTechId.CragHeal)
    self.techTree:AddActivation(kTechId.HealWave,                kTechId.None,          kTechId.None)

    // Shift    
    self.techTree:AddUpgradeNode(kTechId.EvolveEcho,              kTechId.None,         kTechId.None)
    self.techTree:AddActivation(kTechId.ShiftHatch,               kTechId.None,         kTechId.None) 
    self.techTree:AddPassive(kTechId.ShiftEnergize,               kTechId.None,         kTechId.None)
    
    self.techTree:AddTargetedActivation(kTechId.TeleportHydra,       kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportWhip,        kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportCrag,        kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShade,       kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShift,       kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportVeil,        kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportSpur,        kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportShell,       kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportHive,       kTechId.None,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.TeleportEgg,       kTechId.None,         kTechId.None)

    // Shade
    self.techTree:AddUpgradeNode(kTechId.EvolveHallucinations,    kTechId.None,        kTechId.None)
    self.techTree:AddPassive(kTechId.ShadeDisorient)
    self.techTree:AddPassive(kTechId.ShadeCloak)
    self.techTree:AddActivation(kTechId.ShadeInk,                 kTechId.None,         kTechId.None) 

    // Hallucinations
    self.techTree:AddManufactureNode(kTechId.HallucinateDrifter,  kTechId.None,   kTechId.None)
    self.techTree:AddManufactureNode(kTechId.HallucinateSkulk,    kTechId.None,   kTechId.None)
    self.techTree:AddManufactureNode(kTechId.HallucinateGorge,    kTechId.None,   kTechId.None)
    self.techTree:AddManufactureNode(kTechId.HallucinateLerk,     kTechId.None,   kTechId.None)
    self.techTree:AddManufactureNode(kTechId.HallucinateFade,     kTechId.None,   kTechId.None)
    self.techTree:AddManufactureNode(kTechId.HallucinateOnos,     kTechId.None,   kTechId.None)
    
    self.techTree:AddBuildNode(kTechId.HallucinateHive,           kTechId.None,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateWhip,           kTechId.None,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateShade,          kTechId.ShadeHive,      kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateCrag,           kTechId.CragHive,       kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateShift,          kTechId.ShiftHive,      kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateHarvester,      kTechId.None,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.HallucinateHydra,          kTechId.None,           kTechId.None)
    
    self.techTree:AddSpecial(kTechId.TwoHives)
    self.techTree:AddSpecial(kTechId.ThreeHives)
    
    // Tier 2
    
    self.techTree:AddResearchNode(kTechId.Leap,             kTechId.TwoHives,          kTechId.None)
    self.techTree:AddResearchNode(kTechId.Spores,           kTechId.TwoHives,          kTechId.None)
    self.techTree:AddResearchNode(kTechId.BileBomb,         kTechId.TwoHives,          kTechId.None)
    self.techTree:AddResearchNode(kTechId.Blink,            kTechId.TwoHives,          kTechId.None)
    //self.techTree:AddResearchNode(kTechId.BoneShield,       kTechId.TwoHives,         kTechId.None) 

    // Tier 3
     
    self.techTree:AddResearchNode(kTechId.Xenocide,          kTechId.Leap,               kTechId.ThreeHives)
    self.techTree:AddResearchNode(kTechId.Umbra,             kTechId.Spores,             kTechId.ThreeHives)
    //self.techTree:AddResearchNode(kTechId.WebTech,           kTechId.BileBomb,           kTechId.ThreeHives)
    self.techTree:AddResearchNode(kTechId.Vortex,            kTechId.Blink,              kTechId.ThreeHives)
    self.techTree:AddResearchNode(kTechId.BoneShield,        kTechId.TwoHives,           kTechId.None)  
    self.techTree:AddResearchNode(kTechId.Stomp,             kTechId.ThreeHives,         kTechId.None)

    // gorge structures

    self.techTree:AddBuildNode(kTechId.Hydra,            kTechId.None,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.Clog,             kTechId.None,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.BabblerEgg,       kTechId.None,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.GorgeTunnel,      kTechId.GorgeTunnelTech,    kTechId.None) 
    //self.techTree:AddBuildNode(kTechId.Web,              kTechId.WebTech,            kTechId.ThreeHives) 

    // personal upgrades (all alien types)
    
    self.techTree:AddBuyNode(kTechId.Carapace, kTechId.CarapaceShell, kTechId.None, kTechId.AllAliens)    
    self.techTree:AddBuyNode(kTechId.Regeneration, kTechId.RegenerationShell, kTechId.None, kTechId.AllAliens)
    self.techTree:AddBuyNode(kTechId.Silence, kTechId.SilenceVeil, kTechId.None, kTechId.AllAliens)
    self.techTree:AddBuyNode(kTechId.Camouflage, kTechId.CamouflageVeil, kTechId.None, kTechId.AllAliens)
    self.techTree:AddBuyNode(kTechId.Celerity, kTechId.CeleritySpur, kTechId.None, kTechId.AllAliens)  
    self.techTree:AddBuyNode(kTechId.Adrenaline, kTechId.AdrenalineSpur, kTechId.None, kTechId.AllAliens)  

    self.techTree:SetComplete()
    
end

function AlienTeam:GetNumHives()

    local teamInfoEntity = Shared.GetEntity(self.teamInfoEntityId)
    return teamInfoEntity:GetNumCapturedTechPoints()
    
end

function AlienTeam:GetActiveHiveCount()

    local activeHiveCount = 0
    
    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if hive:GetIsAlive() and hive:GetIsBuilt() then
            activeHiveCount = activeHiveCount + 1
        end
    
    end

    return activeHiveCount

end

function AlienTeam:GetActiveEggCount()

    local activeEggCount = 0
    
    for _, egg in ipairs(GetEntitiesForTeam("Egg", self:GetTeamNumber())) do
    
        if egg:GetIsAlive() and egg:GetIsEmpty() then
            activeEggCount = activeEggCount + 1
        end
    
    end
    
    return activeEggCount

end

/**
 * Inform all alien players about the hive construction (add new abilities).
 */
function AlienTeam:OnHiveConstructed(newHive)

    local activeHiveCount = self:GetActiveHiveCount()
    
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
    
        if alien:GetIsAlive() and alien.OnHiveConstructed then
            alien:OnHiveConstructed(newHive, activeHiveCount)
        end
        
    end
    
    SendTeamMessage(self, kTeamMessageTypes.HiveConstructed, newHive:GetLocationId())
    
end

/**
 * Inform all alien players about the hive destruction (remove abilities).
 */
function AlienTeam:OnHiveDestroyed(destroyedHive)

    local activeHiveCount = self:GetActiveHiveCount()
    
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
    
        if alien:GetIsAlive() and alien.OnHiveDestroyed then
            alien:OnHiveDestroyed(destroyedHive, activeHiveCount)
        end
        
    end
    
end

function AlienTeam:OnUpgradeChamberConstructed(upgradeChamber)

    if upgradeChamber:GetTechId() == kTechId.CarapaceShell then
        self.updateAlienArmor = true
    end
    
end

function AlienTeam:OnUpgradeChamberDestroyed(upgradeChamber)

    if upgradeChamber:GetTechId() == kTechId.CarapaceShell then
        self.updateAlienArmor = true
    end
    
    // These is a list of all tech to check when a upgrade chamber is destroyed.
    local checkForLostResearch = { [kTechId.RegenerationShell] = { "Shell", kTechId.Regeneration },
                                   [kTechId.CarapaceShell] = { "Shell", kTechId.Carapace },
                                   [kTechId.CeleritySpur] = { "Spur", kTechId.Celerity },
                                   [kTechId.AdrenalineSpur] = { "Spur", kTechId.Adrenaline },
                                   [kTechId.SilenceVeil] = { "Veil", kTechId.Silence },
                                   [kTechId.CamouflageVeil] = { "Veil", kTechId.Camouflage } }
    
    local checkTech = checkForLostResearch[upgradeChamber:GetTechId()]
    if checkTech then
    
        local anyRemain = false
        for _, ent in ientitylist(Shared.GetEntitiesWithClassname(checkTech[1])) do
        
            // Don't count the upgradeChamber as it is being destroyed now.
            if ent ~= upgradeChamber and ent:GetTechId() == upgradeChamber:GetTechId() then
            
                anyRemain = true
                break
                
            end
            
        end
        
        if not anyRemain then
            SendTeamMessage(self, kTeamMessageTypes.ResearchLost, checkTech[2])
        end
        
    end
    
end

function AlienTeam:OnResearchComplete(structure, researchId)

    PlayingTeam.OnResearchComplete(self, structure, researchId)
    
    local checkForGainedResearch = { [kTechId.UpgradeRegenerationShell] = kTechId.Regeneration,
                                     [kTechId.UpgradeCarapaceShell] = kTechId.Carapace,
                                     [kTechId.UpgradeCeleritySpur] = kTechId.Celerity,
                                     [kTechId.UpgradeAdrenalineSpur] = kTechId.Adrenaline,
                                     [kTechId.UpgradeSilenceVeil] = kTechId.Silence,
                                     [kTechId.UpgradeCamouflageVeil] = kTechId.Camouflage }
    
    local gainedResearch = checkForGainedResearch[researchId]
    if gainedResearch then
        SendTeamMessage(self, kTeamMessageTypes.ResearchComplete, gainedResearch)
    end
    
end

function AlienTeam:UpdateCloakables()

    for index, cloakableId in ipairs(self.cloakables) do
        local cloakable = Shared.GetEntity(cloakableId)
        cloakable:SetIsCloaked(true, 1, false)
    end
 
end

function AlienTeam:GetSpectatorMapName()
    return AlienSpectator.kMapName
end

local function NotTooLate(waveTime, player)

    return player.GetRespawnQueueEntryTime ~= nil and player:GetRespawnQueueEntryTime() ~= nil and
           player:GetRespawnQueueEntryTime() + kAlienMinDeathTime < waveTime
    
end

function AlienTeam:GetWaveSpawnEndTime(forPlayer)

    local timeNextWave = 0
    if self.timeNextWave then
    
        local queuePos = self:GetPlayerPositionInRespawnQueue(forPlayer)
        
        if self.timeNextWave and #GetEntitiesForTeam("Egg", self:GetTeamNumber()) >= queuePos and NotTooLate(self.timeNextWave, forPlayer) then
            timeNextWave = self.timeNextWave
        end
        
    end

    return timeNextWave

end

function AlienTeam:OnEvolved(techId)

    local listeners = self.eventListeners['OnEvolved']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end

function AlienTeam:GetSpawnPosition()
    return gAlienSpawn:GetOrigin()
end

function AlienTeam:GetSpawnAngles()
    return gAlienSpawn:GetAngles()
end

function AlienTeam:RollAliens()

    local result = {}
    local weights = {}
    local roundFraction = GetGamerules():GetRoundFraction()
    
    if GetGamerules():GetGameState() ~= kGameState.Started then
        roundFraction = 0
    end
    
    Print('Round fraction: %f', roundFraction)
    
    local totalWeight = 0
    for i = 1, #kAlienDeck do
        if kAlienDeck[i].start <= roundFraction then
            local minWeight = kAlienDeck[i].minWeight
            local maxWeight = kAlienDeck[i].maxWeight
            
            local t = (roundFraction - kAlienDeck[i].start) / (1 - kAlienDeck[i].start)
            local weight = minWeight + t*(maxWeight - minWeight)
            totalWeight = totalWeight + weight
            table.insert(weights, weight)
            Print('%s has weight %f', kAlienDeck[i].name, weight)
        else
            Print('%s is not available, starts at %f',  kAlienDeck[i].name, kAlienDeck[i].start)
            table.insert(weights, 0)
        end
    end
    
    while #result < 3 do
        
        local roll = math.random(1, totalWeight)
        local currentWeight = 0
        local rolledAlien = nil
        for i = 1, #kAlienDeck do
            if weights[i] > 0 then
                currentWeight = currentWeight + weights[i]
                if roll <= currentWeight then
                    rolledAlien = i
                    break
                end
            end
        end
        
        assert(rolledAlien ~= nil)
        
        // Check not already rolled
        for i = 1, #result do
            if result[i] == rolledAlien then
                rolledAlien = nil
                break
            end
        end
        
        if rolledAlien ~= nil then
            Print('Rolled %s', kAlienDeck[rolledAlien].name)
            table.insert(result, rolledAlien)
        end
            
    end

    return result

end
            