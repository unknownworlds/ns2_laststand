// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\TitleBar.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load('lua/menu/MenuElement.lua')
Script.Load('lua/menu/MenuButton.lua')

local kDefaultBackgroundColor = Color(0.2, 0.2, 0.2)
local kDefaultHeight = 26
local kDefaultFontSize = 20
local kDefaultFontColor = Color(0.77, 0.44, 0.22)
local kWindowNameOffset = Vector(30, 0, 0)
local kDefaultTitleBarFontName = "fonts/Arial_15.fnt"
local kDefaultBackgroundTexture = ""

class 'TitleBar' (MenuElement)

function TitleBar:GetTagName()
    return "titlebar"
end

function TitleBar:Initialize()

    MenuElement.Initialize(self)
    
    self:SetHeight(kDefaultHeight)
    self:GetBackground():SetColor(kDefaultBackgroundColor)
    self:SetBackgroundTexture(kDefaultBackgroundTexture)
    self:SetIgnoreMargin(true)
    
    self.closeButton = CreateMenuElement(self, "MenuButton", false)
    self.closeButton:SetCSSClass("close", false)

    self.isDragged = false
    
    local eventCallBacks = {
    
        OnMouseOver = function (self, mousePressed)
            self:Drag(mousePressed)
        end,

        OnMouseOut = function (self, mousePressed)
            self:Drag(mousePressed)
        end,

        OnMouseDown = function (self)
            self.isDragged = true
        end,

        OnMouseUp = function (self)
            self.isDragged = false
        end,
    
    }
    
    self:AddEventCallbacks(eventCallBacks)

end

function TitleBar:Uninitialize()

    if self.closeButton then
        self.closeButton:Uninitialize()
        self.closeButton = nil
    end
    
    MenuElement.Uninitialize(self)

end

function TitleBar:Drag(mousePressed)

    if self.isDragged and self:GetParent().canBeDragged then
    
        if not mousePressed or not self:GetParent() then
            self.isDragged = false
            return
        end

        // move the window
        local windowPos = self:GetParent():GetBackground():GetPosition()
        windowPos = windowPos + MouseTracker_GetMouseMovement()
        
        local horizontalAlign, verticalAlign = self:GetParent():GetAlign()
        local xOffset = 0
        local yOffset = 0
        
        if horizontalAlign == GUIItem.Center then
            xOffset = -Client.GetScreenWidth() / 2
        elseif horizontalAlign == GUIItem.Right then
            xOffset = -Client.GetScreenWidth()
        end
        
        if verticalAlign == GUIItem.Middle then
            yOffset = -Client.GetScreenHeight() / 2
        elseif verticalAlign == GUIItem.Bottom then
            yOffset = -Client.GetScreenHeight()
        end
        
        windowPos.x = Clamp(windowPos.x, xOffset, Client.GetScreenWidth() - self.background:GetSize().x + xOffset)
        windowPos.y = Clamp(windowPos.y, yOffset, Client.GetScreenHeight() - self.background:GetSize().y + yOffset)
        
        self:GetParent():SetBackgroundPosition(windowPos, true)   
    
    end

end

function TitleBar:SetWidth(width, isPercentage, time, animateFunc, callBack)

    MenuElement.SetWidth(self, width, isPercentage, time, animateFunc, callBack)
    
    if self.closeButton then
        self.closeButton:ReloadCSSClass()
    end
    
end

function TitleBar:OnParentChanged()

    self:SetWidth(1.0, true)

end