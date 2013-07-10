// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Commander_MarqueeSelection.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

local selectorCursorDown = false
local selectorStartX = 0
local selectorStartY = 0

function GetIsCommanderMarqueeSelectorDown()
    return selectorCursorDown
end

local selectorInfo = { }
function GetCommanderMarqueeSelectorInfo()

    selectorInfo.startX = selectorStartX
    selectorInfo.startY = selectorStartY
    local mousePos = MouseTracker_GetCursorPos()
    selectorInfo.endX = mousePos.x
    selectorInfo.endY = mousePos.y
    return selectorInfo
    
end

function SetCommanderMarqueeeSelectorDown(mouseX, mouseY)

    if selectorCursorDown == true then
        return
    end
    
	selectorCursorDown = true
	
	selectorStartX = mouseX
	selectorStartY = mouseY
    
end

function SetCommanderMarqueeeSelectorUp(mouseX, mouseY)

	if selectorCursorDown ~= true then
	    return
	end
	
	selectorCursorDown = false
	
	local player = Client.GetLocalPlayer()    
    player:MarqueeSelectEntities(selectorStartX, selectorStartY, mouseX, mouseY, player.shiftDown)
    
end

