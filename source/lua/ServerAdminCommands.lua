// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\ServerAdminCommands.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Console commands to be used in ServerAdmin.lua system.
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

Script.Load("lua/ConfigFileUtility.lua")

function GetReadableSteamId(steamIdNumber)
    return "STEAM_0:" .. (steamIdNumber % 2) .. ":" .. math.floor(steamIdNumber / 2)
end

local function GetPlayerList()

    local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
    table.sort(playerList, function(p1, p2) return p1:GetName() < p2:GetName() end)
    return playerList
    
end

/**
 * Iterates over all players sorted in alphabetically calling the passed in function.
 */
local function AllPlayers(doThis)

    return function(client)
    
        local playerList = GetPlayerList()
        for p = 1, #playerList do
        
            local player = playerList[p]
            doThis(player, client, p)
            
        end
        
    end
    
end

local function GetPlayerMatchingSteamId(steamId)

    local match = nil
    
    local function Matches(player)
    
        local playerClient = Server.GetOwner(player)
        if playerClient and playerClient:GetUserId() == tonumber(steamId) or GetReadableSteamId(playerClient:GetUserId()) == steamId then
            match = player
        end
        
    end
    AllPlayers(Matches)()
    
    return match
    
end

local function GetPlayerMatchingName(name)

    local match = nil
    
    local function Matches(player)
    
        if player:GetName() == name then
            match = player
        end
        
    end
    AllPlayers(Matches)()
    
    return match
    
end

local function GetPlayerMatching(id)
    return GetPlayerMatchingSteamId(id) or GetPlayerMatchingName(id)
end

local function PrintStatus(player, client, index)

    local playerClient = Server.GetOwner(player)
    // The player may not have an owner. Ragdoll player entities for example.
    if playerClient then
    
        local playerId = playerClient:GetUserId()
        ServerAdminPrint(client, player:GetName() .. " : Steam Id = " .. playerId .. " : " .. GetReadableSteamId(playerId))
        
    end
    
end
CreateServerAdminCommand("Console_sv_status", AllPlayers(PrintStatus), "Lists player Ids and names for use in sv commands", true)

local function PrintStatusIP(player, client, index)

    local playerClient = Server.GetOwner(player)
    // The player may not have an owner. Ragdoll player entities for example.
    if playerClient then
    
        local playerAddressString = IPAddressToString(Server.GetClientAddress(playerClient))
        local playerId = playerClient:GetUserId()
        ServerAdminPrint(client, player:GetName() .. " : Steam Id = " .. playerId .. " : " .. GetReadableSteamId(playerId) .. " : Address = " .. playerAddressString)
        
    end
    
end
CreateServerAdminCommand("Console_sv_statusip", AllPlayers(PrintStatusIP), "Lists player Ids and names for use in sv commands")

CreateServerAdminCommand("Console_sv_changemap", function(_, mapName) MapCycle_ChangeMap( mapName ) end, "<map name>, Switches to the map specified")
CreateServerAdminCommand("Console_sv_reset", function() GetGamerules():ResetGame() end, "Resets the game round")

CreateServerAdminCommand("Console_sv_rrall", AllPlayers(function(player) GetGamerules():JoinTeam(player, kTeamReadyRoom) end), "Forces all players to go to the Ready Room")
CreateServerAdminCommand("Console_sv_randomall", AllPlayers(function(player) JoinRandomTeam(player) end), "Forces all players to join a random team")

local function SwitchTeam(client, playerId, team)

    local player = GetPlayerMatching(playerId)
    local teamNumber = tonumber(team)
    
    if type(teamNumber) ~= "number" or teamNumber < 0 or teamNumber > 3 then
    
        ServerAdminPrint(client, "Invalid team number")
        return
        
    end
    
    if player and teamNumber ~= player:GetTeamNumber() then
        GetGamerules():JoinTeam(player, teamNumber)
    elseif not player then
        ServerAdminPrint(client, "No player matches Id: " .. playerId)
    end
    
end
CreateServerAdminCommand("Console_sv_switchteam", SwitchTeam, "<player id> <team number>, 1 is Marine, 2 is Alien")

local function Eject(client, playerId)

    local player = GetPlayerMatching(playerId)
    if player and player:isa("Commander") then
        player:Eject()
    else
        ServerAdminPrint(client, "Invalid player")
    end
    
end
CreateServerAdminCommand("Console_sv_eject", Eject, "<player id>, Ejects Commander from the Command Structure")

local function Kick(client, playerId)

    local player = GetPlayerMatching(playerId)
    if player then
        Server.DisconnectClient(Server.GetOwner(player))
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_kick", Kick, "<player id>, Kicks the player from the server")

