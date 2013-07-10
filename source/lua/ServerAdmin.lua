// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\ServerAdmin.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Server Admin system. Parses settings from a json file.
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

if Server then

    Script.Load("lua/ConfigFileUtility.lua")
    
    local serverAdminFileName = "ServerAdmin.json"
    
    local defaultConfig = {
                            groups =
                                {
                                  admin_group = { type = "disallowed", commands = { } },
                                  mod_group = { type = "allowed", commands = { "sv_reset", "sv_ban" } }
                                },
                            users =
                                {
                                  NsPlayer = { id = 10000001, groups = { "admin_group" } }
                                }
                          }
    WriteDefaultConfigFile(serverAdminFileName, defaultConfig)
    
    local settings = LoadConfigFile(serverAdminFileName) or defaultConfig
    
    if not settings.groups then
        Shared.Message("No groups defined in " .. serverAdminFileName)
    end
    
    if not settings.users then
        Shared.Message("No users defined in " .. serverAdminFileName)
    end
    
    local function GetGroupCanRunCommand(groupName, commandName)
    
        local group = settings.groups[groupName]
        if not group then
            error("There is no group defined with name: " .. groupName)
        end
        
        local existsInList = false
        for c = 1, #group.commands do
        
            if group.commands[c] == commandName then
            
                existsInList = true
                break
                
            end
            
        end
        
        if group.type == "allowed" then
            return existsInList
        elseif group.type == "disallowed" then
            return not existsInList
        else
            error("Only \"allowed\" and \"disallowed\" are valid terms for the type of the admin group")
        end
        
    end
    
    local function GetClientCanRunCommand(client, commandName, printWarning)
    
        // Convert to the old Steam Id format.
        local steamId = client:GetUserId()
        for name, user in pairs(settings.users) do
        
            if user.id == steamId then
            
                for g = 1, #user.groups do
                
                    local groupName = user.groups[g]
                    if GetGroupCanRunCommand(groupName, commandName) then
                        return true
                    end
                    
                end
                
            end
            
        end
        
        if printWarning then
            Shared.Message("Client with Id " .. steamId .. " is not allowed to execute command: " .. commandName)
        end
        return false
        
    end
    
    local allServerAdminCommands = { }
    function CreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
    
        // Remove the prefix.
        local fixedCommandName = string.gsub(commandName, "Console_", "")
        local newCommand = function(client, ...)
        
            if not client or optionalAlwaysAllowed == true or GetClientCanRunCommand(client, fixedCommandName, true) then
            
                local player = client and client:GetControllingPlayer() or nil
                local name = player and player:GetName() or "Admin"
                local userId = client and client:GetUserId() or 0
                Shared.Message("sv - " .. name .. " - " .. userId .. ": " ..  ": " .. GetReadableSteamId(userId) .. ": " .. fixedCommandName)
                return commandFunction(client, ...)
                
            end
            
        end
        
        table.insert(allServerAdminCommands, { name = fixedCommandName, help = helpText or "No help provided" })
        Event.Hook(commandName, newCommand)
        
    end
    
    local function PrintHelpForCommand(client, optionalCommand)
    
        for c = 1, #allServerAdminCommands do
        
            local command = allServerAdminCommands[c]
            if optionalCommand == command.name or optionalCommand == nil then
            
                if not client or GetClientCanRunCommand(client, command.name, false) then
                    ServerAdminPrint(client, command.name .. ": " .. command.help)
                elseif optionalCommand then
                    ServerAdminPrint(client, "You do not have access to " .. optionalCommand)
                end
                
            end
            
        end
        
    end
    Event.Hook("Console_sv_help", function(client, command) PrintHelpForCommand(client, command) end)
    
end

local kMaxPrintLength = 128
local kServerAdminMessage =
{
    message = string.format("string (%d)", kMaxPrintLength),
}
Shared.RegisterNetworkMessage("ServerAdminPrint", kServerAdminMessage)

if Server then

    function ServerAdminPrint(client, message)
    
        if client then
        
            // First we must split up the message into a list of messages no bigger than kMaxPrintLength each.
            local messageList = { }
            while string.len(message) > kMaxPrintLength do
            
                local messagePart = string.sub(message, 0, kMaxPrintLength)
                table.insert(messageList, messagePart)
                message = string.sub(message, kMaxPrintLength + 1)
                
            end
            table.insert(messageList, message)
            
            for m = 1, #messageList do
                Server.SendNetworkMessage(client:GetControllingPlayer(), "ServerAdminPrint", { message = messageList[m] }, true)
            end
            
        end
        
        // Display message in the server console.
        Shared.Message(message)
        
    end
    
elseif Client then

    local function OnServerAdminPrint(messageTable)
        Shared.Message(messageTable.message)
    end
    Client.HookNetworkMessage("ServerAdminPrint", OnServerAdminPrint)
    
end