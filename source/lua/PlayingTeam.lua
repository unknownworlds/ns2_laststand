// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayingTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Team.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/TeamDeathMessageMixin.lua")

class 'PlayingTeam' (Team)

PlayingTeam.kObliterateVictoryTeamResourcesNeeded = 500

PlayingTeam.kTooltipHelpInterval = 1

PlayingTeam.kTechTreeUpdateTime = 1

PlayingTeam.kBaseAlertInterval = 15
PlayingTeam.kRepeatAlertInterval = 15

// How often to update clear and update game effects
PlayingTeam.kUpdateGameEffectsInterval = .3

PlayingTeam.kResearchDisplayTime = 40

/**
 * spawnEntity is the name of the map entity that will be created by default
 * when a player is spawned.
 */
function PlayingTeam:Initialize(teamName, teamNumber)

    InitMixin(self, TeamDeathMessageMixin)
    
    Team.Initialize(self, teamName, teamNumber)

    self.respawnEntity = nil
    
    self:OnCreate()
        
    self.timeSinceLastLOSUpdate = Shared.GetTime()
    self.timeSinceLastRTUpdate = Shared.GetTime()
    
    self.ejectCommVoteManager = VoteManager()
    self.ejectCommVoteManager:Initialize()
    
    self.concedeVoteManager = VoteManager()
    self.concedeVoteManager:Initialize()
    self.concedeVoteManager:SetTeamPercentNeeded(kPercentNeededForVoteConcede)

    // child classes can specify a custom team info class
    local teamInfoMapName = TeamInfo.kMapName
    if self.GetTeamInfoMapName then
        teamInfoMapName = self:GetTeamInfoMapName()
    end
    
    local teamInfoEntity = Server.CreateEntity(teamInfoMapName)
    
    self.teamInfoEntityId = teamInfoEntity:GetId()
    teamInfoEntity:SetWatchTeam(self)
    
    self.lastCommPingTime = 0
    self.lastCommPingPosition = Vector(0,0,0)
    
    self.entityTechIds = {}
    self.techIdCount = {}

    self.eventListeners = {}

end

function PlayingTeam:AddListener( event, func )

    local listeners = self.eventListeners[event]

    if not listeners then
        listeners = {}
        self.eventListeners[event] = listeners
    end

    table.insert( listeners, func )

    //DebugPrint( 'event %s has %d listeners', event, #self.eventListeners[event] )

end

function PlayingTeam:Uninitialize()

    if self.teamInfoEntityId and Shared.GetEntity(self.teamInfoEntityId) then
    
        DestroyEntity(Shared.GetEntity(self.teamInfoEntityId))
        self.teamInfoEntityId = nil
        
    end
    
    self.entityTechIds = { }
    self.techIdCount = { }
    
    Team.Uninitialize(self)
    
end

function PlayingTeam:AddPlayer(player)

    local added = Team.AddPlayer(self, player)
    
    player.teamResources = self.teamResources
    
    return added
    
end

function PlayingTeam:OnCreate()

    self.entityTechIds = {}
    self.techIdCount = {}
    Team.OnCreate(self)
      
end

function PlayingTeam:OnInitialized()

    self.entityTechIds = {}
    self.techIdCount = {}

    Team.OnInitialized(self)
    
    self:InitTechTree()
    self.requiredTechIds = self.techTree:GetRequiredTechIds()
    self.timeOfLastTechTreeUpdate = nil
    
    self.lastPlayedTeamAlertName = nil
    self.timeOfLastPlayedTeamAlert = nil
    self.alerts = {}
    
    self.timeSinceLastRTUpdate = Shared.GetTime()
    
    self.teamResources = 0
    self.totalTeamResourcesCollected = 0
    self.totalTeamResFromTowers = 0
    self:AddTeamResources(kPlayingTeamInitialTeamRes)
    
    self.ejectCommVoteManager:Reset()
    self.concedeVoteManager:Reset()
    
    self.conceded = false
    
    self.lastCommPingTime = 0
    self.lastCommPingPosition = Vector(0,0,0)

end

