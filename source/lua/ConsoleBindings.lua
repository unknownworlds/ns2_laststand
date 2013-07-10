// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\ConsoleBindings.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

Script.Load("lua/ConfigFileUtility.lua")

local bindingsFileName = "ConsoleBindings.json"

// Load the bindings from file if the file exists.
local bindings = LoadConfigFile(bindingsFileName) or { }

local function GetBinding(keyCode)

    for inputKeyName, code in pairs(InputKey) do
    
        if keyCode == code then
        
            if bindings[inputKeyName] then
                return bindings[inputKeyName].command
            end
            
        end
        
    end
    
    return nil
    
end

local function OnCommandBind(keyName, ...)

    local command = ""
    local args = {...}
    for a = 1, #args do
        command = command .. args[a] .. " "
    end
    
    local bound = false
    for inputKeyName, code in pairs(InputKey) do
    
        if inputKeyName == keyName then
        
            bound = true
            bindings[keyName] = { code = code, command = command }
            
            // Save to disk.
            SaveConfigFile(bindingsFileName, bindings)
            
            Shared.Message(keyName .. " is now: " .. command)
            break
            
        end
        
    end
    
    if not bound then
    
        if keyName then
            Shared.Message(keyName .. " does not exist. Below are the valid key names:")
        else
            Shared.Message("No key name provided. Below are the valid key names:")
        end
        
        local inputKeys = ""
        local numPrinted = 0
        for inputKeyName, code in pairs(InputKey) do
        
            inputKeys = inputKeys .. inputKeyName .. ", "
            numPrinted = numPrinted + 1
            if numPrinted > 5 then
            
                numPrinted = 0
                inputKeys = inputKeys .. "\n"
                
            end
            
        end
        Shared.Message(inputKeys)
        
    end
    
end

local function OnCommandPrintBindings()

    for keyName, binding in pairs(bindings) do
        Shared.Message(keyName .. " = " .. binding.command)
    end
    
end

local function OnCommandClearBinding(keyName)

    if bindings[keyName] then
    
        bindings[keyName] = nil
        
        // Save to disk.
        SaveConfigFile(bindingsFileName, bindings)
        
        Shared.Message(keyName .. " cleared")
        
    end
    
end

/**
 * This needs to be called to notify the ConsoleBindings when a key is pressed
 * to check if the key matches a binding.
 */
function ConsoleBindingsKeyPressed(key)

    local command = GetBinding(key)
    if command then
        Shared.ConsoleCommand(command)
    end
    
end

Event.Hook("Console_bind", OnCommandBind)
Event.Hook("Console_print_bindings", OnCommandPrintBindings)
Event.Hook("Console_clear_binding", OnCommandClearBinding)