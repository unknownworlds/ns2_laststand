//=============================================================================
//
// lua/Scoreboard.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
Script.Load("lua/Insight.lua")

local playerData = { }

function Insight_SetPlayerHealth(clientIndex, health, maxHealth, armor, maxArmor)
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        if playerRecord.ClientIndex == clientIndex then
            playerRecord.Health = health
            playerRecord.MaxHealth = maxHealth
            playerRecord.Armor = armor
            playerRecord.MaxArmor = maxArmor
        end
        
    end
    
end

function Scoreboard_Clear()

    playerData = { }
    Insight_Clear()
    
end

// Score > Kills > Deaths > Resources
function Scoreboard_Sort()

    function sortByScore(player1, player2)
    
        if player1.Score == player2.Score then
        
            if player1.Kills == player2.Kills then
            
                if player1.Deaths == player2.Deaths then    
                
                    if player1.Resources == player2.Resources then    
                    
                        // Somewhat arbitrary but keeps more coherence and adds players to bottom in case of ties
                        return player1.ClientIndex > player2.ClientIndex
                        
                    else
                        return player1.Resources > player2.Resources
                    end
                    
                else
                    return player1.Deaths < player2.Deaths
                end
                
            else
                return player1.Kills > player2.Kills
            end
            
        else
            return player1.Score > player2.Score    
        end        
        
    end
    
    // Sort it by entity id
    table.sort(playerData, sortByScore)

end

// Hooks from console commands coming from server
function Scoreboard_OnResetGame()

    // For each player, clear game data (on reset)
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        playerRecord.EntityId = 0
        playerRecord.EntityTeamNumber = 0
        playerRecord.Score = 0
        playerRecord.Kills = 0
        playerRecord.Deaths = 0
        playerRecord.IsCommander = false
        playerRecord.IsRookie = false
        playerRecord.Resources = 0
        playerRecord.Status = ""
        playerRecord.IsSpectator = false
        
    end 

end

function Scoreboard_OnClientDisconnect(clientIndex)

    table.removeConditional(  playerData, function (element) return element.ClientIndex == clientIndex end )
    return true
    
end

function Scoreboard_SetPlayerData(clientIndex, entityId, playerName, teamNumber, score, kills, deaths, resources, isCommander, isRookie, status, isSpectator)

    // Lookup record for player and update it
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.ClientIndex == clientIndex then

            // Update entry
            playerRecord.EntityId = entityId
            playerRecord.Name = playerName
            playerRecord.EntityTeamNumber = teamNumber
            playerRecord.Score = score
            playerRecord.Kills = kills
            playerRecord.Deaths = deaths
            playerRecord.IsCommander = isCommander
            playerRecord.IsRookie = isRookie
            playerRecord.Resources = resources
            playerRecord.Status = status
            playerRecord.IsSpectator = isSpectator
            
            Scoreboard_Sort()
            
            return
            
        end
        
    end
        
    // Otherwise insert a new record
    local playerRecord = {}
    playerRecord.ClientIndex = clientIndex
    playerRecord.EntityId = entityId
    playerRecord.Name = playerName
    playerRecord.EntityTeamNumber = teamNumber
    playerRecord.Score = score
    playerRecord.Kills = kills
    playerRecord.Deaths = deaths
    playerRecord.IsCommander = isCommander
    playerRecord.IsRookie = isRookie
    playerRecord.Resources = 0
    playerRecord.Ping = 0
    playerRecord.Status = status
    playerRecord.IsSpectator = isSpectator
    
    table.insert(playerData, playerRecord )
    
    Scoreboard_Sort()
    
end

function Scoreboard_SetPing(clientIndex, ping)

    local setPing = false
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        if playerRecord.ClientIndex == clientIndex then
            playerRecord.Ping = ping
            setPing = true
        end
        
    end
    
end

function Scoreboard_SetRookieMode(playerName, rookieMode)

    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.Name == playerName then
            playerRecord.IsRookie = rookieMode
        end
        
    end
    
end

// Set local data for player so scoreboard updates instantly
function Scoreboard_SetLocalPlayerData(playerName, index, data)
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.Name == playerName then
        
            playerRecord[index] = data

            break
            
        end
        
    end
    
end

function Scoreboard_GetPlayerRecord(clientIndex)

    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.ClientIndex == clientIndex then

            return playerRecord
            
        end

    end
    
    return nil
    
end

function Scoreboard_GetPlayerData(clientIndex, dataType)

    local playerRecord = Scoreboard_GetPlayerRecord(clientIndex)
    
    if playerRecord then
    
        return playerRecord[dataType]
        
    end
    
    return nil    
    
end

/**
 * Get table of scoreboard player recrods for all players with team numbers in specified table.
 */