function PlayingTeam:ResetTeam()

    self.conceded = false
    
    local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
    for p = 1, #players do
    
        local player = players[p]
        // player:OnInitialSpawn(self:GetSpawnPosition())
        player:SetResources(kPlayerInitialIndivRes)
        
    end
    
    return commandStructure
    
end

function PlayingTeam:OnResetComplete()
end

function PlayingTeam:GetNumCapturedTechPoints()

    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    local count = 0
    
    for index, cs in ipairs(commandStructures) do
    
        if cs:GetIsBuilt() and cs:GetIsAlive() and cs:GetAttached() then
            count = count + 1
        end
        
    end
    
    return count

end

function PlayingTeam:Reset()

    self:OnInitialized()
    
    Team.Reset(self)

    Server.SendNetworkMessage( "Reset", {}, true )

end

function PlayingTeam:GetHasCommander()
    local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
    return table.count(commanders) > 0
end

function PlayingTeam:InitTechTree()
   
    self.techTree = TechTree()
    
    self.techTree:Initialize()
    
    self.techTree:SetTeamNumber(self:GetTeamNumber())
    
    // Menus
    self.techTree:AddMenu(kTechId.RootMenu)
    self.techTree:AddMenu(kTechId.BuildMenu)
    self.techTree:AddMenu(kTechId.AdvancedMenu)
    self.techTree:AddMenu(kTechId.AssistMenu)
    
    // Orders
    self.techTree:AddOrder(kTechId.Default)
    self.techTree:AddOrder(kTechId.Move)
    self.techTree:AddOrder(kTechId.Attack)
    self.techTree:AddOrder(kTechId.Build)
    self.techTree:AddOrder(kTechId.Construct)
    
    self.techTree:AddAction(kTechId.Cancel)
    
    self.techTree:AddOrder(kTechId.Weld)   
    
    self.techTree:AddAction(kTechId.Stop)
    
    self.techTree:AddOrder(kTechId.SetRally)
    self.techTree:AddOrder(kTechId.SetTarget)
    
end

// Returns marine or alien type
function PlayingTeam:GetTeamType()
    return self.teamType
end

local relevantResearchIds = nil
local function GetIsResearchRelevant(techId)

    if not relevantResearchIds then
    
        relevantResearchIds = {}
        relevantResearchIds[kTechId.ShotgunTech] = 2
        relevantResearchIds[kTechId.GrenadeLauncherTech] = 2
        relevantResearchIds[kTechId.RifleUpgradeTech] = 2
        relevantResearchIds[kTechId.FlamethrowerTech] = 2
        relevantResearchIds[kTechId.WelderTech] = 2
        relevantResearchIds[kTechId.MinesTech] = 2
        relevantResearchIds[kTechId.ShotgunTech] = 2
        relevantResearchIds[kTechId.ExosuitTech] = 3
        relevantResearchIds[kTechId.JetpackTech] = 3
        relevantResearchIds[kTechId.DualMinigunTech] = 3
        relevantResearchIds[kTechId.ClawRailgunTech] = 3
        relevantResearchIds[kTechId.DualRailgunTech] = 3
        
        relevantResearchIds[kTechId.Armor1] = 1
        relevantResearchIds[kTechId.Armor2] = 1
        relevantResearchIds[kTechId.Armor3] = 1
        
        relevantResearchIds[kTechId.Weapons1] = 1
        relevantResearchIds[kTechId.Weapons2] = 1
        relevantResearchIds[kTechId.Weapons3] = 1
        
        relevantResearchIds[kTechId.GorgeTunnelTech] = 1
        
        relevantResearchIds[kTechId.Leap] = 1
        relevantResearchIds[kTechId.BileBomb] = 1
        relevantResearchIds[kTechId.Spores] = 1
        relevantResearchIds[kTechId.Blink] = 1
        relevantResearchIds[kTechId.Stomp] = 1
        
        relevantResearchIds[kTechId.Xenocide] = 1
        relevantResearchIds[kTechId.Umbra] = 1
        relevantResearchIds[kTechId.Vortex] = 1
        relevantResearchIds[kTechId.BoneShield] = 1
        relevantResearchIds[kTechId.WebTech] = 1
    
    end
    
    return relevantResearchIds[techId]

