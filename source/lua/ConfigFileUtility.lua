// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// core/ConfigFileUtility.lua
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/dkjson.lua")

function WriteDefaultConfigFile(fileName, defaultConfig)

    local configFile = io.open("config://" .. fileName, "r")
    if not configFile then
    
        configFile = io.open("config://" .. fileName, "w+")
        if configFile == nil then
            return
        end
        configFile:write(json.encode(defaultConfig, { indent = true }))
        
    end
    
    io.close(configFile)
    
end

function LoadConfigFile(fileName)

    Shared.Message("Loading " .. "config://" .. fileName)
    
    local openedFile = io.open("config://" .. fileName, "r")
    if openedFile then
    
        local parsedFile, _, errStr = json.decode(openedFile:read("*all"))
        if errStr then
            Shared.Message("Error while opening " .. fileName .. ": " .. errStr)
        end
        io.close(openedFile)
        return parsedFile
        
    end
    
    return nil
    
end

function SaveConfigFile(fileName, data)

    Shared.Message("Saving " .. "config://" .. fileName)
    
    local openedFile = io.open("config://" .. fileName, "w+")
    
    if openedFile then
    
        openedFile:write(json.encode(data, { indent = true }))
        io.close(openedFile)
        
    end
    
end