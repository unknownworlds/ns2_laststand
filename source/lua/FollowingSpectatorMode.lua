// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\FollowingSpectatorMode.lua
//
// Created by: Marc Delorme (marc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpectatorMode.lua")

class 'FollowingSpectatorMode' (SpectatorMode)

FollowingSpectatorMode.name = "Following"

function FollowingSpectatorMode:Initialize(spectator)

    spectator:SetFollowMoveEnabled(true)
    local dist = spectator.GetFollowMoveCameraDistance and spectator:GetFollowMoveCameraDistance() or 5
    spectator:SetDesiredCameraDistance(dist)
    
end

function FollowingSpectatorMode:Uninitialize(spectator)

    spectator:SetFollowMoveEnabled(false)
    spectator:SetDesiredCameraDistance(0)
    
end