end

function PlayingTeam:OnResearchComplete(structure, researchId)

    // Loop through all entities on our team and tell them research was completed
    local teamEnts = GetEntitiesWithMixinForTeam("Research", self:GetTeamNumber())
    for index, ent in ipairs(teamEnts) do
        ent:TechResearched(structure, researchId)
    end
    
    if structure then
    
        local techNode = self:GetTechTree():GetTechNode(researchId)
        
        if techNode and (techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() or techNode:GetIsPlasmaManufacture()) then
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertManufactureComplete, kTechId.AlienAlertManufactureComplete), structure)  
        else
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure)
        end
        
    end
    
    // pass relevant techIds to team info object
    local techPriority = GetIsResearchRelevant(researchId)
    if techPriority ~= nil then
    
        local teamInfoEntity = Shared.GetEntity(self.teamInfoEntityId)
        teamInfoEntity:SetLatestResearchedTech(researchId, Shared.GetTime() + PlayingTeam.kResearchDisplayTime, techPriority) 
        
    end

    // inform listeners

    local listeners = self.eventListeners['OnResearchComplete']

    if listeners then
    
        for _, listener in ipairs(listeners) do
            listener(structure, researchId)
        end

    end

end

function PlayingTeam:OnCommanderAction(techId)

    local listeners = self.eventListeners['OnCommanderAction']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end

function PlayingTeam:OnConstructionComplete(structure)

    local listeners = self.eventListeners['OnConstructionComplete']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(structure)
        end

    end

end

// Returns sound name of last alert and time last alert played (for testing)
function PlayingTeam:GetLastAlert()
    return self.lastPlayedTeamAlertName, self.timeOfLastPlayedTeamAlert
end

// Play audio alert for all players, but don't trigger them too often. 
// This also allows neat tactics where players can time strikes to prevent the other team from instant notification of an alert, ala RTS.
// Returns true if the alert was played.
function PlayingTeam:TriggerAlert(techId, entity, force)
    
end

function PlayingTeam:SetTeamResources(amount)

    self.teamResources = math.min(kMaxTeamResources, amount)
    
    function PlayerSetTeamResources(player)
        player:SetTeamResources(self.teamResources)
    end
    
    self:ForEachPlayer(PlayerSetTeamResources)
    
end

function PlayingTeam:GetTeamResources()

    return self.teamResources
    
end

function PlayingTeam:AddTeamResources(amount, countTowardsTotal)

    /* LS
    if countTowardsTotal then
    
        // Save towards victory condition
        self.totalTeamResourcesCollected = self.totalTeamResourcesCollected + amount
        
    end
    self:SetTeamResources(self.teamResources + amount)
    */
    
end
function PlayingTeam:GetTotalTeamResources()

    return self.totalTeamResourcesCollected

end


function PlayingTeam:GetTotalTeamResourcesFromTowers()

    return self.totalTeamResFromTowers

end

function PlayingTeam:GetHasTeamLost()

    if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then
    
        // Team can't respawn or last Command Station or Hive destroyed
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()
        local numAliveCommandStructures = self:GetNumAliveCommandStructures()
        
        if  (not activePlayers and not abilityToRespawn) or
            (numAliveCommandStructures == 0) or
            (self:GetNumPlayers() == 0) or 
            self:GetHasConceded() then
            
            return true
            
        end
        
    end
    
    return false
    
end

// TODO: Returns true if team has acheived alternate victory condition - hive releases bio-plague and marines teleport
// away and nuke station from orbit!
function PlayingTeam:GetHasTeamWon()
    return false
end

