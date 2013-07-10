// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Commander_Ping.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

local pingEnabled = false

function SetCommanderPingEnabled(setEnabled)
    pingEnabled = setEnabled
end

function GetCommanderPingEnabled()
    return pingEnabled
end

local function CheckMouseIsInMinimapFrame(x, y)

    local minimapScript = ClientUI.GetScript("GUIMinimapFrame")
    local containsPoint, withinX, withinY = GUIItemContainsPoint(minimapScript:GetMinimapItem(), x, y)
    return containsPoint, withinX, withinY, minimapScript:GetMinimapSize()
    
end

local function CheckKeyIsAMouseButton(key)

    for buttonIndex = 0, 7 do
    
        if key == InputKey["MouseButton" .. buttonIndex] then
            return true
        end
        
    end
    
    return false
    
end

function CheckKeyEventForCommanderPing(key, down)

    if not ChatUI_EnteringChatMessage() and down and (GetIsBinding(key, "PingLocation") or (pingEnabled and key == InputKey.MouseButton0)) then
    
        local x, y = Client.GetCursorPosScreen()
        local containsPoint, withinX, withinY, minimapSize = CheckMouseIsInMinimapFrame(x, y)
        if containsPoint then
        
            local mmX = withinX / minimapSize.x
            local mmY = withinY / minimapSize.y
            CommanderUI_TriggerPingOnMinimap(mmX, mmY)
            
        else
            CommanderUI_TriggerPingInWorld(x, y)
        end
        
        pingEnabled = false
        return true
        
    end
    
    // If the key is any mouse button, disable ping at this point.
    if down and CheckKeyIsAMouseButton(key) then
        pingEnabled = false
    end
    
    return false
    
end