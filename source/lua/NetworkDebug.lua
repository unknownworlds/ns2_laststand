// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\NetworkDebug.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local networkDebugClassName = nil
local networkDebugStage = nil

/**
 * This will be called twice, the first time to collect data
 * and the next time to dump any changed fields.
 */
local function NetworkDebug(entity)

    local firstTime = true
    local diffCount = 0
    local stage = entity._prevNetworkState and "dump" or "collect"
    entity._prevNetworkState = entity._prevNetworkState or { }
    
    local networkFieldNames = { }
    entity:GetNetworkFieldNames(networkFieldNames)
    for i, fieldName in ipairs(networkFieldNames) do
    
        local fieldValue = entity[fieldName]
        
        local v = entity[fieldName]
        local p = entity._prevNetworkState[fieldName]
        
        if p ~= v then
        
            if stage == "dump" then
            
                if firstTime then
                
                    Log("%s Networkdiffs @ %s", entity, Shared.GetTime())
                    firstTime = false
                    
                end
                Log("    # %s.%s: %s -> %s", entity:GetClassName(), fieldName, p, v)
                
            end
            
            entity._prevNetworkState[fieldName] = v
            diffCount = diffCount + 1
            
        end
        
    end
    
    // clean up
    if stage == "dump" then
        entity._prevNetworkState = null
    end
    
    return diffCount
    
end

/**
 * Show differences in one network snapshot for all subclasses of classname.
 */
local function OnCommandNetworkDiff(client, classname)

    if Shared.GetCheatsEnabled() then
    
        networkDebugClassName = classname or "Entity"
        Log("Taking network snapshot for %s", networkDebugClassName)
        
    end
    
end
Event.Hook("Console_networkdiff", OnCommandNetworkDiff)

local function OnUpdateServer(deltaTime)

    if networkDebugClassName then
    
        // Hook to allow debugging of network variable changes
        local entityDiffCount = 0
        local fieldDiffCount = 0
        local totalCount = 0
        
        networkDebugStage = networkDebugStage and "dump" or "collect"
        
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname(networkDebugClassName)) do
        
            totalCount = totalCount + 1
            local fieldsDiffering = NetworkDebug(entity)
            
            if fieldsDiffering >= 0 then
            
                fieldDiffCount = fieldDiffCount + fieldsDiffering
                entityDiffCount = entityDiffCount + (fieldsDiffering > 0 and 1 or 0)
                
            end
            
        end
        
        if networkDebugStage == "dump" then
        
            // done, turn off
            Log("Networkdiff: %s total entities, %s fields changed in %s entites", totalCount, fieldDiffCount, entityDiffCount)
            networkDebugStage = nil
            networkDebugClassName= nil
            
        end
        
    end
    
end
Event.Hook("UpdateServer", OnUpdateServer)