local function SpawnResourceTower(self, techPoint)

    local techPointOrigin = Vector(techPoint:GetOrigin())
    
    local closestPoint = nil
    local closestPointDistance = 0
    
    for index, current in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
    
        // The resource point and tech point must be in locations that share the same name.
        local sameLocation = techPoint:GetLocationName() == current:GetLocationName()
        if sameLocation then
        
            local pointOrigin = Vector(current:GetOrigin())
            local distance = (pointOrigin - techPointOrigin):GetLength()
            
            if current:GetAttached() == nil and closestPoint == nil or distance < closestPointDistance then
            
                closestPoint = current
                closestPointDistance = distance
                
            end
            
        end
        
    end
    
    // Now spawn appropriate resource tower there
    if closestPoint ~= nil then
    
        local techId = ConditionalValue(self:GetIsAlienTeam(), kTechId.Harvester, kTechId.Extractor)
        return closestPoint:SpawnResourceTowerForTeam(self, techId)
        
    end
    
    return nil
    
end

/**
 * Spawn hive or command station at nearest empty tech point to specified team location.
 * Does nothing if can't find any.
 */
local function SpawnCommandStructure(techPoint, teamNumber)

    local commandStructure = techPoint:SpawnCommandStructure(teamNumber)
    assert(commandStructure ~= nil)
    commandStructure:SetConstructionComplete()
    
    // Use same align as tech point.
    local techPointCoords = techPoint:GetCoords()
    techPointCoords.origin = commandStructure:GetOrigin()
    commandStructure:SetCoords(techPointCoords)
    
    return commandStructure
    
end

function PlayingTeam:GetHasAbilityToRespawn()
    return true
end

function PlayingTeam:GetIsAlienTeam()
    return false
end

function PlayingTeam:GetIsMarineTeam()
    return false    
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 * Pass nil origin/angles to have spawn entity chosen.
 */
function PlayingTeam:ReplaceRespawnPlayer(player, origin, angles, mapName)

    local spawnMapName = self.respawnEntity
    
    if mapName ~= nil then
        spawnMapName = mapName
    end
    
    local newPlayer = player:Replace(spawnMapName, self:GetTeamNumber(), false, origin)
    
    // If we fail to find a place to respawn this player, put them in the Team's
    // respawn queue.
    if not self:RespawnPlayer(newPlayer, origin, angles) then
    
        newPlayer = newPlayer:Replace(newPlayer:GetDeathMapName())
        self:PutPlayerInRespawnQueue(newPlayer)
        
    end
    
    newPlayer:ClearGameEffects()
    if HasMixin(newPlayer, "Upgradable") then
        newPlayer:ClearUpgrades()
    end
    
    return (newPlayer ~= nil), newPlayer
    
end

// Call with origin and angles, or pass nil to have them determined from team location and spawn points.
function PlayingTeam:RespawnPlayer(player, origin, angles)

    local success = false
    
    if origin ~= nil and angles ~= nil then
        success = Team.RespawnPlayer(self, player, origin, angles)
    else
    
        // Compute random spawn location
        // local capsuleHeight, capsuleRadius = player:GetTraceCapsule()
        // local spawnOrigin = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, self:GetSpawnPosition(), 2, 15, EntityFilterAll())
        local spawnOrigin = self:GetSpawnPosition()
        if spawnOrigin ~= nil then
        
            success = Team.RespawnPlayer(self, player, spawnOrigin, self:GetSpawnAngles())
            
        else
        
            Print("PlayingTeam:RespawnPlayer: Couldn't compute random spawn for player.\n")
            Print(Script.CallStack())
            
        end
        
    end
    
    return success
    
end

function PlayingTeam:TechAdded(entity)

    PROFILE("PlayingTeam:TechAdded")

    // Tell tech tree to recompute availability next think
    local techId = entity:GetTechId()

    if not self.requiredTechIds then
        self.requiredTechIds = { }
    end
    
    // don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end    
    
    table.insertunique(self.entityTechIds, techId)
    
    if self.techIdCount[techId] then
        self.techIdCount[techId] = self.techIdCount[techId] + 1
    else
        self.techIdCount[techId] = 1
    end
    
    //Print("TechAdded %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if self.techTree then
        self.techTree:SetTechChanged()
    end
end

