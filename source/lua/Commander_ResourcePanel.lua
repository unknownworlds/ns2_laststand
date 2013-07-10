//=============================================================================
//
// lua/Commander_ResourcePanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Get total number of team harvesters.
 */
function CommanderUI_GetTeamHarvesterCount()

    PROFILE("CommanderUI_GetTeamHarvesterCount")
    
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        local teamInfo = GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())
        if table.count(teamInfo) > 0 then
            return teamInfo[1]:GetNumResourceTowers()
        end
        
    end
    
    return 0
    
end

function CommanderUI_GetNumSupportedHarvesters()

    local player = Client.GetLocalPlayer()
    local techPoints = 0
    
    if player ~= nil then
    
        local teamInfo = GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())        
        if table.count(teamInfo) > 0 then
            techPoints = teamInfo[1]:GetNumCapturedTechPoints()
        end
    end
    
    return kMinSupportedRTs + techPoints * kRTsPerTechpoint

end

/**
 * Indicates user clicked on the harvester count.
 */
function CommanderUI_ClickedTeamHarvesterCount()
end