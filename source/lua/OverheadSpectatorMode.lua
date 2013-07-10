// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\OverheadSpectatorMode.lua
//
// Created by: Marc Delorme (marc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpectatorMode.lua")

if Client then
    Script.Load("lua/GUIManager.lua")
end

class 'OverheadSpectatorMode' (SpectatorMode)

OverheadSpectatorMode.name = "Overhead"

function OverheadSpectatorMode:Initialize(spectator)

    spectator:SetOverheadMoveEnabled(true)
    
    spectator:SetDesiredCamera( 0.3, { follow = true })
    
    // Set Overhead view angle.
    local overheadAngle = Angles((70 / 180) * math.pi, (90 / 180) * math.pi, 0)
    spectator:SetBaseViewAngles(Angles(0, 0, 0))
    spectator:SetViewAngles(overheadAngle)
    
    if Client and spectator == Client.GetLocalPlayer() then
    
        GetGUIManager():CreateGUIScriptSingle("GUIInsight_Overhead")
        MouseTracker_SetIsVisible(true, nil, true)
        
    	SetCommanderPropState(true)
        SetSkyboxDrawState(false)
        Client.SetSoundGeometryEnabled(false)
        Client.SetGroupIsVisible(kCommanderInvisibleGroupName, false)
        
        Client.SetPitch(overheadAngle.pitch)
        Client.SetYaw(overheadAngle.yaw)
        
    end
    
end

function OverheadSpectatorMode:Uninitialize(spectator)

    spectator:SetOverheadMoveEnabled(false)
    
	spectator:SetDesiredCamera( 0.3, { follow = true })
    local position = spectator:GetOrigin()
    
    -- Pick a height to set the spectator at
    -- Either a raytrace to the ground (better value)
    -- Or use the heightmap if the ray goes off the map
    local trace = GetCommanderPickTarget(spectator, spectator:GetOrigin(), true, false, false)
    local traceHeight = trace.endPoint.y
    local mapHeight = GetHeightmap():GetElevation(position.x, position.z) - 8
    
    -- Assume the trace is off the map if it's far from the heightmap
    -- Is there a better way to test this?
    local traceOffMap = math.abs(traceHeight-mapHeight) > 15
    local bestHeight = ConditionalValue(traceOffMap, mapHeight, traceHeight)
    position.y = bestHeight
    
	local viewAngles = spectator:GetViewAngles()
	viewAngles.pitch = 0
	spectator:SetOrigin(position)
	spectator:SetViewAngles(viewAngles)
    
	if Client then
    
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_Overhead")
        MouseTracker_SetIsVisible(false)
        
        SetCommanderPropState(false)
        SetSkyboxDrawState(true)
        Client.SetSoundGeometryEnabled(true)
        Client.SetGroupIsVisible(kCommanderInvisibleGroupName, true)
        
        Client.SetPitch(viewAngles.pitch)
        
	end
    
end