function PlayingTeam:TechRemoved(entity)

    PROFILE("PlayingTeam:TechRemoved")

    // Tell tech tree to recompute availability next think
    
    local techId = entity:GetTechId()

    // don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end
    
    if self.techIdCount[techId] then    
        self.techIdCount[techId] = self.techIdCount[techId] - 1    
    end
    
    if self.techIdCount[techId] == nil or self.techIdCount[techId] <= 0 then
        table.removevalue(self.entityTechIds, techId)
        self.techIdCount[techId] = nil
    end
    
    //Print(ToString(debug.traceback()))
    //Print("TechRemoved %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
    
end

function PlayingTeam:Update(timePassed)

    PROFILE("PlayingTeam:Update")
    
    /* LS
    self:UpdateTechTree()
    */
    
    self:UpdateGameEffects(timePassed)
    
    self:UpdateVotes()
    
    /* LS
    if GetGamerules():GetGameStarted() then
        self:UpdateResourceTowers()
    end
    */
    
end

function PlayingTeam:PrintWorldTextForTeamInRange(messageType, data, position, range)

    local playersInRange = GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), position, range)
    local message = BuildWorldTextMessage(messageType, data, position)
    
    for _, player in ipairs(playersInRange) do
        Server.SendNetworkMessage(player, "WorldText", message, true)        
    end

end

function PlayingTeam:UpdateResourceTowers()

end

function PlayingTeam:GetTechTree()
    return self.techTree
end

function PlayingTeam:UpdateTechTree()

    PROFILE("PlayingTeam:UpdateTechTree")
    
    // Compute tech tree availability only so often because it's very slooow
    if self.techTree ~= nil and (self.timeOfLastTechTreeUpdate == nil or Shared.GetTime() > self.timeOfLastTechTreeUpdate + PlayingTeam.kTechTreeUpdateTime) then

        self.techTree:Update(self.entityTechIds, self.techIdCount)
        
        /*
        local techTreeString = ""        
        for _, techId in ipairs(self.entityTechIds) do            
            techTreeString = techTreeString .. " " .. EnumToString(kTechId, techId) .. "(" .. ToString(self.techIdCount[techId]) .. ")"            
        end        
        Print("-----------team nr %s", ToString(self:GetTeamNumber()))
        Print(techTreeString)
        Print("------------------------")
        */

        // Send tech tree base line to players that just switched teams or joined the game        
        local players = self:GetPlayers()
        
        for index, player in ipairs(players) do
        
            if player:GetSendTechTreeBase() then
            
                self.techTree:SendTechTreeBase(player)
                
                player:ClearSendTechTreeBase()
                
            end
            
        end
        
        // Send research, availability, etc. tech node updates to team players
        self.techTree:SendTechTreeUpdates(players)
        
        self.timeOfLastTechTreeUpdate = Shared.GetTime()
        
        self:OnTechTreeUpdated()
        
    end
    
end

function PlayingTeam:OnTechTreeUpdated()
end

// Update from alien team instead of in alien buildings think because we need to clear
// game effect flag too.
function PlayingTeam:UpdateGameEffects(timePassed)

    PROFILE("PlayingTeam:UpdateGameEffects")  

end

function PlayingTeam:UpdateTeamSpecificGameEffects()
end

function PlayingTeam:VoteToGiveUp(votingPlayer)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())

    if self.concedeVoteManager:PlayerVotes(votingPlayerSteamId, Shared.GetTime()) then
        PrintToLog("%s cast vote to give up.", votingPlayer:GetName())
        
        // notify all players on this team
        if Server then

            local vote = self.concedeVoteManager    

            local netmsg = {
                voterName = votingPlayer:GetName(),
                votesMoreNeeded = vote:GetNumVotesNeeded()-vote:GetNumVotesCast()
            }

            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())

            for index, player in ipairs(players) do
                Server.SendNetworkMessage(player, "VoteConcedeCast", netmsg, false)
            end

        end
    end

end

