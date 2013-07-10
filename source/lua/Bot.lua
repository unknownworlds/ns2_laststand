//=============================================================================
//
// lua\Bot.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

if (not Server) then
    error("Bot.lua should only be included on the Server")
end

// Stores all of the bots
server_bots = { }

class 'Bot'

Script.Load("lua/TechMixin.lua")
Script.Load("lua/ExtentsMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/OrdersMixin.lua")

function Bot:Initialize(forceTeam, active)

    InitMixin(self, TechMixin)
    InitMixin(self, ExtentsMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })

    // Create a virtual client for the bot
    self.client = Server.AddVirtualClient()
    self.forceTeam = forceTeam
    self.active = active
    
    self.client:GetControllingPlayer():SetName("Bot")
    
end

function Bot:GetMapName()
    return "bot"
end

function Bot:GetIsFlying()
    return false
end

function Bot:UpdateTeam(joinTeam)

    local player = self:GetPlayer()

    // Join random team (could force join if needed but will enter respawn queue if game already started)
    if player and player:GetTeamNumber() == 0 and (math.random() < .03) then
    
        if joinTeam == nil then
            joinTeam = ConditionalValue(math.random() < .5, 1, 2)
        end
        
        if GetGamerules():GetCanJoinTeamNumber(joinTeam) or Shared.GetCheatsEnabled() then
            GetGamerules():JoinTeam(player, joinTeam)
        end
        
    end
    
end


function Bot:Disconnect()
    Server.DisconnectClient(self.client)    
    self.client = nil
end

function Bot:GetPlayer()
    return self.client:GetControllingPlayer()
end

function Bot:OnThink()
    self:UpdateTeam(self.forceTeam)        
end

function OnConsoleAddPassiveBots(client, numBotsParam, forceTeam, className)
    OnConsoleAddBots(client, numBotsParam, forceTeam, className, true)  
end

function OnConsoleAddBots(client, numBotsParam, forceTeam, className, passive)

    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
    
        local class = BotPlayer
    
        if className == "test" then
            class = BotTest
        end

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        for index = 1, numBots do
        
            local bot = class()
            bot:Initialize(tonumber(forceTeam), not passive)
            table.insert( server_bots, bot )
       
        end
        
    end
    
end

function OnConsoleRemoveBots(client, numBotsParam, teamNum)

    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
    
        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        teamNum = teamNum and tonumber(teamNum) or nil
        
        local numRemoved = 0
        for index = #server_bots, 1, -1 do
        
            local bot = server_bots[index]
            if bot then
            
                local disconnect = true
                if teamNum and bot:GetPlayer():GetTeamNumber() ~= teamNum then
                    disconnect = false
                end
                
                if disconnect then
                
                    bot:Disconnect()
                    numRemoved = numRemoved + 1
                    table.remove(server_bots, index)
                    
                end
                
                if numRemoved == numBots then
                    break
                end
                
            end
            
        end
        
    end
    
end

function OnVirtualClientMove(client)

    // If the client corresponds to one of our bots, generate a move from it.
    for i,bot in ipairs(server_bots) do
    
        if bot.client == client then
        
            local player = bot:GetPlayer()
            if player then
                return bot:GenerateMove()
            end
            
        end
        
    end

end

function OnVirtualClientThink(client, deltaTime)

    // If the client corresponds to one of our bots, allow it to think.
    for i, bot in ipairs(server_bots) do
    
        if bot.client == client then
            local player = bot:GetPlayer()
            bot:OnThink()
        end
        
    end

    return true
    
end

Script.Load("lua/Bot_Player.lua")
Script.Load("lua/BotTest.lua")

// Register the bot console commands
Event.Hook("Console_addpassivebot",  OnConsoleAddPassiveBots)
Event.Hook("Console_addbot",         OnConsoleAddBots)
Event.Hook("Console_removebot",      OnConsoleRemoveBots)
Event.Hook("Console_addbots",        OnConsoleAddBots)
Event.Hook("Console_removebots",     OnConsoleRemoveBots)

// Register to handle when the server wants this bot to
// process orders
Event.Hook("VirtualClientThink",    OnVirtualClientThink)

// Register to handle when the server wants to generate a move
// for one of the virtual clients
Event.Hook("VirtualClientMove",     OnVirtualClientMove)