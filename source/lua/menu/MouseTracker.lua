// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\MouseTracker.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kDoubleClickDelay = 0.3

local gCursorPos = Vector(0,0,0)
local gLastCursorPos = Vector(0,0,0)
local gMouseMove = Vector(0,0,0)
local gMouseMovementListeners = {}
local gMouseWheelMovementListeners = {}
local gMouseButtonListeners = {}
local gCursorStack = {}

local gLeftButtonPressed = false
local gRightButtonPressed = false
local gMiddleButtonPressed = false
local gLeftButtonPressedTime = nil

function MouseTracker_ListenToMovement(listener)

    assert(listener.OnMouseMove)
    
    table.insert(gMouseMovementListeners, listener)
    
end

function MouseTracker_ListenToWheel(listener)

    assert(listener.OnMouseWheel)
    
    table.insert(gMouseWheelMovementListeners, listener)
    
end

function MouseTracker_ListenToButtons(listener)

    assert(listener.OnMouseDown)
    assert(listener.OnMouseUp)
    
    table.insert(gMouseButtonListeners, listener)
    
end

function MouseTracker_GetCursorPos()
    return gCursorPos
end

function MouseTracker_GetLastCursorPos()
    return gLastCursorPos
end

function MouseTracker_GetMouseMovement()
    return gMouseMove
end

function MouseTracker_GetIsLeftButtonPressed()
    return gLeftButtonPressed
end

function MouseTracker_GetIsRightButtonPressed()
    return gRightButtonPressed
end

function MouseTracker_GetIsMiddleButtonPressed()
    return gMiddleButtonPressed
end

function MouseTracker_SetIsVisible(isVisible, texture, clipped)

    if isVisible then
    
        if not texture then
            texture = "ui/Cursor_MenuDefault.dds"
        end
        
        table.insert(gCursorStack, { Texture = texture, Clipped = clipped } )
        
        Client.SetCursor(texture, 0, 0)
        Client.SetMouseVisible(true)
        Client.SetMouseClipped(clipped == true)
        
    else
    
        if #gCursorStack > 1 then
        
            table.remove(gCursorStack, #gCursorStack)
            Client.SetCursor(gCursorStack[#gCursorStack].Texture, 0, 0)
            Client.SetMouseClipped(gCursorStack[#gCursorStack].Clipped == true)
            
        else
        
            table.remove(gCursorStack, 1)
            
            // These calls are only available after the Client has connected to a server.
            if Client.SetMouseVisible then
                Client.SetMouseVisible(false)
            end
            
            if Client.SetMouseClipped then
                Client.SetMouseClipped(true)
            end
            
        end
        
    end
    
end

function MouseTracker_GetIsVisible()
    return #gCursorStack > 0
end

/**
 * If inputBlocked is true, the key event will not be processed. Only
 * the movement internally will be processed in this case.
 */
function MouseTracker_SendKeyEvent(key, down, amount, inputBlocked)

    if not Shared.GetIsRunningPrediction() and #gCursorStack > 0 then
    
        if key == InputKey.MouseZ and not inputBlocked then
        
            // Notify about mouse wheel movement.
            for index, listener in ipairs(gMouseWheelMovementListeners) do
                listener:OnMouseWheel(amount > 0)
            end
            
            return true
            
        elseif key == InputKey.MouseX or key == InputKey.MouseY then
        
            gLastCursorPos.x = gCursorPos.x
            gLastCursorPos.y = gCursorPos.y
            
            local screenWidth = Client.GetScreenWidth() 
            local screenHeight = Client.GetScreenHeight()
            
            gCursorPos.x, gCursorPos.y = Client.GetCursorPosScreen()
            
            // Prevent moving objects outside of the window when mouse is not clipped.
            gCursorPos.x = Clamp(gCursorPos.x, 0, screenWidth)
            gCursorPos.y = Clamp(gCursorPos.y, 0, screenHeight)
            
            gMouseMove = gCursorPos - gLastCursorPos
            
            if not inputBlocked then
            
                // Notify about mouse movement.
                for index, listener in ipairs(gMouseMovementListeners) do
                    listener:OnMouseMove(gLeftButtonPressed)
                end
                
            end
            
            return true
            
        elseif key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton2 then
            
            local doubleClick = false
            if key == InputKey.MouseButton0 then
                gLeftButtonPressed = down
                if down then
                    local newTime = Shared.GetTime()
                    if gLeftButtonPressedTime ~= nil then
                        local timeSinceLastPress = newTime - gLeftButtonPressedTime
                        if timeSinceLastPress < kDoubleClickDelay then
                            doubleClick = true
                            newTime = nil
                        end
                    end
                    gLeftButtonPressedTime = newTime
                end
            elseif key == InputKey.MouseButton1 then
                gRightButtonPressed = down         
            elseif key == InputKey.MouseButton2 then
                gMiddleButtonPressed = down 
            end
            
            local stop = false
            
            if not inputBlocked then
            
                for index, listener in ipairs(gMouseButtonListeners) do
                
                    if down then
                        stop = listener:OnMouseDown(key, doubleClick)
                    else
                        stop = listener:OnMouseUp(key)
                    end
                    
                    if stop then
                        break
                    end
                    
                end
                
            end
            
            return stop
            
        end
        
    end
    
    return false
    
end