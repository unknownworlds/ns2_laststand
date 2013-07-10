// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\NS2Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules.lua")
Script.Load("lua/dkjson.lua")
Script.Load("lua/ServerSponitor.lua")

if Client then
    Script.Load("lua/NS2ConsoleCommands_Client.lua")
else
    Script.Load("lua/NS2ConsoleCommands_Server.lua")
end

gRoundSecs = 150.0
gReadySecs = 30.0

class 'NS2Gamerules' (Gamerules)

local networkVars = 
{
    lsSecsLeft = "time",
    lsPreGameSecsLeft = "time",
    lsReadySecsLeft = "time",
    lsNumMarinesLeft = "integer (0 to 255)",
    gameState = "enum kGameState"
}

NS2Gamerules.kMapName = "ns2_gamerules"

local kGameEndCheckInterval = 0.5
local kPreGameLength = 20
local kTimeToReadyRoom = 5.0
local kPauseToSocializeBeforeMapcycle = 30
local kGameStartMessageInterval = 10

// How often to send the "No commander" message to players in seconds.
local kSendNoCommanderMessageRate = 50

////////////
// Server //
////////////
if Server then

    gGameEventListeners = { }

    Script.Load("lua/PlayingTeam.lua")
    Script.Load("lua/ReadyRoomTeam.lua")
    Script.Load("lua/SpectatingTeam.lua")
    Script.Load("lua/GameViz.lua")
    Script.Load("lua/ObstacleMixin.lua")

    NS2Gamerules.kMarineStartSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/game_start")
    NS2Gamerules.kAlienStartSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/game_start")
    NS2Gamerules.kCountdownSound = PrecacheAsset("sound/NS2.fev/common/countdown")

    // Allow players to spawn in for free (not using IP or eggs) for this many seconds after the game starts
    local kFreeSpawnTime = 60

    function NS2Gamerules:BuildTeam(teamType)

        if teamType == kAlienTeamType then
            return AlienTeam()
        end
        
        return MarineTeam()
        
    end

    function NS2Gamerules:SetGameState(state)
    
        if state ~= self.gameState then
        
            self.gameState = state
            self.gameInfo:SetState(state)
            self.timeGameStateChanged = Shared.GetTime()
            self.timeSinceGameStateChanged = 0
            
            local frozenState = (state == kGameState.Countdown) and (not Shared.GetDevMode())
            self.team1:SetFrozenState(frozenState)
            self.team2:SetFrozenState(frozenState)
            
            if self.gameState == kGameState.Started then

                DestroyLiveMapEntities()

                PostGameViz("Game started")
                self.gameStartTime = Shared.GetTime()
                
                self.gameInfo:SetStartTime(self.gameStartTime)
                
                SendTeamMessage(self.team1, kTeamMessageTypes.GameStarted)
                SendTeamMessage(self.team2, kTeamMessageTypes.GameStarted)
                
                // Reset disconnected player resources when a game starts to prevent shenanigans.
                self.disconnectedPlayerResources = { }

                //----------------------------------------
                //  LS init
                //----------------------------------------
                self.lsSecsLeft = gRoundSecs

                // signal all the equipment piles
                // we should really have an event system here..
                for i, listener in pairs(gGameEventListeners) do
                    if listener.OnGameStart then
                        listener:OnGameStart()
                    end
                end

            elseif state == kGameState.Team1Won or state == kGameState.Team2Won then

                // On end game, check for map switch conditions
            
                if MapCycle_TestCycleMap() then
                    self.timeToCycleMap = Shared.GetTime() + kPauseToSocializeBeforeMapcycle
                else
                    self.timeToCycleMap = nil
                end

            elseif state == kGameState.PreGame then

                self.lsPreGameSecsLeft = self:GetPregameLength()

                for i, listener in pairs(gGameEventListeners) do
                    if listener.OnPreGameStart then
                        listener:OnPreGameStart()
                    end
                end
                
                // Balance teams!
                local p1 = self.team1:GetNumPlayers()
                local p2 = self.team2:GetNumPlayers()
                
                while math.abs(p1 - p2) > 1 do
                
                    local from, to
                    
                    if p1 > p2 then
                        from, toTeam = self.team1, kTeam2Index
                    else
                        from, toTeam = self.team2, kTeam1Index
                    end
                    
                    local victimList = from:GetPlayers()
                    local victimIndex = math.random(1, #victimList)
                    local victim = victimList[victimIndex]

                    Print('Moving player %s to team %i', ToString(victim), toTeam)
                    self:JoinTeam(victim, toTeam, true)
                    
                    p1 = self.team1:GetNumPlayers()
                    p2 = self.team2:GetNumPlayers()
                    
                end
                
                // Reset all aliens
                local aliens = self.team2:GetPlayers()
                for i = 1, #aliens do
                    self.team2:ReplaceRespawnPlayer(aliens[i], nil, nil)
                end

            elseif state == kGameState.NotStarted then

                self.lsReadySecsLeft = gReadySecs

            end
            
        end
        
    end

    function NS2Gamerules:GetGameTimeChanged()
        return self.timeSinceGameStateChanged
    end

    function NS2Gamerules:GetGameState()
        return self.gameState
    end

    function NS2Gamerules:OnCreate()

        // Calls SetGamerules()
        Gamerules.OnCreate(self)

        self.sponitor = ServerSponitor()
        self.sponitor:Initialize(self)
        
        self.techPointRandomizer = Randomizer()
        self.techPointRandomizer:randomseed(Shared.GetSystemTime())
        
        // Create team objects
        self.team1 = self:BuildTeam(kTeam1Type)
        self.team1:Initialize(kTeam1Name, kTeam1Index)
        self.sponitor:ListenToTeam(self.team1)
        
        self.team2 = self:BuildTeam(kTeam2Type)
        self.team2:Initialize(kTeam2Name, kTeam2Index)
        self.sponitor:ListenToTeam(self.team2)
        
        self.worldTeam = ReadyRoomTeam()
        self.worldTeam:Initialize("World", kTeamReadyRoom)
        
        self.spectatorTeam = SpectatingTeam()
        self.spectatorTeam:Initialize("Spectator", kSpectatorIndex)
        
        self.gameInfo = Server.CreateEntity(GameInfo.kMapName)
        
        self:SetGameState(kGameState.NotStarted)
        
        self.allTech = false
        self.orderSelf = false
        self.autobuild = false
        
        //self:SetIsVisible(false)
        //self:SetPropagate(Entity.Propagate_Never)
        
        // Used to keep track of the amount of resources a player has when they
        // reconnect so we can award them the res back if they reconnect soon.
        self.disconnectedPlayerResources = { }
        
        self.justCreated = true

        self.lsSecsLeft = 0.0
        
    end

    function NS2Gamerules:OnDestroy()

        self.team1:Uninitialize()
        self.team1 = nil
        self.team2:Uninitialize()
        self.team2 = nil
        self.worldTeam:Uninitialize()
        self.worldTeam = nil
        self.spectatorTeam:Uninitialize()
        self.spectatorTeam = nil

        Gamerules.OnDestroy(self)

    end
    
    function NS2Gamerules:GetFriendlyFire()
        return true // LS
    end
    
    // All damage is routed through here.
    function NS2Gamerules:CanEntityDoDamageTo(attacker, target)
        return true // LS
        //return CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), self:GetFriendlyFire())
    end
    
    function NS2Gamerules:OnClientDisconnect(client)
    
        local player = client:GetControllingPlayer()
        
        if player ~= nil then
        
            // When a player disconnects remove them from their team
            local team = self:GetTeam(player:GetTeamNumber())
            if team then
                team:RemovePlayer(player)
            end
            
            player:RemoveSpectators(nil)
            
            self.disconnectedPlayerResources[client:GetUserId()] = player:GetResources()
            
        end
        
        Gamerules.OnClientDisconnect(self, client)
        
    end
    
    function NS2Gamerules:OnEntityCreate(entity)

        self:OnEntityChange(nil, entity:GetId())

        if entity.GetTeamNumber then
        
            local team = self:GetTeam(entity:GetTeamNumber())
            
            if team then
            
                if entity:isa("Player") then
            
                    if team:AddPlayer(entity) then

                        // Tell team to send entire tech tree on team change
                        entity.sendTechTreeBase = true           
                        
                    end
                   
                    // Send scoreboard changes to everyone    
                    entity:SetScoreboardChanged(true)
                
                end
                
            end
            
        end
        
    end

    function NS2Gamerules:OnEntityDestroy(entity)
        
        self:OnEntityChange(entity:GetId(), nil)

        if entity.GetTeamNumber then
        
            local team = self:GetTeam(entity:GetTeamNumber())
            if team then
            
                if entity:isa("Player") then
                    team:RemovePlayer(entity)
                end
                
            end
            
        end
       
    end

    // Update player and entity lists
    function NS2Gamerules:OnEntityChange(oldId, newId)

        PROFILE("NS2Gamerules:OnEntityChange")
        
        if self.worldTeam then
            self.worldTeam:OnEntityChange(oldId, newId)
        end
        
        if self.team1 then
            self.team1:OnEntityChange(oldId, newId)
        end
        
        if self.team2 then
            self.team2:OnEntityChange(oldId, newId)
        end
        
        if self.spectatorTeam then
            self.spectatorTeam:OnEntityChange(oldId, newId)
        end
        
        // Keep server map entities up to date
        local index = table.find(Server.mapLoadLiveEntityValues, oldId)
        if index then
        
            table.removevalue(Server.mapLoadLiveEntityValues, oldId)
            if newId then
                table.insert(Server.mapLoadLiveEntityValues, newId)
            end
            
        end
        
        local notifyEntities = Shared.GetEntitiesWithTag("EntityChange")
        
        // Tell notifyEntities this entity has changed ids or has been deleted (changed to nil).
        for index, ent in ientitylist(notifyEntities) do
        
            if ent:GetId() ~= oldId and ent.OnEntityChange then
                ent:OnEntityChange(oldId, newId)
            end
            
        end
        
    end

    // Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
    function NS2Gamerules:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        
        // Also output to log if we're recording the game for playback in the game visualizer
        PostGameViz(string.format("%s killed %s", SafeClassName(doer), SafeClassName(targetEntity)), targetEntity)
        
        self.team1:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.team2:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.worldTeam:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.spectatorTeam:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.sponitor:OnEntityKilled(targetEntity, attacker, doer)

    end

    // logs out any players currently as the commander
    function NS2Gamerules:LogoutCommanders()

        for index, entity in ientitylist(Shared.GetEntitiesWithClassname("CommandStructure")) do
            entity:Logout()
        end
        
    end
     
    /**
     * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
     * respawn playing players.
     */
    function NS2Gamerules:ResetGame()
    
        // save commanders for later re-login
        local team1CommanderClientIndex = self.team1:GetCommander() and self.team1:GetCommander().clientIndex or nil
        local team2CommanderClientIndex = self.team2:GetCommander() and self.team2:GetCommander().clientIndex or nil
        
        // Cleanup any peeps currently in the commander seat by logging them out
        // have to do this before we start destroying stuff.
        self:LogoutCommanders()
        
        // Destroy any map entities that are still around
        DestroyLiveMapEntities()
        
        // Track which clients have joined teams so we don't 
        // give them starting resources again if they switch teams
        self.userIdsInGame = {}
        
        self:SetGameState(kGameState.NotStarted)
        
        // Reset all players, delete other not map entities that were created during 
        // the game (hives, command structures, initial resource towers, etc)
        // We need to convert the EntityList to a table since we are destroying entities
        // within the EntityList here.
        for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do
        
            // Don't reset/delete NS2Gamerules or TeamInfo.
            // NOTE!!!
            // MapBlips are destroyed by their owner which has the MapBlipMixin.
            // There is a problem with how this reset code works currently. A map entity such as a Hive creates
            // it's MapBlip when it is first created. Before the entity:isa("MapBlip") condition was added, all MapBlips
            // would be destroyed on map reset including those owned by map entities. The map entity Hive would still reference
            // it's original MapBlip and this would cause problems as that MapBlip was long destroyed. The right solution
            // is to destroy ALL entities when a game ends and then recreate the map entities fresh from the map data
            // at the start of the next game, including the NS2Gamerules. This is how a map transition would have to work anyway.
            // Do not destroy any entity that has a parent. The entity will be destroyed when the parent is destroyed or
            // when the owner manually destroyes the entity.
            local shieldTypes = { "GameInfo", "MapBlip", "NS2Gamerules" }
            local allowDestruction = true
            for i = 1, #shieldTypes do
                allowDestruction = allowDestruction and not entity:isa(shieldTypes[i])
            end
            
            if allowDestruction and entity:GetParent() == nil then
            
                local isMapEntity = entity:GetIsMapEntity()
                local mapName = entity:GetMapName()
                
                // Reset all map entities and all player's that have a valid Client (not ragdolled players for example).
                local resetEntity = entity:isa("TeamInfo") or entity:GetIsMapEntity() or (entity:isa("Player") and entity:GetClient() ~= nil)
                if resetEntity then
                
                    if entity.Reset then
                        entity:Reset()
                    end
                    
                else
                    DestroyEntity(entity)
                end
                
            end       
            
        end
        
        // Clear out obstacles from the navmesh before we start repopualating the scene
        RemoveAllObstacles()
        
        // Build list of tech points
        local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
        if table.maxn(techPoints) < 2 then
            Print("Warning -- Found only %d %s entities.", table.maxn(techPoints), TechPoint.kMapName)
        end
        
        local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
        if resourcePoints:GetSize() < 2 then
            Print("Warning -- Found only %d %s entities.", resourcePoints:GetSize(), ResourcePoint.kPointMapName)
        end
        
        
        self.worldTeam:ResetPreservePlayers(nil)
        self.spectatorTeam:ResetPreservePlayers(nil)    
        
        // Replace players with their starting classes with default loadouts at spawn locations
        self.team1:ReplaceRespawnAllPlayers()
        self.team2:ReplaceRespawnAllPlayers()
        
        // Create team specific entities
        local commandStructure1 = self.team1:ResetTeam()
        local commandStructure2 = self.team2:ResetTeam()
        
        // login the commanders again
        local function LoginCommander(commandStructure, team, clientIndex)
            if commandStructure and clientIndex then
                for i,player in ipairs(team:GetPlayers()) do
                    if player.clientIndex == clientIndex then
                        // make up for not manually moving to CS and using it
                        commandStructure.occupied = true
                        player:SetOrigin(commandStructure:GetDefaultEntryOrigin())
                        commandStructure:LoginPlayer(player)
                        break
                    end
                end 
            end
        end
        
        LoginCommander(commandStructure1, self.team1, team1CommanderClientIndex)
        LoginCommander(commandStructure2, self.team2, team2CommanderClientIndex)
        
        // Create living map entities fresh
        CreateLiveMapEntities()
        
        self.forceGameStart = false
        self.losingTeam = nil
        self.preventGameEnd = nil
        // Reset banned players for new game
        self.bannedPlayers = {}
        
        // Send scoreboard update, ignoring other scoreboard updates (clearscores resets everything)
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            Server.SendCommand(player, "onresetgame")
            //player:SetScoreboardChanged(false)
        end
        
        self.team1:OnResetComplete()
        self.team2:OnResetComplete()
        
    end
    
    function NS2Gamerules:GetTeam1()
        return self.team1
    end
    
    function NS2Gamerules:GetTeam2()
        return self.team2
    end
    
    function NS2Gamerules:GetWorldTeam()
        return self.worldTeam
    end
    
    function NS2Gamerules:GetSpectatorTeam()
        return self.spectatorTeam
    end
    
    function NS2Gamerules:GetTeams()
        return { self.team1, self.team2, self.worldTeam, self.spectatorTeam }
    end
    
    /**
     * Should be called when the Hive type is chosen.
     */
    function NS2Gamerules:SetHiveTechIdChosen(hive, techId)
    
        if self.initialHiveTechId == nil then
            self.initialHiveTechId = techId
        end
        
    end
    
    function NS2Gamerules:UpdateScores()

        if (self.timeToSendScores == nil or Shared.GetTime() > self.timeToSendScores) then
        
            local allPlayers = Shared.GetEntitiesWithClassname("Player")

            // If any player scoreboard info has changed, send those updates to everyone
            for index, fromPlayer in ientitylist(allPlayers) do
            
                // Send full update if any part of it changed
                if(fromPlayer:GetScoreboardChanged()) then
                
                    // If any value has changed then we also want to update the internal score
                    // so we can update steams player info.
                    local client = Server.GetOwner(fromPlayer)
                    if client ~= nil then
                    
                        local playerScore = 0
                        if HasMixin(fromPlayer, "Scoring") then
                            playerScore = fromPlayer:GetScore()
                        end
                        Server.UpdatePlayerInfo(client, fromPlayer:GetName(), playerScore)
                        
                        if(fromPlayer:GetName() ~= "") then
                        
                            // Now send scoreboard info to everyone, including fromPlayer     
                            for index, sendToPlayer in ientitylist(allPlayers) do
                                // Build the message per player as some info is not synced for players
                                // on the other team.
                                local scoresMessage = BuildScoresMessage(fromPlayer, sendToPlayer)
                                Server.SendNetworkMessage(sendToPlayer, "Scores", scoresMessage, true)
                            end
                            
                            fromPlayer:SetScoreboardChanged(false)
                            
                        else
                            Print("Player name empty, can't send scoreboard update.")
                        end

                    end
                    
                end
                
            end
            
            // When players connect to server, they send up a request for scores (as they 
            // may not have finished connecting when the scores where previously sent)    
            for index, requestingPlayer in ientitylist(allPlayers) do

                // Check for empty name string because player isn't connected yet
                if(requestingPlayer:GetRequestsScores() and requestingPlayer:GetName() ~= "") then
                
                    // Send player all scores
                    for index, fromPlayer in ientitylist(allPlayers) do
                    
                        local scoresMessage = BuildScoresMessage(fromPlayer, requestingPlayer)
                        Server.SendNetworkMessage(requestingPlayer, "Scores", scoresMessage, true)
   
                    end
                    
                    requestingPlayer:SetRequestsScores(false)
                    
                end
                
            end
                
            // Time to send next score
            self.timeToSendScores = Shared.GetTime() + kScoreboardUpdateInterval
            
        end

    end

    // Batch together string with pings of every player to update scoreboard. This is a separate
    // command to keep network utilization down.
    function NS2Gamerules:UpdatePings()
    
        local now = Shared.GetTime()
        
        // Check if the individual player's should be sent their own ping.
        if self.timeToSendIndividualPings == nil or now >= self.timeToSendIndividualPings then
        
            for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                Server.SendNetworkMessage(player, "Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), false)
            end
            
            self.timeToSendIndividualPings =  now + kUpdatePingsIndividual
            
        end
        
        // Check if all player's pings should be sent to everybody.
        if self.timeToSendAllPings == nil or  now >= self.timeToSendAllPings then
        
            for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                Server.SendNetworkMessage("Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), false)
            end
            
            self.timeToSendAllPings =  now + kUpdatePingsAll
            
        end
        
    end
    
    // Sends player health to all spectators
    function NS2Gamerules:UpdateHealth()
    
        if self.timeToSendHealth == nil or Shared.GetTime() > self.timeToSendHealth then
        
            local spectators = Shared.GetEntitiesWithClassname("Spectator")
            if spectators:GetSize() > 0 then
            
                // Send spectator all health
                for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                
                    for index, spectator in ientitylist(spectators) do
                        Server.SendNetworkMessage(spectator, "Health", BuildHealthMessage(player), false)
                    end
                    
                end
            
            end
            self.timeToSendHealth = Shared.GetTime() + 0.25
            
        end
        
    end
    
    // Send Tech Point info to all spectators
    function NS2Gamerules:UpdateTechPoints()
    
        if self.timeToSendTechPoints == nil or Shared.GetTime() > self.timeToSendTechPoints then
        
            local spectators = Shared.GetEntitiesWithClassname("Spectator")
            if spectators:GetSize() > 0 then
                
                local powerNodes = Shared.GetEntitiesWithClassname("PowerPoint")
                local eggs = Shared.GetEntitiesWithClassname("Egg")
                
                for _, techpoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
                
                    local message = BuildTechPointsMessage(techpoint, powerNodes, eggs)
                    for _, spectator in ientitylist(spectators) do
                        Server.SendNetworkMessage(spectator, "TechPoints", message, false)
                    end
                    
                end
            
            end
            
            self.timeToSendTechPoints = Shared.GetTime() + 0.5
            
        end
        
    end
    
    // Commander ejection functionality
    function NS2Gamerules:CastVoteByPlayer( voteTechId, player )
    
        if voteTechId == kTechId.VoteConcedeRound then
        
            if self.timeSinceGameStateChanged > kMinTimeBeforeConcede and self:GetGameStarted() then
            
                local team = player:GetTeam()
                team:VoteToGiveUp(player)
                
            end
        
        elseif voteTechId == kTechId.VoteDownCommander1 or voteTechId == kTechId.VoteDownCommander2 or voteTechId == kTechId.VoteDownCommander3 then

            // Get the 1st, 2nd or 3rd commander by entity order (does this on client as well)    
            local playerIndex = (voteTechId - kTechId.VoteDownCommander1 + 1)        
            local commanders = GetEntitiesForTeam("Commander", player:GetTeamNumber())
            
            if playerIndex <= table.count(commanders) then
            
                local targetCommander = commanders[playerIndex]
                local team = player:GetTeam()
                
                if player and team.VoteToEjectCommander then
                    team:VoteToEjectCommander(player, targetCommander)
                end
                
            end
            
        end
        
    end

    function NS2Gamerules:OnMapPostLoad()

        Gamerules.OnMapPostLoad(self)
        
        // Now allow script actors to hook post load
        local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
        for index, scriptActor in ientitylist(allScriptActors) do
            scriptActor:OnMapPostLoad()
        end
        
    end

    function NS2Gamerules:UpdateToReadyRoom()

        local state = self:GetGameState()
        if(state == kGameState.Team1Won or state == kGameState.Team2Won or state == kGameState.Draw) then
        
            if self.timeSinceGameStateChanged >= kTimeToReadyRoom then
            
                // Force the commanders to logout before we spawn people
                // in the ready room
                self:LogoutCommanders()
        
                // Set all players to ready room team
                local function SetReadyRoomTeam(player)
                    player:SetCameraDistance(0)
                    self:JoinTeam(player, kTeamReadyRoom)
                end
                Server.ForAllPlayers(SetReadyRoomTeam)

                // Spawn them there and reset teams
                self:ResetGame()

            end
            
        end
        
    end
    
    function NS2Gamerules:UpdateMapCycle()
    
        if self.timeToCycleMap ~= nil and Shared.GetTime() >= self.timeToCycleMap then

            MapCycle_CycleMap()               
            self.timeToCycleMap = nil
            
        end
        
    end
    
    // Network variable type time has a maximum value it can contain, so reload the map if
    // the age exceeds the limit and no game is going on.
    local kMaxServerAgeBeforeMapChange = 36000
    local function ServerAgeCheck(self)
    
        if self.gameState ~= kGameState.Started and Shared.GetTime() > kMaxServerAgeBeforeMapChange then
            MapCycle_ChangeMap(Shared.GetMapName())
        end
        
    end
    
    local function UpdateAutoTeamBalance(self, dt)
    
        local wasDisabled = false
        
        // Check if auto-team balance should be enabled or disabled.
        local autoTeamBalance = Server.GetConfigSetting("auto_team_balance")
        if autoTeamBalance then
        
            local enabledOnUnbalanceAmount = autoTeamBalance.enabled_on_unbalance_amount or 2
            // Prevent the unbalance amount from being 0 or less.
            enabledOnUnbalanceAmount = enabledOnUnbalanceAmount > 0 and enabledOnUnbalanceAmount or 2
            local enabledAfterSeconds = autoTeamBalance.enabled_after_seconds or 10
            
            local team1Players = self.team1:GetNumPlayers()
            local team2Players = self.team2:GetNumPlayers()
            
            local unbalancedAmount = math.abs(team1Players - team2Players)
            if unbalancedAmount >= enabledOnUnbalanceAmount then
            
                if not self.autoTeamBalanceEnabled then
                
                    self.teamsUnbalancedTime = self.teamsUnbalancedTime or 0
                    self.teamsUnbalancedTime = self.teamsUnbalancedTime + dt
                    
                    if self.teamsUnbalancedTime >= enabledAfterSeconds then
                    
                        self.autoTeamBalanceEnabled = true
                        if team1Players > team2Players then
                            self.team1:SetAutoTeamBalanceEnabled(true, unbalancedAmount)
                        else
                            self.team2:SetAutoTeamBalanceEnabled(true, unbalancedAmount)
                        end
                        
                        SendTeamMessage(self.team1, kTeamMessageTypes.TeamsUnbalanced)
                        SendTeamMessage(self.team2, kTeamMessageTypes.TeamsUnbalanced)
                        Print("Auto-team balance enabled")
                        
                        TEST_EVENT("Auto-team balance enabled")
                        
                    end
                    
                end
                
            // The autobalance system itself has turned itself off.
            elseif self.autoTeamBalanceEnabled then
                wasDisabled = true
            end
            
        // The autobalance system was turned off by the admin.
        elseif self.autoTeamBalanceEnabled then
            wasDisabled = true
        end
        
        if wasDisabled then
        
            self.team1:SetAutoTeamBalanceEnabled(false)
            self.team2:SetAutoTeamBalanceEnabled(false)
            self.teamsUnbalancedTime = 0
            self.autoTeamBalanceEnabled = false
            SendTeamMessage(self.team1, kTeamMessageTypes.TeamsBalanced)
            SendTeamMessage(self.team2, kTeamMessageTypes.TeamsBalanced)
            Print("Auto-team balance disabled")
            
            TEST_EVENT("Auto-team balance disabled")
            
        end
        
    end
    
    local function CheckForNoCommander(self, onTeam, commanderType)

        self.noCommanderStartTime = self.noCommanderStartTime or { }
        
        if not self:GetGameStarted() then
            self.noCommanderStartTime[commanderType] = nil
        else
        
            local commanderExists = Shared.GetEntitiesWithClassname(commanderType):GetSize() ~= 0
            
            if commanderExists then
                self.noCommanderStartTime[commanderType] = nil
            elseif not self.noCommanderStartTime[commanderType] then
                self.noCommanderStartTime[commanderType] = Shared.GetTime()
            elseif Shared.GetTime() - self.noCommanderStartTime[commanderType] >= kSendNoCommanderMessageRate then
            
                self.noCommanderStartTime[commanderType] = nil
                SendTeamMessage(onTeam, kTeamMessageTypes.NoCommander)
                
            end
            
        end
        
    end
    
    local function KillEnemiesNearCommandStructureInPreGame(self, timePassed)
    
        if self:GetGameState() == kGameState.NotStarted then
        
            local commandStations = Shared.GetEntitiesWithClassname("CommandStructure")
            for _, ent in ientitylist(commandStations) do
            
                local enemyPlayers = GetEntitiesForTeam("Player", GetEnemyTeamNumber(ent:GetTeamNumber()))
                for e = 1, #enemyPlayers do
                
                    local enemy = enemyPlayers[e]
                    if enemy:GetDistance(ent) <= 5 then
                        enemy:TakeDamage(25 * timePassed, nil, nil, nil, nil, 0, 25 * timePassed, kDamageType.Normal)
                    end
                    
                end
                
            end
            
        end
        
    end
    
    function NS2Gamerules:OnUpdate(timePassed)
    
        PROFILE("NS2Gamerules:OnUpdate")
        
        GetEffectManager():OnUpdate(timePassed)
        
        if Server then

            self.lsNumMarinesLeft = self.team1:GetNumActivePlayers()

            if self:GetGameStarted() then
                self.lsSecsLeft = math.max(0.0, self.lsSecsLeft - timePassed)
            end
        
            if self.justCreated then
            
                if not self.gameStarted then
                    self:ResetGame()
                end
                
                self.justCreated = false
                
            end
            
            if self:GetMapLoaded() then
            
                self:CheckGameStart(timePassed)
                self:CheckGameEnd()
                
                //self:UpdatePregame(timePassed)
                self:UpdateToReadyRoom()
                self:UpdateMapCycle()
                ServerAgeCheck(self)
                UpdateAutoTeamBalance(self, timePassed)
                
                self.timeSinceGameStateChanged = self.timeSinceGameStateChanged + timePassed
                
                self.worldTeam:Update(timePassed)
                self.team1:Update(timePassed)
                self.team2:Update(timePassed)
                self.spectatorTeam:Update(timePassed)
                
                // Send scores every so often
                self:UpdateScores()
                self:UpdatePings()
                self:UpdateHealth()
                self:UpdateTechPoints()
                
                CheckForNoCommander(self, self.team1, "MarineCommander")
                CheckForNoCommander(self, self.team2, "AlienCommander")
                KillEnemiesNearCommandStructureInPreGame(self, timePassed)
                
            end

            self.sponitor:Update(timePassed)
            
        end

    end
    
    /**
     * Ends the current game
     */
    function NS2Gamerules:EndGame(winningTeam)
    
        if self:GetGameState() == kGameState.Started then
        
            if self.autoTeamBalanceEnabled then
                TEST_EVENT("Auto-team balance, game ended")
            end
            
            // Set losing team        
            local losingTeam = nil
            if winningTeam == self.team1 then
            
                self:SetGameState(kGameState.Team2Won)
                losingTeam = self.team2            
                PostGameViz("Alien win")
                
            else
            
                self:SetGameState(kGameState.Team1Won)
                losingTeam = self.team1            
                PostGameViz("Marine win")
                
            end
            
            winningTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = true }, true) end)
            losingTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = false }, true) end)
            self.spectatorTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = losingTeam:GetTeamType() == kAlienTeamType }, true) end)
            
            self.losingTeam = losingTeam
            
            self.team1:ClearRespawnQueue()
            self.team2:ClearRespawnQueue()
            
            // Automatically end any performance logging when the round has ended.
            Shared.ConsoleCommand("p_endlog")

            self.sponitor:OnEndMatch(winningTeam)

        end
        
    end
    
    function NS2Gamerules:DrawGame()

        if self:GetGameState() == kGameState.Started then
        
            self:SetGameState(kGameState.Draw)
            
            // Display "draw" message
            local drawMessage = "The game was a draw!"
            self.team1:BroadcastMessage(drawMessage)
            self.team2:BroadcastMessage(drawMessage)
            
            self.team1:ClearRespawnQueue()
            self.team2:ClearRespawnQueue()  
            
        end
        
    end

    function NS2Gamerules:GetTeam(teamNum)

        local team = nil    
        if(teamNum == kTeamReadyRoom) then
            team = self.worldTeam
        elseif(teamNum == kTeam1Index) then
            team = self.team1
        elseif(teamNum == kTeam2Index) then
            team = self.team2
        elseif(teamNum == kSpectatorIndex) then
            team = self.spectatorTeam
        end
        return team
        
    end

    function NS2Gamerules:GetRandomTeamNumber()

        // Return lesser of two teams, or random one if they are the same
        local team1Players = self.team1:GetNumPlayers()
        local team2Players = self.team2:GetNumPlayers()
        
        if team1Players < team2Players then
            return self.team1:GetTeamNumber()
        elseif team2Players < team1Players then
            return self.team2:GetTeamNumber()
        end
        
        return ConditionalValue(math.random() < .5, kTeam1Index, kTeam2Index)
        
    end
    
    -- No enforced balanced teams on join as the auto team balance system balances teams.
    function NS2Gamerules:GetCanJoinTeamNumber(teamNumber)
        if self.gameState ~= kGameState.NotStarted then
            return false
        end
        return true
    end
    
    function NS2Gamerules:GetCanSpawnImmediately()
        return not self:GetGameStarted() or Shared.GetCheatsEnabled() or (Shared.GetTime() < (self.gameStartTime + kFreeSpawnTime))
    end
    
    // Returns bool for success and bool if we've played in the game already.
    local function GetUserPlayedInGame(self, player)
    
        local success = false
        local played = false
        
        local owner = Server.GetOwner(player)
        if owner then
        
            local userId = tonumber(owner:GetUserId())
            
            // Could be invalid if we're still connecting to Steam
            played = table.find(self.userIdsInGame, userId) ~= nil
            success = true
            
        end
        
        return success, played
        
    end
    
    local function SetUserPlayedInGame(self, player)
    
        local owner = Server.GetOwner(player)
        if owner then
        
            local userId = tonumber(owner:GetUserId())
            
            // Could be invalid if we're still connecting to Steam.
            return table.insertunique(self.userIdsInGame, userId)
            
        end
        
        return false
        
    end
    
    /**
     * Returns two return codes: success and the player on the new team. This player could be a new
     * player (the default respawn type for that team) or it will be the original player if the team 
     * wasn't changed (false, original player returned). Pass force = true to make player change team 
     * no matter what and to respawn immediately.
     */
    function NS2Gamerules:JoinTeam(player, newTeamNumber, force)
    
        local success = false
        local oldPlayerWasSpectating = false
        if player then
        
            local ownerClient = Server.GetOwner(player)
            oldPlayerWasSpectating = ownerClient ~= nil and ownerClient:GetSpectatingPlayer() ~= nil
            
        end
        
        // Join new team
        if player and player:GetTeamNumber() ~= newTeamNumber or force then
        
            local team = self:GetTeam(newTeamNumber)
            local oldTeam = self:GetTeam(player:GetTeamNumber())
            
            // Remove the player from the old queue if they happen to be in one
            if oldTeam ~= nil then
                oldTeam:RemovePlayerFromRespawnQueue(player)
            end
            
            // Spawn immediately if going to ready room, game hasn't started, cheats on, or game started recently
            if newTeamNumber == kTeamReadyRoom then

                newPlayer = player:Replace(LSReadyRoomPlayer.kMapName, newTeamNumber)
                success = true
            
            elseif self:GetCanSpawnImmediately() or force then
                
                success, newPlayer = team:ReplaceRespawnPlayer(player, nil, nil)
                
                // newPlayer:OnInitialSpawn(team:GetSpawnPosition())
                
            else
            
                // Destroy the existing player and create a spectator in their place.
                newPlayer = player:Replace(team:GetSpectatorMapName(), newTeamNumber)
                
                // Queue up the spectator for respawn.
                team:PutPlayerInRespawnQueue(newPlayer)
                
                success = true
                
            end
            
            // Update frozen state of player based on the game state and player team.
            if team == self.team1 or team == self.team2 then
            
                local devMode = Shared.GetDevMode()
                local inCountdown = self:GetGameState() == kGameState.Countdown
                if not devMode and inCountdown then
                    newPlayer.frozen = true
                end
                
            else
            
                // Ready room or spectator players should never be frozen
                newPlayer.frozen = false
                
            end
            
            local newPlayerClient = Server.GetOwner(newPlayer)
            local clientUserId = newPlayerClient and newPlayerClient:GetUserId() or 0
            local disconnectedPlayerRes = self.disconnectedPlayerResources[clientUserId]
            if disconnectedPlayerRes then
            
                newPlayer:SetResources(disconnectedPlayerRes)
                self.disconnectedPlayerResources[clientUserId] = nil
                
            else
            
                // Give new players starting resources. Mark players as "having played" the game (so they don't get starting res if
                // they join a team again, etc.)
                local success, played = GetUserPlayedInGame(self, newPlayer)
                if success and not played then
                    newPlayer:SetResources(kPlayerInitialIndivRes)
                end
                
            end
            
            if self:GetGameStarted() then
                SetUserPlayedInGame(self, newPlayer)
            end
            
            newPlayer:TriggerEffects("join_team")
            
            if success then
            
                self.sponitor:OnJoinTeam(newPlayer, team)
                
                if oldPlayerWasSpectating then
                    newPlayerClient:SetSpectatingPlayer(nil)
                end
                
                Server.SendNetworkMessage(newPlayerClient, "SetClientTeamNumber", { teamNumber = newPlayer:GetTeamNumber() }, true)
                
            end

            return success, newPlayer
            
        end
        
        // Return old player
        return success, player
        
    end
    
    /* For test framework only. Prevents game from ending on its own also. */
    function NS2Gamerules:SetGameStarted()

        self:SetGameState(kGameState.Started)
        self.preventGameEnd = true
        
    end

    function NS2Gamerules:SetPreventGameEnd(state)
        self.preventGameEnd = state
    end
    
    function NS2Gamerules:CheckGameStart(dt)

        if self:GetGameState() == kGameState.NotStarted then

            self.lsReadySecsLeft = math.max( self.lsReadySecsLeft - dt, 0 )

            // LS logic: If there are no ready room players and at least one marine, start already!
            // Or, if ready time is up
            if self.team1:GetNumPlayers() > 0 and (
                    self.worldTeam:GetNumPlayers() == 0
                    or self.lsReadySecsLeft <= 0.0 )
            then
                self:SetGameState(kGameState.PreGame)
            end

        elseif self:GetGameState() == kGameState.PreGame then

            self.lsPreGameSecsLeft = math.max(self.lsPreGameSecsLeft - dt, 0)
        
            if self.lsPreGameSecsLeft <= 0 then
                self:SetGameState(kGameState.Started)
                self.preventGameEnd = true
            end

        end
        
    end
    
    function NS2Gamerules:CheckGameEnd()

        if self:GetGameStarted() then

            if not self.team1:GetHasActivePlayers() then

                // all marines gone, lose
                self:EndGame(self.team2)

            elseif self.lsSecsLeft <= 0.0 then

                // marines survived the time - win!
                self:EndGame(self.team1)

            end

        end
    
        /*
        if self:GetGameStarted() and self.timeGameEnded == nil and not Shared.GetCheatsEnabled() and not self.preventGameEnd then
        
            if self.timeLastGameEndCheck == nil or (Shared.GetTime() > self.timeLastGameEndCheck + kGameEndCheckInterval) then
            
                local team1Lost = self.team1:GetHasTeamLost()
                local team2Lost = self.team2:GetHasTeamLost()
                local team1Won = self.team1:GetHasTeamWon()
                local team2Won = self.team2:GetHasTeamWon()
                
                local team1Players = self.team1:GetNumPlayers()
                local team2Players = self.team2:GetNumPlayers()
                local totalCount = team1Players + team2Players
                
                // This is an optional end condition based on the teams being unbalanced.
                local endGameOnUnbalancedAmount = Server.GetConfigSetting("end_round_on_team_unbalance")
                // Don't consider unbalanced game end until enough people are playing.
                if totalCount > 6 and endGameOnUnbalancedAmount and endGameOnUnbalancedAmount ~= 0 then
                
                    if (1 - (team1Players / team2Players)) >= endGameOnUnbalancedAmount then
                        team1Lost = true
                    elseif (1 - (team2Players / team1Players)) >= endGameOnUnbalancedAmount then
                        team2Lost = true
                    end
                    
                end
                
                if (team1Lost and team2Lost) or (team1Won and team2Won) then
                    self:DrawGame()
                elseif team1Lost or team2Won then
                    self:EndGame(self.team2)
                elseif team2Lost or team1Won then
                    self:EndGame(self.team1)
                end
                
                self.timeLastGameEndCheck = Shared.GetTime()
                
            end
            
        end
        */
        
    end
    
    function NS2Gamerules:GetCountingDown()
        return self:GetGameState() == kGameState.Countdown
    end
    
    local function ResetPlayerScores()
    
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do            
            if player.ResetScores then
                player:ResetScores()
            end            
        end
    
    end
    
    local function StartCountdown(self)
    
        self:ResetGame()
        
        self:SetGameState(kGameState.Countdown)
        ResetPlayerScores()
        self.countdownTime = kCountDownLength
        
        self.lastCountdownPlayed = nil
        
    end
    
    function NS2Gamerules:GetPregameLength()
    
        local preGameTime = kPreGameLength
        if Shared.GetCheatsEnabled() then
            preGameTime = 0
        end
        
        return preGameTime
        
    end
    
    function NS2Gamerules:UpdatePregame(timePassed)

    /*
        if self:GetGameState() == kGameState.PreGame then
        
            local preGameTime = self:GetPregameLength()
            
            if self.timeSinceGameStateChanged > preGameTime then
            
                StartCountdown(self)
                if Shared.GetCheatsEnabled() then
                    self.countdownTime = 1
                end
                
            end
            
        elseif self:GetGameState() == kGameState.Countdown then
        
            self.countdownTime = self.countdownTime - timePassed
            
            // Play count down sounds for last few seconds of count-down
            local countDownSeconds = math.ceil(self.countdownTime)
            if self.lastCountdownPlayed ~= countDownSeconds and (countDownSeconds < 4) then
            
                self.worldTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.spectatorTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                
                self.lastCountdownPlayed = countDownSeconds
                
            end
            
            if self.countdownTime <= 0 then
            
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                
                self:SetGameState(kGameState.Started)
                self.sponitor:OnStartMatch()
            end
            
        end
        */
        
    end

    function NS2Gamerules:GetLosingTeam()
        return self.losingTeam
    end

    function NS2Gamerules:GetAllTech()
        return self.allTech
    end

    function NS2Gamerules:SetAllTech(state)

        if state ~= self.allTech then
        
            self.allTech = state
            
            self.team1:GetTechTree():SetTechChanged()
            self.team2:GetTechTree():SetTechChanged()
            
        end
        
    end

    function NS2Gamerules:GetAutobuild()
        return self.autobuild
    end

    function NS2Gamerules:SetAutobuild(state)
        self.autobuild = state
    end

    function NS2Gamerules:SetOrderSelf(state)
        self.orderSelf = state
    end

    function NS2Gamerules:GetOrderSelf()
        return self.orderSelf
    end

    function NS2Gamerules:GetIsPlayerFollowingTeamNumber(player, teamNumber)

        local following = false
        
        if player:isa("Spectator") then
        
            local playerId = player:GetFollowingPlayerId()
            
            if playerId ~= Entity.invalidId then
            
                local followedPlayer = Shared.GetEntity(playerId)
                
                if followedPlayer and followedPlayer:GetTeamNumber() == teamNumber then
                
                    following = true
                    
                end
                
            end

        end
        
        return following

    end

    // Function for allowing teams to hear each other's voice chat
    function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer)

        local canHear = false
        
        // Check if the listerner has the speaker muted.
        if listenerPlayer:GetClientMuted(speakerPlayer:GetClientIndex()) then
            return false
        end
        
        // If both players have the same team number, they can hear each other
        if(listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()) then
            canHear = true
        end
            
        // Or if cheats or dev mode is on, they can hear each other
        if(Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
            canHear = true
        end
        
        // NOTE: SCRIPT ERROR CAUSED IN THIS FUNCTION WHEN FP SPEC WAS ADDED.
        // This functionality never really worked anyway.
        // If we're spectating a player, we can hear their team (but not in tournamentmode, once that's in)
        //if self:GetIsPlayerFollowingTeamNumber(listenerPlayer, speakerPlayer:GetTeamNumber()) then
        //    canHear = true
        //end
        
        return canHear
        
    end

    function NS2Gamerules:RespawnPlayer(player)

        local team = player:GetTeam()
        team:RespawnPlayer(player, nil, nil)
        
    end

    // Add SteamId of player to list of players that can't command again until next game
    function NS2Gamerules:BanPlayerFromCommand(playerId)
        ASSERT(type(playerId) == "number")
        table.insertunique(self.bannedPlayers, playerId)
    end

    function NS2Gamerules:GetPlayerBannedFromCommand(playerId)
        ASSERT(type(playerId) == "number")
        return (table.find(self.bannedPlayers, playerId) ~= nil)
    end

    function NS2Gamerules:GetNumMarinePlayers()
        return self.team1:GetNumPlayers()
    end

    function NS2Gamerules:GetRoundFraction()
        return 1.0 - self.lsSecsLeft / gRoundSecs
    end

    Event.Hook("Console_ls_length", function(client, arg)
                local t = tonumber(arg)
                Print("TWEAK Setting round length to %0.2fs", t)
                gRoundSecs = t
            end)

    Event.Hook("Console_ls_fraction", function(client)
            Print("round fraction = %f", GetGamerules():GetRoundFraction())
            end)


////////////////    
// End Server //
////////////////

end

if Client or Predict then

    gGameRules = nil

    function GetGamerules()
        return gGameRules
    end

    function NS2Gamerules:OnCreate()
        gGameRules = self
        self.roundEndMusicPlayed = false
        self:SetUpdates(true)
    end
    
    function NS2Gamerules:OnUpdate(dt)
        if self.gameState == kGameState.Started then
            if self.lsSecsLeft < 32.5 and not self.roundEndMusicPlayed then
                Shared.PlaySound(nil, kCommonGameSounds.RoundEndMusic)  
                self.roundEndMusicPlayed = true
                self.stopMusicTimer = 2
            end        
        else
            if self.roundEndMusicPlayed then
                self.stopMusicTimer = self.stopMusicTimer - dt
                if self.stopMusicTimer <= 0 then                    
                    Shared.StopSound(nil, kCommonGameSounds.RoundEndMusic)
                    self.roundEndMusicPlayed = false
                end    
            end
        end
    end

end

function NS2Gamerules:GetRoundSecsLeft()
    return self.lsSecsLeft
end

function NS2Gamerules:GetNumMarinesLeft()
    return self.lsNumMarinesLeft
end

function NS2Gamerules:GetGameStartTime()
    return ConditionalValue(self:GetGameStarted(), self.gameStartTime, 0)
end

function NS2Gamerules:GetGameStarted()
    return self.gameState == kGameState.Started
end

// TODO misnomer. should be, MarinesCanDoStuff
function NS2Gamerules:GetIsMarinePrepTime()
    return self.gameState == kGameState.Started or self.gameState == kGameState.PreGame
end


Shared.LinkClassToMap("NS2Gamerules", NS2Gamerules.kMapName, networkVars )
