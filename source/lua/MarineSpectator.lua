// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineSpectator.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Alien spectators can choose their upgrades and lifeform while dead.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamSpectator.lua")
Script.Load("lua/ScoringMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'MarineSpectator' (TeamSpectator)

MarineSpectator.kMapName = "marinespectator"

local networkVars ={ }

function MarineSpectator:OnCreate()

    TeamSpectator.OnCreate(self)
    self:SetTeamNumber(1)
    
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    if Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })
    end
    
end

function MarineSpectator:OnInitialized()

    TeamSpectator.OnInitialized(self)
    
    self:SetTeamNumber(1)
    
end

/**
 * Prevent the camera from penetrating into the world when waiting to spawn at the IP.
 */
function MarineSpectator:GetPreventCameraPenetration()

    local followTarget = Shared.GetEntity(self:GetFollowTargetId())
    return followTarget and followTarget:isa("InfantryPortal")
    
end

function MarineSpectator:GetFollowMoveCameraDistance()
    return 2.5
end

Shared.LinkClassToMap("MarineSpectator", MarineSpectator.kMapName, networkVars)