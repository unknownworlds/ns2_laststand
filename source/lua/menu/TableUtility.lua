// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\TableUtility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Collection of render functions for tables.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function RenderTextEntry(tableEntry, entryData)

    local font = CreateMenuElement(tableEntry, 'Font', false)
    font:SetText(ToString(entryData))
    
    return font

end

function RenderModName(tableEntry, entryData)

    local font = CreateMenuElement(tableEntry, 'Font', false)
    font:SetText(ToString(entryData))
    font:SetCSSClass("mod_name")
    
    return font

end

function RenderServerNameEntry(tableEntry, entryData)

    if entryData == "FAVORITE" or entryData == "PRIVATE" then
    
        local image = CreateMenuElement(tableEntry, 'Image', false)
        
        if entryData == "FAVORITE" then
            image:SetCSSClass("top_row_favorite")
        else
            image:SetCSSClass("top_row_private")
        end
        image:SetIgnoreEvents(true)
        
        return image
    
    else
    
        local font = CreateMenuElement(tableEntry, 'Font', false)
        
        local serverName = ""
        local rookieFriendly = nil
    
        if type(entryData) == "string" then
            serverName = entryData
        else
            serverName = entryData[1]
            rookieFriendly = entryData[2]
        end
        font:SetText(serverName)
        
        return font
        
    end
    
end

function RenderPrivateEntry(tableEntry, entryData)
    local image = CreateMenuElement(tableEntry, 'Image', false)
    image:SetCSSClass("private")
    image.background:SetIsVisible(entryData)

    return image
end

function RenderStatusIconsEntry(tableEntry, entryData)

    local friendsIcon = nil 
    if entryData[1] then    
        friendsIcon = CreateMenuElement(tableEntry, 'Image', false)
        friendsIcon:SetCSSClass("friends_icon")
    end

    local lanIcon = nil
    if entryData[2] then 
        lanIcon = CreateMenuElement(tableEntry, 'Image', false)
        lanIcon:SetCSSClass("lan_icon")
    end    
    
    local customGameIcon = nil
    if entryData[3] then
        customGameIcon = CreateMenuElement(tableEntry, 'Image', false)
        customGameIcon:SetCSSClass("custom_game_icon")
    end
    
    return friendsIcon, lanIcon, customGameIcon

end

function RenderMapNameEntry(tableEntry, entryData)

    local font = CreateMenuElement(tableEntry, 'Font', false)
    font:SetText(entryData)
    font:SetCSSClass("map_name")
    
    return font
    
end

function RenderPlayerCountEntry(tableEntry, entryData)

    local playerCount = entryData[1]
    local maxPlayers = entryData[2]
    
    local font = CreateMenuElement(tableEntry, 'Font', false)    
    font:SetText(string.format("%d/%d", playerCount, maxPlayers))
    
    if playerCount >= maxPlayers then
        font:SetCSSClass("player_count_full")
    else
        font:SetCSSClass("player_count_free")
    end    
    
    return font

end

function RenderPingEntry(tableEntry, entryData)

    local font = CreateMenuElement(tableEntry, 'Font', false)
    font:SetText(ToString(entryData))
    
    if entryData >= kBadPing then
        font:SetCSSClass("ping_bad")
    elseif entryData >= kModeratePing then
        font:SetCSSClass("ping_moderate")
    else    
        font:SetCSSClass("ping_good")
    end
    
    return font

end