local function GetChatMessage(...)

    local chatMessage = StringConcatArgs(...)
    if chatMessage then
        return string.sub(chatMessage, 1, kMaxChatLength)
    end
    
    return ""
    
end

local function Say(client, ...)

    local chatMessage = GetChatMessage(...)
    if string.len(chatMessage) > 0 then
    
        Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
        Shared.Message("Chat All - Admin: " .. chatMessage)
        Server.AddChatToHistory(chatMessage, "Admin", 0, kTeamReadyRoom, false)
        
    end
    
end
CreateServerAdminCommand("Console_sv_say", Say, "<message>, Sends a message to every player on the server")

local function TeamSay(client, team, ...)

    local teamNumber = tonumber(team)
    if type(teamNumber) ~= "number" or teamNumber < 0 or teamNumber > 3 then
    
        ServerAdminPrint(client, "Invalid team number")
        return
        
    end
    
    local chatMessage = GetChatMessage(...)
    if string.len(chatMessage) > 0 then
    
        local players = GetEntitiesForTeam("Player", teamNumber)
        for index, player in ipairs(players) do
            Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "Team - Admin", -1, teamNumber, kNeutralTeamType, chatMessage), true)
        end
        
        Shared.Message("Chat Team - Admin: " .. chatMessage)
        Server.AddChatToHistory(chatMessage, "Admin", 0, teamNumber, true)
        
    end
    
end
CreateServerAdminCommand("Console_sv_tsay", TeamSay, "<team number> <message>, Sends a message to one team")

local function PlayerSay(client, playerId, ...)

    local chatMessage = GetChatMessage(...)
    local player = GetPlayerMatching(playerId)
    
    if player then
    
        chatMessage = string.sub(chatMessage, 1, kMaxChatLength)
        if string.len(chatMessage) > 0 then
        
            Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, teamNumber, kNeutralTeamType, chatMessage), true)
            Shared.Message("Chat Player - Admin: " .. chatMessage)
            
        end
        
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_psay", PlayerSay, "<player id> <message>, Sends a message to a single player")

local function Slay(client, playerId)

    local player = GetPlayerMatching(playerId)
    
    if player then
         player:Kill(nil, nil, player:GetOrigin())
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_slay", Slay, "<player id>, Kills player")

local function SetPassword(client, newPassword)
    Server.SetPassword(newPassword or "")
end
CreateServerAdminCommand("Console_sv_password", SetPassword, "<string>, Changes the password on the server")

local function SetCheats(client, enabled)
    Shared.ConsoleCommand("cheats " .. ((enabled == "true" or enabled == "1") and "1" or "0"))
end
CreateServerAdminCommand("Console_sv_cheats", SetCheats, "<boolean>, Turns cheats on and off")

local bannedPlayersFileName = "BannedPlayers.json"
local bannedPlayers = LoadConfigFile(bannedPlayersFileName) or { }

local function SaveBannedPlayers()
    SaveConfigFile(bannedPlayersFileName, bannedPlayers)
end

local function OnConnectCheckBan(client)

    local steamid = client:GetUserId()
    for b = #bannedPlayers, 1, -1 do
    
        local ban = bannedPlayers[b]
        if ban.id == steamid then
        
            // Check if enough time has passed on a temporary ban.
            local now = Shared.GetSystemTime()
            if ban.time == 0 or now < ban.time then
            
                Server.DisconnectClient(client)
                break
                
            else
            
                // No longer banned.
                table.remove(bannedPlayers, b)
                SaveBannedPlayers()
                
            end
            
        end
        
    end
    
end
Event.Hook("ClientConnect", OnConnectCheckBan)

/**
 * Duration is specified in minutes. Pass in 0 or nil to ban forever.
 * A reason string may optionally be provided.
 */
local function Ban(client, playerId, duration, ...)

    local player = GetPlayerMatching(playerId)
    local bannedUntilTime = Shared.GetSystemTime()
    duration = tonumber(duration)
    if duration == nil or duration <= 0 then
        bannedUntilTime = 0
    else
        bannedUntilTime = bannedUntilTime + (duration * 60)
    end
    
    local playerIdNum = tonumber(playerId)
    if player then
    
        table.insert(bannedPlayers, { name = player:GetName(), id = Server.GetOwner(player):GetUserId(), reason = StringConcatArgs(...), time = bannedUntilTime })
        SaveBannedPlayers()
        ServerAdminPrint(client, player:GetName() .. " has been banned")
        Server.DisconnectClient(Server.GetOwner(player))
        
    elseif playerIdNum and playerIdNum > 0 then
    
        table.insert(bannedPlayers, { name = "Unknown", id = playerIdNum, reason = StringConcatArgs(...) or "None provided", time = bannedUntilTime })
        SaveBannedPlayers()
        ServerAdminPrint(client, "Player with SteamId " .. playerIdNum .. " has been banned")
        
    else
        ServerAdminPrint(client, "No matching player")
    end
    
