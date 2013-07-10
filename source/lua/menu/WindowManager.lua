// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\WindowManager.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Holds all window instances, tracks mouse states, controls clicking/events and sorts
//    hud layers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kWindowLayerDefault = 0
kWindowLayerMainMenu = 20

Script.Load("lua/menu/MouseTracker.lua")
Script.Load("lua/menu/Window.lua")
Script.Load("lua/menu/MenuMixin.lua")

local gWindowManager = nil
function GetWindowManager()
    return gWindowManager
end

class 'WindowManager'

function WindowManager:OnMouseMove(pressed)

    local element = self.lastRelevantElement
    local window = self.lastActiveWindow

    if not pressed then
        element, window = self:GetRelevantElement(MouseTracker_GetCursorPos())
    end   
    
    // handle mouse out:
    if self.lastRelevantElement and self.lastRelevantElement ~= element and self.lastRelevantElement.OnMouseOut then
        self.lastRelevantElement:OnMouseOut(MouseTracker_GetIsLeftButtonPressed())
    end
    
    // handle mouse in:
    if self.lastRelevantElement and self.lastRelevantElement ~= element and self.lastRelevantElement.OnMouseIn then
        self.lastRelevantElement:OnMouseIn(MouseTracker_GetIsLeftButtonPressed())
    end
    
    // handle mouse over:
    if element and element.OnMouseOver then
        element:OnMouseOver(MouseTracker_GetIsLeftButtonPressed())
    end
    
    self.lastRelevantElement = element
    
    window = self:GetActiveWindow()
    self:HandleFocusBlur(window, nil)

end

function WindowManager:OnMouseWheel(up)

    if self.lastActiveWindow and self.lastActiveWindow.OnMouseWheel then
        self.lastActiveWindow:OnMouseWheel(up)
    end
    
end

function WindowManager:OnMouseDown(key, doubleClick)

    local element, window, windowLayer = self:GetRelevantElement(MouseTracker_GetCursorPos())

    if window then
        self:SetWindowActive(window, windowLayer)
        if window.OnMouseDown then
            window:OnMouseDown(key, doubleClick)
        end
    end

    if element and element.OnMouseDown then
        element:OnMouseDown(key, doubleClick)
    end
    
    window = self:GetActiveWindow()
    self:HandleFocusBlur(window, element)

end

function WindowManager:HandleFocusBlur(window, element)

    if window and window ~= self.lastActiveWindow then
    
        if self.lastActiveWindow and self.lastActiveWindow.OnBlur and self.lastActiveWindow:GetIsVisible() then
            self.lastActiveWindow:OnBlur()
        end
        
        if window and window.OnFocus then
            window:OnFocus()
        end    
        
        self.lastActiveWindow = window
        
    end

    if element and element ~= self.lastActiveElement then
    
        if self.lastActiveElement and self.lastActiveElement.OnBlur then
            self.lastActiveElement:OnBlur()
        end
        
        if element and element.OnFocus then
            element:OnFocus()
        end

        self.lastActiveElement = element
        
    end    

end

function WindowManager:OnMouseUp(key)
    
    local element, window, windowLayer = self:GetRelevantElement(MouseTracker_GetCursorPos())

    if element then

        if element.OnMouseUp then
            element:OnMouseUp(key)
        end
        
        if element.OnClick and key == InputKey.MouseButton0 then
            element:OnClick()
        end
        
    end
    
    window = self:GetActiveWindow()
    self:HandleFocusBlur(window, element)

end

function WindowManager:Initialize()
 
    self.windowLayers = {}
    self.layerOrder = {}
    
    MouseTracker_ListenToMovement(self)
    MouseTracker_ListenToWheel(self)
    MouseTracker_ListenToButtons(self)
    
    // used for OnMouseOver, OnMouseOut
    self.lastRelevantElement = nil
    
    // used for OnFocus, OnBlur
    self.lastActiveWindow = nil
    self.lastActiveElement = nil

end

local function CreateWindowManager()

    if gWindowManager == nil then
        local windowManager = WindowManager()
        windowManager:Initialize()
        return windowManager
    else
        Print("WindowManager was already created.")
        return gWindowManager
    end

end

gWindowManager = CreateWindowManager()

function WindowManager:Uninitialize()

    for index, windowLayers in ipairs(self.windowLayers) do
        for index, window in ipairs(windowLayer.windows) do
            window:Destroy()
        end
    end
    
    self.windowLayers = nil
    self.layerOrder = nil

end

function WindowManager:GetActiveWindow()

    for i = 1, #self.layerOrder do

        local windowLayer = self.windowLayers[self.layerOrder[i]]
        if #windowLayer.windowOrder > 0 then
        
            local index = #windowLayer.windowOrder
            for i = 1, #windowLayer.windowOrder do
            
                if windowLayer.windowOrder[index]:GetIsVisible() then
                    return windowLayer.windowOrder[index], windowLayer
                end
            
                index = index - 1
                
            end
            
        end 
        
    end    
    
end

