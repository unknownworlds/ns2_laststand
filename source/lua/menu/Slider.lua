// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\menu\slider.lua
//
//    Created by:   Matt Calabrese (metaprogrammingtheworld@gmail.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")

local kDefaultBackgroundColor = Color(0, 0, 0, 0.8)
local kDefaultMarginLeft = 16
local kDefaultRange = { min = 0, max = 1 }
local kDefaultSize = Vector(350, 16, 0)
local kDefaultLeftArrowSize  = Vector(16, 24, 0)
local kDefaultRightArrowSize = Vector(16, 24, 0)
local kSlideButtonTexture = ""
local kDefaultButtonSize = Vector(24, 16, 0)

// A sensible default for when the user clicks left or right (5% of range)
// It's implemented as a function here so that the default is usable regardless of range
local kDefaultIntervalFunction = function(self) return (self.range.max - self.range.min) / 20 end

class 'Slider' (FormElement)

local function UpdateBarPosition(self)

    local pos = self.slideButton:GetBackground():GetPosition()
    local currentValue = self:GetValue()
    pos.x = (currentValue / self.range.max) * self:GetWidth()
    self.slideButton:GetBackground():SetPosition(pos)
    
end

function Slider:Initialize()

    FormElement.Initialize(self)
    
    self.range = kDefaultRange
    
    self.IntervalFunction = kDefaultIntervalFunction
    
    // By default have the bar work as though it is analog (such as for volume)
    // For something like player count, you'd want to clip to integers
    self.snapToInterval = false
    
    //self:SetChildrenIgnoreEvents(true)
    
    self:SetBorderWidth(0)
    
    // The left arrow button
    self.slideLeftButton = CreateMenuElement(self, "MenuButton", false)
    self.slideLeftButton:SetBorderWidth(0)
    self.slideLeftButton:SetBackgroundTexture(kArrowHorizontalButtonTexture)
    self.slideLeftButton:SetTextureCoords(kArrowMinCoords)
    self.slideLeftButton:SetCSSClass("slider_arrow")
    self.slideLeftButton:AddEventCallbacks({ OnClick = function(self) self:GetParent():SelectPrevious() end })
    
    // The bar button
    self.slideButton = CreateMenuElement(self, "MenuButton")
    self.slideButton:SetIsScaling(false)
    self.slideButton:SetIgnoreMargin(true)
    self.slideButton:SetBackgroundSize(kDefaultButtonSize)
    self.slideButton:SetBackgroundTexture(kSlideButtonTexture)
    self.slideButton:SetCSSClass("slider_button")
    local buttonEventCallbacks =
    {
        OnMouseOver =
            function(_, buttonPressed)
            
                if buttonPressed then
                
                    local backgroundX = self:GetBackground():GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight()).x
                    local cursorX = MouseTracker_GetCursorPos().x - backgroundX
                    cursorX = math.max(0, cursorX)
                    cursorX = math.min(self:GetWidth(), cursorX)
                    self:SetValue(math.min(self.range.max, math.max(self.range.min, cursorX / self:GetWidth())))
                    
                end
                
            end
    }
    self.slideButton:AddEventCallbacks(buttonEventCallbacks)
    
    // The right arrow button
    self.slideRightButton = CreateMenuElement(self, "MenuButton", false)
    self.slideRightButton:SetBorderWidth(0)
    self.slideRightButton:SetBackgroundTexture(kArrowHorizontalButtonTexture)
    self.slideRightButton:SetTextureCoords(kArrowMaxCoords)
    self.slideRightButton:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.slideRightButton:SetCSSClass("slider_arrow")
    self.slideRightButton:AddEventCallbacks({ OnClick = function(self) self:GetParent():SelectNext() end })
    
    local eventCallbacks =
    {
        OnFocus = function (self)
        end,
        
        OnBlur = function (self)
        end,
        
        OnEscape = function (self)
        end,
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    self:SetValue(self.range.min)
    self:SetMarginLeft(kDefaultMarginLeft)
    
    UpdateBarPosition(self)
    
end

function Slider:SetInterval(newInterval)

    self.intervalFunction = function(self) return newInterval end
    self:SnapToInterval()
    
end

function Slider:GetInterval()
    return self:IntervalFunction()
end

// TODO make this snap to fixed intervals (such as for player count snapping to integers, etc)
function Slider:SnapToInterval()

    if self.snapToInterval then
        // TODO implement this
    end
    
end

function Slider:SetLength(newLength)

    self.maxLength = newMaxLength
    // TODO resize the bar

end

function Slider:SetValue(value)

    FormElement.SetValue(self, value)
    
    UpdateBarPosition(self)
    
end

function Slider:OnSendKey(key, down)

  // TODO allow left and right to SelectPrevious and SelectNext

end

function Slider:SelectNext()
    self:SetValue(math.min(self.range.max, self:GetValue() + self:GetInterval()))
end

function Slider:SelectPrevious()
    self:SetValue(math.max(self.range.min, self:GetValue() - self:GetInterval()))
end

function Slider:GetTagName()
    return "slider"
end