function PlayingTeam:VoteToEjectCommander(votingPlayer, targetCommander)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())
    local targetSteamId = tonumber(Server.GetOwner(targetCommander):GetUserId())
    
    if self.ejectCommVoteManager:PlayerVotesFor(votingPlayerSteamId, targetSteamId, Shared.GetTime()) then
        PrintToLog("%s cast vote to eject commander %s", votingPlayer:GetName(), targetCommander:GetName())

        // notify all players on this team
        if Server then

            local vote = self.ejectCommVoteManager    

            local netmsg = {
                voterName = votingPlayer:GetName(),
                votesMoreNeeded = vote:GetNumVotesNeeded()-vote:GetNumVotesCast()
            }

            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())

            for index, player in ipairs(players) do
                Server.SendNetworkMessage(player, "VoteEjectCast", netmsg, false)
            end

        end
    end
    
end

function PlayingTeam:UpdateVotes()

    PROFILE("PlayingTeam:UpdateVotes")
    
    // Update with latest team size
    self.ejectCommVoteManager:SetNumPlayers(self:GetNumPlayers())
    self.concedeVoteManager:SetNumPlayers(self:GetNumPlayers())

    // Eject commander if enough votes cast
    if self.ejectCommVoteManager:GetVotePassed() then    
        
        local targetCommander = GetPlayerFromUserId( self.ejectCommVoteManager:GetTarget() )
        
        if targetCommander and targetCommander.Eject then
            targetCommander:Eject()
        end        
        
        self.ejectCommVoteManager:Reset()
        
    elseif self.ejectCommVoteManager:GetVoteElapsed(Shared.GetTime()) then
    
        self.ejectCommVoteManager:Reset()
            
    end
    
    // give up when enough votes
    if self.concedeVoteManager:GetVotePassed() then
    
        self.concedeVoteManager:Reset()
        self.conceded = true

        // Notify all players
        Server.SendNetworkMessage( "TeamConceded", {teamNumber=self:GetTeamNumber()} )
        
    elseif self.concedeVoteManager:GetVoteElapsed(Shared.GetTime()) then
    
        self.concedeVoteManager:Reset()
            
    end 
        
    
end

function PlayingTeam:GetHasConceded()
    return self.conceded
end    

function PlayingTeam:GetPresRecipientCount()

    local recipientCount = 0
    for i, playerId in ipairs(self.playerIds) do
        
        local player = Shared.GetEntity(playerId)
        if player and player:GetResources() < kMaxPersonalResources and player:GetIsAlive() and not player:isa("Commander") then
            recipientCount = recipientCount + 1
        end

    end
    
    return recipientCount

end

// split resources to all players until their they either have all reached the maximum or the rewarded res was splitted evenly
function PlayingTeam:SplitPres(resAwarded)

    local recipientCount = self:GetPresRecipientCount()

    for i = 1, recipientCount do 
    
        if resAwarded <= 0.001 or recipientCount <= 0 then
            break;
        end    
    
        local resPerPlayer = resAwarded / recipientCount
        
        for i, playerId in ipairs(self.playerIds) do
            local player = Shared.GetEntity(playerId)
            if player and player:GetIsAlive() and not player:isa("Commander") then
                resAwarded = resAwarded - player:AddResources(resPerPlayer)
            end
        end
        
        recipientCount = self:GetPresRecipientCount()

    end

end

// add resources to player and split overflow amongst the team
function PlayingTeam:AwardPersonalResources(min, max, pointOwner)

    local resAwarded = math.random(min, max) 
    resAwarded = resAwarded - pointOwner:AwardResForKill(resAwarded)
    
    if resAwarded > 0 then
        self:SplitPres(resAwarded)
    end

end

function PlayingTeam:GetCommander()

    local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
    if commanders and #commanders > 0 then
        return commanders[1]
    end    

    return nil
end

function PlayingTeam:PlayCommanderSound(soundName)

    local commander = self:GetCommander()
    if commander then
        StartSoundEffectForPlayer(soundName, commander)
    end

end

function PlayingTeam:GetCommanderPingTime()
    return self.lastCommPingTime
end

function PlayingTeam:GetCommanderPingPosition()
    return self.lastCommPingPosition
end

function PlayingTeam:SetCommanderPing(position)

    if self.lastCommPingTime + 3 < Shared.GetTime() then
        self.lastCommPingTime = Shared.GetTime()
        self.lastCommPingPosition = position
    end
    
end
