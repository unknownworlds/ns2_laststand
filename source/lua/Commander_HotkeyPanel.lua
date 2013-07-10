//=============================================================================
//
// lua/Commander_HotkeyPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return name for hotkey at index
 */
function CommanderUI_GetHotkeyName(idx)

    return string.format("%d", idx)
    
end

function CommanderUI_GetHotKeyGroups()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetHotkeyGroups()
    end
    
end

function CommnaderUI_GetHotKeyEnergyFraction(idx)

    local player = Client.GetLocalPlayer()
    
    if player then

        local hotgroups = player:GetHotkeyGroups()    
        local group = hotgroups[idx]
        
        local energyFraction = 0.0
        local countedEnts = 0
        
        for _, entityId in ipairs(group) do
        
            if entityId then
            
                local entity = Shared.GetEntity(entityId)
                if entity and HasMixin(entity, "Energy") then
                
                    energyFraction = energyFraction + entity:GetEnergyFraction()
                    countedEnts = countedEnts + 1
                    
                end
                
            end
        
        end
        
        if countedEnts == 0 then
            return 0
        end    
        
        return energyFraction / countedEnts
    
    end

end

/**
 * Indicates hotkey that user has clicked on
 */
function CommanderUI_SelectHotkey(idx)

    local commander = Client.GetLocalPlayer()

    if commander and commander:isa("Commander") then

        local selected, hotgroup = commander:GetHotGroupSelected(idx)        
        if selected then
        
            local position = hotgroup[1]:GetOrigin()
            commander:SetWorldScrollPosition(position.x, position.z)
            
        else

            // The server won't know about this selection, we need to manually tell it.
            commander:SendSelectHotkeyGroupMessage(idx)
            commander:SelectHotkeyGroup(idx)
        
        end
    
    end
    
end

/**
 * Return subicons for the indexed hotkey in linear {x, y} array
 * Return empty array for nothing 
 */
function CommanderUI_GetHotkeySubIcons(idx)
    return {}
end

/**
 * Return bargraph color and percentage in linear array [0-1]
 * Return empty array for nothing
 */
function CommanderUI_GetHotkeyBargraph(idx)
    return {}
end

/**
 * Hotkey tooltip text
 */
function CommanderUI_GetHotkeyTooltip(idx)
    return "Hot group #" .. idx
end
