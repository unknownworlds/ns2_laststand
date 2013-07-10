// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Font.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

local TOP = 1
local RIGHT = 2
local BOTTOM = 3
local LEFT = 4

local kDefaultBackgroundColor = Color(1, 1, 1, 0.4)
local kDefaultBackgroundSize = Vector(64, 20, 0)
local kDefaultFontSize = 34
local kDefaultFontName = "fonts/Arial_15.fnt"
local kDefaultFontColor = Color(1, 0.4, 0.1)

class 'Font' (MenuElement)

local function UpdateBackGroundSize(self)

    local bgSize = Vector(0, 0, 0)
    
    local stringWidth = self.text:GetTextWidth(self.storedString)
    local backgroundWidth = self.textPadding[RIGHT] + self.textPadding[LEFT]
    
    if backgroundWidth > stringWidth * 1.3 then
        bgSize.x = backgroundWidth
    else
        bgSize.x = backgroundWidth + stringWidth        
    end
    
    self.text:SetPosition(Vector(self.textPadding[LEFT], self.textPadding[TOP], 0))
    
    bgSize.y = self.text:GetTextHeight(self.storedString) + self.textPadding[TOP] + self.textPadding[BOTTOM]
    
    self:SetBackgroundSize(bgSize, true)
    
end

function Font:Initialize()

    self.isClipped = false
    self.textWidth = 0
    self.textHeight = 0

    MenuElement.Initialize(self)
    
    self.textPadding = { 0, 0, 0, 0 }
    
    self.text = CreateTextItem(self)
    self.storedString = ""
    
    self:SetFontSize(kDefaultFontSize)
    self:SetFontName(kDefaultFontName)
    self:SetTextColor(kDefaultFontColor)
    
    self:GetBackground():AddChild(self.text)
    
    self:GetBackground():SetColor(kDefaultBackgroundColor)
    self:SetBackgroundSize(kDefaultBackgroundSize, true)
    
    local eventCallbacks =
    {
        OnMouseOver = function (self, buttonPressed)
            if self.hoverColor then
                self.text:SetColor(self.hoverColor)
            end
        end,
        
        OnMouseOut = function (self, buttonPressed)
            if self.normalColor then
                self.text:SetColor(self.normalColor)
            end
        end
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    self:SetIsScaling(true)
    
    self:SetIgnoreEvents(true)
    
end

function Font:GetTagName()
    return "font"
end

function Font:SetIsScaling(isScaling)

    MenuElement.SetIsScaling(self, self.text)    
    self.text:SetIsScaling(self.text)
    
    local scale = self:GetScaleDivider()
    self.text:SetTextClipped(self.isClipped, self.textWidth * scale, self.textHeight * scale)
    
end

function Font:SetText(text, time, animateFunc, animName, callBack)
 
    self.text:SetText(text, time, animName, animateFunc, callBack)
    self.storedString = text

    UpdateBackGroundSize(self)
    
end

function Font:SetTextColor(color)

    self.normalColor = color
    self.text:SetColor(color)
    
end

function Font:GetTextColor()
    return Color(self.normalColor.r, self.normalColor.g, self.normalColor.b, self.normalColor.a)
end

function Font:SetHoverTextColor(color)
    self.hoverColor = color
end

function Font:SetFontSize(fontSize)

    self.text:SetFontSize(fontSize)
    UpdateBackGroundSize(self)
    
end

function Font:SetFontName(fontName)

    self.text:SetFontName(fontName)
    UpdateBackGroundSize(self)
    
end

function Font:SetFontIsBold(fontIsBold)

    self.text:SetFontIsBold(fontIsBold)
    UpdateBackGroundSize(self)
    
end  

function Font:SetTextPadding(value)

    self.textPadding = { value, value, value, value }
    UpdateBackGroundSize(self)
    
end    

function Font:SetTextPaddingRight(value)

    self.textPadding[RIGHT] = value
    UpdateBackGroundSize(self)
    
end

function Font:SetTextPaddingLeft(value)

    self.textPadding[LEFT] = value
    UpdateBackGroundSize(self)
    
end

function Font:SetTextPaddingTop(value)

    self.textPadding[TOP] = value
    UpdateBackGroundSize(self)
    
end

function Font:SetTextPaddingBottom(value)

    self.textPadding[BOTTOM] = value
    UpdateBackGroundSize(self)
    
end

function Font:SetTextHorizontalAlign(value)

    self.text:SetTextAlignmentX(value)
    self.textXAlign = value
    
end

function Font:SetTextVerticalAlign(value)

    self.text:SetTextAlignmentY(value)
    self.textXAlign = value
    
end

function Font:SetInheritOpacity(inheritOpacity)

    MenuElement.SetInheritOpacity(self, inheritOpacity)
    
    self.text:SetInheritsParentAlpha(inheritOpacity)
    
end

function Font:SetTextClipped(isClipped, textWidth, textHeight)

    self.isClipped = isClipped == true
    self.textWidth = textWidth and textWidth or 0
    self.textHeight = textHeight and textHeight or 0

    local scale = self:GetScaleDivider()
    self.text:SetTextClipped(self.isClipped, self.textWidth * scale, self.textHeight * scale)
    
end