// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\FreeLookSpectatorMode.lua
//
// Created by: Marc Delorme (marc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpectatorMode.lua")

class 'FreeLookSpectatorMode' (SpectatorMode)

FreeLookSpectatorMode.name = "FreeLook"

function FreeLookSpectatorMode:Initialize(spectator)

    spectator:SetFreeLookMoveEnabled(true)
    
    if Server then

        local angles = Angles(spectator:GetViewAngles())
        
        // Start with a null velocity
        spectator:SetVelocity(Vector(0, 0, 0))
        
        spectator:SetBaseViewAngles(Angles(0, 0, 0))
        spectator:SetViewAngles(angles)

    end
    
end

function FreeLookSpectatorMode:Uninitialize(spectator)
    spectator:SetFreeLookMoveEnabled(false)
end