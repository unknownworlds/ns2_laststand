// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\AFKMixin.lua
//
// ==============================================================================================

AFKMixin = CreateMixin(AFKMixin)
AFKMixin.type = "AFKMixin"

function AFKMixin:__initmixin()
    assert(Server)
end

function AFKMixin:GetAFKTime()

    local client = Server.GetOwner(self)
    return (client and client.timeLastNotAFK) and (Shared.GetTime() - client.timeLastNotAFK) or 0
    
end

local function GetAutoKickOnAFKEnabled(serverAFKTime)

    // Only kick if enough time has passed and the defined time is greater than 0.
    if serverAFKTime and serverAFKTime > 0  then
    
        // Only kick if the server is at the player capacity defined.
        local capacity = Server.GetConfigSetting("auto_kick_afk_capacity")
        local percentFull = Server.GetNumPlayers() / Server.GetMaxPlayers()
        local overCapacity = (not capacity or (percentFull >= capacity))
        return overCapacity
        
    end
    
    return false
    
end

function AFKMixin:OnProcessMove(input)

    PROFILE("AFKMixin:OnProcessMove")
    
    local serverAFKTime = Server.GetConfigSetting("auto_kick_afk_time")
    local autoKickOnAFKEnabled = GetAutoKickOnAFKEnabled(serverAFKTime)
    
    local client = Server.GetOwner(self)
    
    if client and autoKickOnAFKEnabled then
    
        local inputMove = input.move
        if not (inputMove.x == 0 and inputMove.y == 0 and inputMove.z == 0 and
                input.commands == 0 and client.lastAFKInputYaw == input.yaw and
                client.lastAFKInputPitch == input.pitch) then
        
            client.timeLastNotAFK = Shared.GetTime()
            
        end
        
        client.lastAFKInputYaw = input.yaw
        client.lastAFKInputPitch = input.pitch
        
        local playerAFKTime = self:GetAFKTime()
        if playerAFKTime >= serverAFKTime then
        
            Server.DisconnectClient(client)
            Shared.Message("Player " .. self:GetName() .. " kicked for being AFK for " .. serverAFKTime .. " seconds")
            TEST_EVENT("AFK Player auto-kicked")
            
        elseif playerAFKTime >= serverAFKTime * 0.75 then
        
            if not self.warnedAtTime or (Shared.GetTime() - self.warnedAtTime) > (serverAFKTime * 0.75) then
            
                Server.SendNetworkMessage(client, "AFKWarning", { timeAFK = playerAFKTime, maxAFKTime = serverAFKTime }, true)
                self.warnedAtTime = Shared.GetTime()
                
            end
            
        end
        
    elseif client then
        client.timeLastNotAFK = Shared.GetTime()
    end
    
end

local kAFKWarning =
{
    timeAFK = "float",
    maxAFKTime = "float"
}
Shared.RegisterNetworkMessage("AFKWarning", kAFKWarning)

if Client then

    local function OnMessageAFKWarning(message)
    
        local warningText = StringReformat(Locale.ResolveString("AFK_WARNING"), { timeAFK = message.timeAFK, maxAFKTime = message.maxAFKTime })
        ChatUI_AddSystemMessage(warningText)
        
    end
    Client.HookNetworkMessage("AFKWarning", OnMessageAFKWarning)
    
end