// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GhostModelUI.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local gGhostModel = nil
local gLoadedTechId = nil

function LoadGhostModel(className)

    local pathToFile = string.format("lua/Hud/Commander/%s.lua", className)

    if gGhostModel then
        gGhostModel:Destroy()
        gGhostModel = nil
    end
    
    Script.Load(pathToFile)
    local creationFunction = _G[className]

    if creationFunction == nil then
    
        Shared.Message("Error: Failed to load ghostmodel class named " .. className)
        return nil
        
    end

    gGhostModel = creationFunction()
    gGhostModel:Initialize()

end

function GhostModelUI_GetModelName()

    local player = Client.GetLocalPlayer()
    if player and player.GetGhostModelTechId then
        return LookupTechData(player:GetGhostModelTechId(), kTechDataModel)    
    end
    
end

function GhostModelUI_GetNearestAttachPointDirection()

    local player = Client.GetLocalPlayer()
    if player then
    
        local attachClass = LookupTechData(player.currentTechId, kStructureAttachClass)
        if attachClass then
        
            local ghostOrigin = player:GetGhostModelCoords().origin
            local nearestAttachEnt = GetNearestFreeAttachEntity(player.currentTechId, ghostOrigin)
            if nearestAttachEnt then
            
                local withinSnapRadius = nearestAttachEnt:GetOrigin():GetDistanceTo(ghostOrigin) <= kStructureSnapRadius
                if not withinSnapRadius then
                    return GetNormalizedVectorXZ(nearestAttachEnt:GetOrigin() - ghostOrigin)
                end
                
            end
            
        end
        
    end
    
    return nil
    
end

function GhostModelUI_GetNearestAttachStructureDirection()

    local player = Client.GetLocalPlayer()
    if player then
    
        local attachId = LookupTechData(player.currentTechId, kStructureAttachId)
        
        // Handle table of attach ids.
        local supportingTechIds = { }
        if type(attachId) == "table" then
        
            for index, currentAttachId in ipairs(attachId) do
                table.insert(supportingTechIds, currentAttachId)
            end
            
        else
            table.insert(supportingTechIds, attachId)
        end
        
        local ents = GetEntsWithTechIdIsActive(supportingTechIds)
        if #ents > 0 then
        
            local ghostOrigin = player:GetGhostModelCoords().origin
            Shared.SortEntitiesByDistance(ghostOrigin, ents)
            local ghostRadius = LookupTechData(player.currentTechId, kStructureAttachRange, 0)
            if ents[1]:GetOrigin():GetDistanceTo(ghostOrigin) > ghostRadius then
                return GetNormalizedVectorXZ(ents[1]:GetOrigin() - ghostOrigin)
            end
            
        end
        
    end
    
    return nil
    
end

function GhostModelUI_GetGhostModelCoords()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetGhostModelCoords()
    end
    
end

function GhostModelUI_GetLastClickedPosition()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetLastClickedPosition()
    end
    
end

function GhostModelUI_GetIsValidPlacement()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetIsPlacementValid()    
    end

end

local function OnUpdateRenderGhostModel()

    local player = Client.GetLocalPlayer()
    local showGhostModel = false
    if player and player.GetShowGhostModel then
        showGhostModel = player:GetShowGhostModel()
    end
    
    local techId = player and player.GetGhostModelTechId and player:GetGhostModelTechId()
    
    if showGhostModel and techId then

        if gLoadedTechId ~= techId then
            LoadGhostModel(LookupTechData(techId, kTechDataGhostModelClass, "GhostModel") )
            gLoadedTechId = techId
        end

        gGhostModel:Update()

    else

        if gGhostModel then
        
            gGhostModel:Destroy()
            gGhostModel = nil
            gLoadedTechId = nil
            
        end

    end  
        
end

Event.Hook("UpdateRender", OnUpdateRenderGhostModel)