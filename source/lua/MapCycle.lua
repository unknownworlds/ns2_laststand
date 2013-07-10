// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// core/MapCycle.lua
//
// Created by Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ConfigFileUtility.lua")

local mapCycleFileName = "MapCycle.json"

local defaultConfig = { maps = { "ns2_docking", "ns2_mineshaft", "ns2_refinery", "ns2_summit", "ns2_tram", "ns2_veil" }, time = 30, mode = "order" }
WriteDefaultConfigFile(mapCycleFileName, defaultConfig)

local cycle = LoadConfigFile(mapCycleFileName) or defaultConfig

if type(cycle.time) ~= "number" then
    Shared.Message("No cycle time defined in MapCycle.json")
end

if type(cycle.maps) ~= "table" then
    Shared.Message("No maps defined in MapCycle.json")
end

function MapCycle_GetMapCycle()
    return cycle
end

function MapCycle_SetMapCycle(newCycle)
    cycle = newCycle
    SaveConfigFile(mapCycleFileName, cycle)
end

local function GetMapName(map)
    if type(map) == "table" and map.map ~= nil then
        return map.map
    end
    return map
end

local function StartMap(map)

    local mods = { }
    
    // Copy the global defined mods.
    if type(cycle.mods) == "table" then
        table.copy(cycle.mods, mods, true)
    end
    
    local mapName = GetMapName(map)
    if type(map) == "table" and type(map.mods) == "table" then
        table.copy(map.mods, mods, true)
    end
    
    // Verify the map exists on the file system.
    local found = false
    for i = 1, Server.GetNumMaps() do
    
        local name = Server.GetMapName(i)
        if mapName == name then
        
            found = true
            break
            
        end
        
    end
    
    if found then
        Server.StartWorld(mods, mapName)
    end
    
end

/**
 * Advances to the next map in the cycle
 */
function MapCycle_CycleMap()

    local numMaps = #cycle.maps
    
    if numMaps == 0 then
    
        Shared.Message("No maps in the map cycle")
        return
        
    end
    
    local currentMap = Shared.GetMapName()
    local map = nil
    
    if cycle.mode == "random" then
    
        // Choose a random map to switch to.
        local mapIndex = math.random(1, numMaps)
        map = cycle.maps[mapIndex]
        
        // Don't change to the map we're currently playing.
        if GetMapName(map) == currentMap then
        
            mapIndex = mapIndex + 1
            if mapIndex > numMaps then
                mapIndex = 1
            end
            map = cycle.maps[mapIndex]
            
        end
        
    else
    
        // Go to the next map in the cycle. We need to search backwards
        // in case the same map has been specified multiple times.
        local mapIndex = 0
        
        for i = #cycle.maps, 1, -1 do
            if GetMapName(cycle.maps[i]) == currentMap then
                mapIndex = i
                break
            end
        end
        
        mapIndex = mapIndex + 1
        if mapIndex > numMaps then
            mapIndex = 1
        end
        
        map = cycle.maps[mapIndex]
        
    end
    
    local mapName = GetMapName(map)
    if mapName ~= currentMap then
        StartMap( map )
    end
    
end

/**
 * Advances to the next map in the cycle, if appropriate.
 */
function MapCycle_TestCycleMap()

    // time is stored as minutes so convert to seconds.
    if Shared.GetTime() < (cycle.time * 60) then
        // We haven't been on the current map for long enough.
        return false
    end
    
    return true
    
end

local function OnCommandCycleMap(client)

    if client == nil or client:GetIsLocalClient() then
        MapCycle_CycleMap()
    end
    
end

local function OnCommandChangeMap(client, mapName)
    
    if client == nil or client:GetIsLocalClient() then
        MapCycle_ChangeMap(mapName)
    end
    
end

function MapCycle_ChangeMap(mapName)

    // Find the map in the list
    for i = 1,#cycle.maps do
        local map = cycle.maps[i]
        if GetMapName(map) == mapName then
            StartMap( map )
            return            
        end
    end
    
    // If the map isn't in the cycle, just start with the global mods
    StartMap( mapName )
    
end

Event.Hook("Console_changemap", OnCommandChangeMap)
Event.Hook("Console_cyclemap", OnCommandCycleMap)