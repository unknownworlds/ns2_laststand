//=============================================================================
//
// lua/ServerBrowser.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2012, Unknown Worlds Entertainment
//
//=============================================================================

Script.Load("lua/Utility.lua")

local kFavoritesFileName = "FavoriteServers.json"

local kFavoriteAddedSound = "sound/NS2.fev/common/checkbox_on"
Client.PrecacheLocalSound(kFavoriteAddedSound)

local kFavoriteRemovedSound = "sound/NS2.fev/common/checkbox_off"
Client.PrecacheLocalSound(kFavoriteRemovedSound)

local function SetLastServerInfo(address, password, mapname)

	Client.SetOptionString(kLastServerConnected, address)
	Client.SetOptionString(kLastServerPassword, password)
	Client.SetOptionString(kLastServerMapName, GetTrimmedMapName(mapname))
	
end

local function GetLastServerInfo()

	local address = Client.GetOptionString(kLastServerConnected, "")
	local password = Client.GetOptionString(kLastServerPassword, "")
	local mapname = Client.GetOptionString(kLastServerMapName, "")
	
	return address, password, mapname
	
end

/**
 * Join the server specified by UID and password.
 * If password is empty string there is no password.
 */
function MainMenu_SBJoinServer(address, password, mapname)

    Client.Disconnect()
    LeaveMenu()
    if password == nil then
        password = ""
    end
    Client.Connect(address, password)
    
    SetLastServerInfo(address, password, mapname)
    
    local params = { steamID = "" .. Client.GetSteamId() }
    Shared.SendHTTPRequest(kCatalyzURL .. "/deregister", "GET", params)
    
end

function OnRetryCommand()

    local address, password, mapname = GetLastServerInfo()
    
    if address == nil or address == "" then
    
        Shared.Message("No valid server to connect to.")
        return
        
    end
    
    Client.Disconnect()
    LeaveMenu()
    Shared.Message("Reconnecting to " .. address)
    MainMenu_SBJoinServer(address, password, mapname)
    
end
Event.Hook("Console_retry", OnRetryCommand)
Event.Hook("Console_reconnect", OnRetryCommand)

local gFavoriteServers = LoadConfigFile(kFavoritesFileName) or { }

local function UpgradeFavoriteServersFormat(favorites)

    local newFavorites = favorites
    // The old format stored a list of addresses as strings.
    if type(favorites[1]) == "string" then
    
        // The new format stores a list of server entries as tables.
        newFavorites = { }
        for f = 1, #favorites do
            table.insert(newFavorites, { address = favorites[f] })
        end
        
        SaveConfigFile(kFavoritesFileName, newFavorites)
        
    end
    
    return newFavorites
    
end
gFavoriteServers = UpgradeFavoriteServersFormat(gFavoriteServers)

// Remove any entries lacking a server address. These are bogus entries.
for f = #gFavoriteServers, 1, -1 do

    if not gFavoriteServers[f].address then
        table.remove(gFavoriteServers, f)
    end
    
end

function SetServerIsFavorite(serverData, isFavorite)

    local foundIndex = nil
    for f = 1, #gFavoriteServers do
    
        if gFavoriteServers[f].address == serverData.address then
        
            foundIndex = f
            break
            
        end
        
    end
    
    if isFavorite and not foundIndex then
    
        local savedServerData = { }
        for k, v in pairs(serverData) do savedServerData[k] = v end
        table.insert(gFavoriteServers, savedServerData)
        StartSoundEffect(kFavoriteAddedSound)
        
    elseif foundIndex then
    
        table.remove(gFavoriteServers, foundIndex)
        StartSoundEffect(kFavoriteRemovedSound)
        
    end
    
    SaveConfigFile(kFavoritesFileName, gFavoriteServers)
    
end

function GetServerIsFavorite(address)

    for f = 1, #gFavoriteServers do
    
        if gFavoriteServers[f].address == address then
            return true
        end
        
    end
    
    return false
    
end

function UpdateFavoriteServerData(serverData)

    for f = 1, #gFavoriteServers do
    
        if gFavoriteServers[f].address == serverData.address then
        
            for k, v in pairs(serverData) do gFavoriteServers[f][k] = v end
            break
            
        end
        
    end
    
end

function GetFavoriteServers()
    return gFavoriteServers
end