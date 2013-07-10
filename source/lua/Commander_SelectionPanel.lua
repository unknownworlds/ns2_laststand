//=============================================================================
//
// lua/Commander_SelectionPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of entities currently selected by a commander
 */
function CommanderUI_GetSelectedEntitiesCount()

    return table.count(Client.GetLocalPlayer():GetSelection())

end

/**
 * Return a list of entities selected by a commander
 */
function CommanderUI_GetSelectedEntities()

    local player = Client.GetLocalPlayer()
    if player.GetSelection then
        return player:GetSelection()
    end
    
    return { }
        
end

/**
 * Player is selecting all active players. Sets local selection and sends command to server.
 */
function CommanderUI_ClickedSelectAllPlayers()
    
    local player = Client.GetLocalPlayer()
    if player and player.SelectAllPlayers then
    
        player:SelectAllPlayers()        
        Shared.ConsoleCommand("selectallplayers")
        
    end
        
end

/**
 * Get up to 2 <text>,[0-1] pairs in linear array for bargraphs on the commander selection
 */
function CommanderUI_GetCommandBargraphs()

    local selectedEnts = Client.GetLocalPlayer():GetSelection()
    
    if (table.count(selectedEnts) == 1) then
    
        local entId = selectedEnts[1]
        return CommanderUI_GetSelectedBargraphs(entityId)
        
    end

    return {}
    
end

/**
 * Get a string that describes the entity
 */
function CommanderUI_GetSelectedDescriptor(entity)

    local player = Client.GetLocalPlayer()
    
    local descriptor = "Unknown"
    if player and entity then
        descriptor = GetSelectionText(entity, player:GetTeamNumber())
    end
    
    return descriptor
    
end

/**
 * Get a string that describes the entity location
 */
function CommanderUI_GetSelectedLocation(entity)

    local locationText = ""
    if entity and entity.GetLocationName then
        locationText = locationText .. entity:GetLocationName()
    else
        Print("CommanderUI_GetSelectedLocation(): Entity is nil.")
    end
        
    return locationText

end

function CommanderUI_GetSelectedHealth(entity)

    if entity and HasMixin(entity, "Live") and entity:GetMaxHealth() > 0 and not entity:GetIgnoreHealth() then
        return string.format("%d/%d", math.floor(entity:GetHealth()), math.ceil(entity:GetMaxHealth()))
    end
    
    return ""
    
end

function CommanderUI_GetSelectedArmor(entity)

    if entity and HasMixin(entity, "Live") and entity:GetMaxArmor() > 0 then
        return string.format("%d/%d", math.floor(entity:GetArmor()), math.ceil(entity:GetMaxArmor()))
    end
    
    return ""
    
end

function CommanderUI_GetSelectedEnergy(entity)

    if entity and entity.GetEnergy and entity.GetMaxEnergy then
        return string.format("%d/%d", math.floor(entity:GetEnergy()), math.ceil(entity:GetMaxEnergy()))
    end
    
    return ""

end

/**
 * Get up to 2 <text>,[0-1] pairs in linear array for bargraphs on the selected entity
 */
function CommanderUI_GetSelectedBargraphs(entity)

    local t = {}
    
    if entity then
        
        if HasMixin(entity, "Recycle") and entity:GetRecycleActive() then
        
            table.insert(t, Locale.ResolveString("COMM_SEL_RECYCLING"))
            table.insert(t, entity:GetResearchProgress())
            table.insert(t, entity:GetResearchingId())
            
        elseif HasMixin(entity, "Construct") and not entity:GetIsBuilt() then
        
            table.insert(t, Locale.ResolveString("COMM_SEL_CONSTRUCTING"))
            table.insert(t, entity:GetBuiltFraction())
            table.insert(t, kTechId.Construct)
            
        elseif HasMixin(entity, "Research") and entity:GetIsManufacturing() then
        
            table.insert(t, Locale.ResolveString("COMM_SEL_BUILDING"))
            table.insert(t, entity:GetResearchProgress())
            table.insert(t, entity:GetResearchingId())
            
        elseif HasMixin(entity, "Research") and entity:GetIsUpgrading() then
        
            table.insert(t, Locale.ResolveString("COMM_SEL_UPGRADING"))
            table.insert(t, entity:GetResearchProgress())
            table.insert(t, entity:GetResearchingId())
            
        elseif HasMixin(entity, "Research") and entity:GetIsResearching() then
        
            table.insert(t, Locale.ResolveString("COMM_SEL_RESEARCHING"))
            table.insert(t, entity:GetResearchProgress())
            table.insert(t, entity:GetResearchingId())
            
        end
        
    end
    
    return t
    
end

/**
 * Return pixel coordinates to the selected entity icon
 */
function CommanderUI_GetSelectedIconOffset(entity)
    
    local isaMarine = Client.GetLocalPlayer():isa("MarineCommander")
    return GetPixelCoordsForIcon(entity, isaMarine)
    
end
/**
 * Get custom rightside selection text for a single selection
 */
function CommanderUI_GetSingleSelectionCustomText(entity)

    local customText = ""
    
    if entity and entity.GetCustomSelectionText then
        customText = entity:GetCustomSelectionText()
    end
    
    return customText
    
end