end
CreateServerAdminCommand("Console_sv_ban", Ban, "<player id> <duration in minutes> <reason text>, Bans the player from the server, pass in 0 for duration to ban forever")

local function UnBan(client, steamId)

    local found = false
    for p = #bannedPlayers, 1, -1 do
    
        if bannedPlayers[p].id == tonumber(steamId) then
        
            table.remove(bannedPlayers, p)
            ServerAdminPrint(client, "Removed " .. steamId .. " from the ban list")
            found = true
            
        end
        
    end
    
    if found then
        SaveBannedPlayers()
    else
        ServerAdminPrint(client, "No matching Steam Id in ban list: " .. steamId)
    end
    
end
CreateServerAdminCommand("Console_sv_unban", UnBan, "<steam id>, Removes the player matching the passed in Steam Id from the ban list")

function GetBannedPlayersList()

    local returnList = { }
    
    for p = 1, #bannedPlayers do
    
        local ban = bannedPlayers[p]
        table.insert(returnList, { name = ban.name, id = ban.id, reason = ban.reason, time = ban.time })
        
    end
    
    return returnList
    
end

local function ListBans(client)

    if #bannedPlayers == 0 then
        ServerAdminPrint(client, "No players are currently banned")
    end
    
    for p = 1, #bannedPlayers do
    
        local ban = bannedPlayers[p]
        local timeLeft = ban.time == 0 and "Forever" or (((ban.time - Shared.GetSystemTime()) / 60) .. " minutes")
        ServerAdminPrint(client, "Name: " .. ban.name .. " Id: " .. ban.id .. " Time Remaining: " .. timeLeft .. " Reason: " .. (ban.reason or "Not provided"))
        
    end
    
end
CreateServerAdminCommand("Console_sv_listbans", ListBans, "Lists the banned players")

local function PLogAll(client)

    Shared.ConsoleCommand("p_logall")
    ServerAdminPrint(client, "Performance logging enabled")
    
end
CreateServerAdminCommand("Console_sv_p_logall", PLogAll, "Starts performance logging")

local function PEndLog(client)

    Shared.ConsoleCommand("p_endlog")
    ServerAdminPrint(client, "Performance logging disabled")
    
end
CreateServerAdminCommand("Console_sv_p_endlog", PEndLog, "Ends performance logging")

local function AutoBalance(client, enabled, playerCount, seconds)

    if enabled == "true" then
    
        playerCount = playerCount and tonumber(playerCount) or 2
        seconds = seconds and tonumber(seconds) or 10
        Server.SetConfigSetting("auto_team_balance", { enabled_on_unbalance_amount = playerCount, enabled_after_seconds = seconds })
        ServerAdminPrint(client, "Auto Team Balance is now Enabled. Player unbalance amount: " .. playerCount .. " Activate delay: " .. seconds)
        
    else
    
        Server.SetConfigSetting("auto_team_balance", nil)
        ServerAdminPrint(client, "Auto Team Balance is now Disabled")
        
    end
    
end
CreateServerAdminCommand("Console_sv_autobalance", AutoBalance, "<true/false> <player count> <seconds>, Toggles auto team balance. The player count and seconds are optional. Count defaults to 2 over balance to enable. Defaults to 10 second wait to enable.")

local function AutoKickAFK(client, time, capacity)

    time = tonumber(time) or 300
    capacity = tonumber(capacity) or 0.5
    Server.SetConfigSetting("auto_kick_afk_time", time)
    Server.SetConfigSetting("auto_kick_afk_capacity", capacity)
    ServerAdminPrint(client, "Auto-kick AFK players is " .. (time <= 0 and "disabled" or "enabled") .. ". Kick after: " .. math.floor(time) .. " seconds when server is at: " .. math.floor(capacity * 100) .. "% capacity")
    
end
CreateServerAdminCommand("Console_sv_auto_kick_afk", AutoKickAFK, "<seconds> <number>, Auto-kick is disabled when the first argument is 0. A player will be kicked only when the server is at the defined capacity (0-1).")

local function EnableEventTesting(client, enabled)

    enabled = not (enabled == "false")
    SetEventTestingEnabled(enabled)
    ServerAdminPrint(client, "Event testing " .. (enabled and "enabled" or "disabled"))
    
end
CreateServerAdminCommand("Console_sv_test_events", EnableEventTesting, "<true/false>, Toggles event testing mode")