local function HandleKeyEventCallbacks(key, down, item)
    
    local stop = false

    if down then
        if (key == InputKey.NumPadEnter or key == InputKey.Return) and item.OnEnter then
            stop = item:OnEnter()
        elseif key == InputKey.Tab and item.OnTab then
            stop = item:OnTab()
        elseif key == InputKey.Escape and item.OnEscape then
            stop = item:OnEscape()
        end
    end
    
    return stop

end

// Return true if the event should be stopped here.
function WindowManager:SendKeyEvent(key, down, amount)

    if not Shared.GetIsRunningPrediction() then
        
        local activeWindow = self:GetActiveWindow()
        local stop = false

        if activeWindow == nil then
            return
        end
        
        if self.lastActiveElement then
            stop = HandleKeyEventCallbacks(key, down, self.lastActiveElement)            
            if not stop and self.lastActiveElement.OnSendKey then
                stop = self.lastActiveElement:OnSendKey(key, down, amount)
            end
            
        end
        
        if not stop then
            stop = HandleKeyEventCallbacks(key, down, activeWindow)
            if not stop and activeWindow.OnSendKey then
                stop = activeWindow:OnSendKey(key, down, amount)
            end
        end
        
        activeWindow = self:GetActiveWindow()
        self:HandleFocusBlur(activeWindow, nil)
        
        return stop
    end

    return false    
    
end

// Return true if the event should be stopped here.
function WindowManager:SendCharacterEvent(character)

    local window = self:GetActiveWindow()
    local stop = false
    
    if self.lastActiveElement and self.lastActiveElement.OnSendCharacter then
        stop = self.lastActiveElement:OnSendCharacter(character)
    end
    
    if not stop and window and window.OnSendCharacter then
        stop = window:OnSendCharater(character)
    end
    
    return stop

end

// checks the ordered window list (top/active window first)
function WindowManager:GetRelevantElement(pos)

    for i = 1, #self.layerOrder do
    
        local windowLayer = self.windowLayers[self.layerOrder[i]]
        
        local index = #windowLayer.windowOrder
        for i = 1, #windowLayer.windowOrder do
        
            local windowVisible = windowLayer.windowOrder[index]:GetIsVisible()
            local posInWindow = GUIItemContainsPoint(windowLayer.windowOrder[index]:GetBackground(), pos.x, pos.y)
            if windowVisible and posInWindow then
            
                local childAtPos = windowLayer.windowOrder[index]:GetChildAtPos(pos)
                if childAtPos and childAtPos:GetIsVisible() then
                    return childAtPos, windowLayer.windowOrder[index], windowLayer
                end
                
            end
            
            index = index - 1
            
        end
        
    end
    
end

function WindowManager:Update(deltaTime)

    Print("WindowManager:Update(%s)", ToString(deltaTime))

end

function WindowManager:CreateWindow(scriptHandle, windowLayer)

    assert(scriptHandle ~= nil)
    assert(HasMenuMixin(scriptHandle))
    
    if windowLayer == nil then
        windowLayer = 0
    end
    
    if not self.windowLayers[windowLayer] then
        self.windowLayers[windowLayer] = {
            windows = {},
            windowOrder = {},
            offset = windowLayer
        }
        
        // insert sorted, descending:
        local inserted = false
        for index, layerIndex in ipairs(self.layerOrder) do
        
            if layerIndex <= windowLayer then
                table.insert(self.layerOrder, index, windowLayer)
                inserted = true
                break
            end 
        
        end
        
        if not inserted then
            table.insert(self.layerOrder, windowLayer)
        end
        
    end
    
    local window = Window()
    table.insert(self.windowLayers[windowLayer].windows, window)
    table.insert(self.windowLayers[windowLayer].windowOrder, window)
    
    window:SetScriptHandle(scriptHandle)
    window:Initialize()
    window:SetLayer(table.count(self.windowLayers[windowLayer].windowOrder) + windowLayer)
    
    window:SetCSSClass()
    
    return window
    
end

function WindowManager:RemoveWindow(window, windowLayer)
    
    if not windowLayer then
        windowLayer = 0
    end

    table.removevalue(self.windowLayers[windowLayer].windows, window)
    table.removevalue(self.windowLayers[windowLayer].windowOrder, window)

    self.lastActiveWindow = nil
    self.lastRelevantElement = nil

end

function WindowManager:SetWindowActive(newActiveWindow, windowLayer)

    if not newActiveWindow or newActiveWindow:GetCanSetActive() == false then
        return false
    end    
    
    if type(windowLayer) == "number" then
        windowLayer = self.windowLayers[windowLayer]
    end

    local currentActiveWindow = self:GetActiveWindow()
    
    // update hudlayers
    if newActiveWindow ~= currentActiveWindow then
    
        local newWindowOrder = {}
        for index, window in ipairs(windowLayer.windowOrder) do
            if window ~= newActiveWindow then
                table.insert(newWindowOrder, window)
            end
        end
        
        table.insert(newWindowOrder, newActiveWindow)
        
        windowLayer.windowOrder = newWindowOrder
        
        for index, window in ipairs(windowLayer.windowOrder) do
            window:SetLayer(index + windowLayer.offset)
        end
        
        return true
   
    end
    
    return false
    
end