function GetScoreData(teamNumberTable)

    local scoreData = { }
    local commanders = { }
    
    for index, playerRecord in ipairs(playerData) do
        if table.find(teamNumberTable, playerRecord.EntityTeamNumber) then
        
            if not playerRecord.IsCommander then
                table.insert(scoreData, playerRecord)
            else
                table.insert(commanders, playerRecord)
            end    
                
        end
    end
    
    for _, commander in ipairs(commanders) do
        table.insert(scoreData, 1, commander)
    end
    
    return scoreData
    
end

/**
 * Get score data for the blue team
 */
function ScoreboardUI_GetBlueScores()
    return GetScoreData({ kTeam1Index })
end

/**
 * Get score data for the red team
 */
function ScoreboardUI_GetRedScores()
    return GetScoreData({ kTeam2Index })
end

/**
 * Get score data for everyone not playing.
 */
function ScoreboardUI_GetSpectatorScores()
    return GetScoreData({ kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetAllScores()
    return GetScoreData({ kTeam1Index, kTeam2Index, kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetTeamResources(teamNumber)

    local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
    if table.count(teamInfo) > 0 then
        return teamInfo[1]:GetTeamResources()
    end
    
    return 0

end

/**
 * Get the name of the blue team
 */
function ScoreboardUI_GetBlueTeamName()
    return kTeam1Name
end

/**
 * Get the name of the red team
 */
function ScoreboardUI_GetRedTeamName()
    return kTeam2Name
end

/**
 * Get the name of the spectator team
 */
function ScoreboardUI_GetSpectatorTeamName()
    return kSpectatorTeamName
end

/**
 * Return true if playerName is a local player.
 */
function ScoreboardUI_IsPlayerLocal(playerName)
    
    local player = Client.GetLocalPlayer()
    
    // Get entry with this name and check entity id
    if player then
    
        for i = 1, table.maxn(playerData) do

            local playerRecord = playerData[i]        
            if playerRecord.Name == playerName then

                return (player:GetClientIndex() == playerRecord.ClientIndex)
                
            end
            
        end    
        
    end
    
    return false
    
end

function ScoreboardUI_IsPlayerCommander(playerName)

    for i = 1, table.maxn(playerData) do

        local playerRecord = playerData[i]        
        if playerRecord.Name == playerName then
            return playerRecord.IsCommander            
        end
        
    end  
    
    return false
    
end

function ScoreboardUI_IsPlayerRookie(playerName)

    for i = 1, table.maxn(playerData) do

        local playerRecord = playerData[i]        
        if playerRecord.Name == playerName then
            return playerRecord.IsRookie
        end
        
    end  
    
    return false
    
end

function ScoreboardUI_GetDrawRookie(playerName, forPlayer)

    for i = 1, table.maxn(playerData) do

        local playerRecord = playerData[i]        
        if playerRecord.Name == playerName then
            return playerRecord.IsRookie and ((forPlayer:GetTeamNumber() == playerRecord.EntityTeamNumber) or (forPlayer:GetTeamNumber() == kSpectatorIndex))
        end
        
    end  
    
    return false
    
end

function ScoreboardUI_GetTeamHasCommander(teamNumber)

    for i = 1, #playerData do
    
        local playerRecord = playerData[i]
        if playerRecord.EntityTeamNumber == teamNumber and playerRecord.IsCommander then
            return true
        end
        
    end
    
    return false
    
end

function ScoreboardUI_GetCommanderName(teamNumber)

    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if (playerRecord.EntityTeamNumber == teamNumber) and playerRecord.IsCommander then
            return playerRecord.Name
        end
        
    end
    
    return nil
    
end

function ScoreboardUI_GetOrderedCommanderNames(teamNumber)

    local commanders = {}
    
    // Create table of commander entity ids and names
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if (playerRecord.EntityTeamNumber == teamNumber) and playerRecord.IsCommander then
            table.insert( commanders, {playerRecord.EntityId, playerRecord.Name} )
        end
        
    end
    
    function sortCommandersByEntity(pair1, pair2)
        return pair1[1] < pair2[1]
    end
    
    // Sort it by entity id
    table.sort(commanders, sortCommandersByEntity)
    
    // Return names in order
    local commanderNames = {}
    for index, pair in ipairs(commanders) do
        table.insert(commanderNames, pair[2])
    end
    
    return commanderNames
    
end

function ScoreboardUI_GetNumberOfAliensByType(alienType)

    local numberOfAliens = 0
    
    for index, playerRecord in ipairs(playerData) do
        if alienType == playerRecord.Status then
            numberOfAliens = numberOfAliens + 1
        end
    end
    
    return numberOfAliens

end