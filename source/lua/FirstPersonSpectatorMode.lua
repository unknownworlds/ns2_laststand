// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\FirstPersonSpectatorMode.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpectatorMode.lua")

class 'FirstPersonSpectatorMode' (SpectatorMode)

FirstPersonSpectatorMode.name = "FirstPerson"

function FirstPersonSpectatorMode:Initialize(spectator)
end

function FirstPersonSpectatorMode:Uninitialize(spectator)

    if Server then

        local client = Server.GetOwner(spectator)
        if client then
            local player = client:GetSpectatingPlayer()
            if player then
                spectator:SelectEntity(player:GetId())
                // This doesn't override the client's view angles for some reason. WRY?
                spectator:SetViewAngles(player:GetViewAngles())
                spectator:SetAngles(player:GetAngles())
                spectator:SetOrigin(player:GetOrigin())
            end
            client:SetSpectatingPlayer(nil)
        end
        
    end
    
end

function FirstPersonSpectatorMode:FindTarget(spectator)

    local validTarget = nil
    if spectator.selectedId ~= Entity.invalidId then
    
        validTarget = Shared.GetEntity(spectator.selectedId)
        // Do not allow spectating Commanders currently in first person.
        // More work is needed before that is ready.
        if validTarget and validTarget:isa("Commander") then
            validTarget = nil
        end
        
    end
    
    local targets = spectator:GetTargetsToFollow()
    if not validTarget then
    
        // Find a valid target to follow.
        for t = 1, #targets do
        
            if targets[t]:isa("Player") then
            
                validTarget = targets[t]
                break
                
            end
            
        end
        
    end
    
    if validTarget then
        Server.GetOwner(spectator):SetSpectatingPlayer(validTarget)
    elseif spectator:GetIsOnPlayingTeam() then
        spectator:SetSpectatorMode(kSpectatorMode.Following)
    else
    
        // If there is at least an invalid target, use it as the origin for the spectator
        // so the spectator free cam isn't placed in the RR for example.
        if #targets > 0 then
            spectator:SetOrigin(targets[1]:GetOrigin() + Vector(0, 1, 0))
        end
        spectator:SetSpectatorMode(kSpectatorMode.FreeLook)
        
    end
    
end

function FirstPersonSpectatorMode:CycleSpectatingPlayer(spectatingEntity, spectatorEntity, client, forward)

    // Find a valid target to follow.
    local targets = spectatorEntity:GetTargetsToFollow()
    // Remove any non-players from the list.
    for t = #targets, 1, -1 do
    
        local target = targets[t]
        if not target:isa("Player") then
            table.remove(targets, t)
        end
        
    end
    
    local numTargets = #targets
    local validTargetIndex = numTargets > 0 and math.random(1, numTargets) or nil
    // Look for the current spectatingEntity index.
    for t = 1, #targets do
    
        if targets[t] == spectatingEntity then
        
            validTargetIndex = t
            break
            
        end
        
    end
    
    // Fall back on Following mode if there is no other target.
    if numTargets == 0 then
    
        spectatorEntity:SetSpectatorMode(kSpectatorMode.Following)
        return true
        
    elseif validTargetIndex then
    
        // Find the next index and cycle around if needed.
        if forward then
            validTargetIndex = validTargetIndex < #targets and validTargetIndex + 1 or 1
        else
            validTargetIndex = validTargetIndex > 1 and validTargetIndex - 1 or #targets
        end
        
        local finalTargetEnt = targets[validTargetIndex]
        if spectatingEntity ~= finalTargetEnt then
        
            client:SetSpectatingPlayer(finalTargetEnt)
            return true
            
        end
        
    end
    
    return false
    
end