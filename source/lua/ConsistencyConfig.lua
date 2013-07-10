// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// core/ConsistencyConfig.lua
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ConfigFileUtility.lua")

local consistencyConfigFileName = "ConsistencyConfig.json"

// Write out the default file if it doesn't exist.
local defaultConfig = { check = { "game_setup.xml", "*.lua", "*.fx", "*.screenfx", "*.surface_shader", "*.fxh", "*.render_setup", "*.shader_template" } }
WriteDefaultConfigFile(consistencyConfigFileName, defaultConfig)

/** 
 * Loads information from the consistency config file.
 */
local consistencyConfig = LoadConfigFile(consistencyConfigFileName)

if consistencyConfig then

    if type(consistencyConfig.check) == "table" then
        local check = consistencyConfig.check
        for c = 1, #check do
            local numHashed = Server.AddFileHashes(check[c])
            Shared.Message("Hashed " .. numHashed .. " " .. check[c] .. " files for consistency")
        end
    end

    if type(consistencyConfig.ignore) == "table" then
        local ignore = consistencyConfig.ignore
        for c = 1, #ignore do
            local numHashed = Server.RemoveFileHashes(ignore[c])
            Shared.Message("Skipped " .. numHashed .. " " .. ignore[c] .. " files for consistency")
        end
    end
    
end