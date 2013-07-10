// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\MenuButton.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load('lua/menu/MenuElement.lua')

local kDefaultMenuButtonFontSize = 24
local kDefaultSize = Vector(16, 16, 0)
local kDefaultBorderWidth = 1
local kDefaultMenuButtonFontName = "fonts/Arial_15.fnt"
local kDefaultFontSize = 18
local kDefaultFontColor = Color(0.77, 0.44, 0.22)

class 'MenuButton' (MenuElement)

function MenuButton:GetTagName()
    return "button"
end

function MenuButton:Initialize()

    MenuElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize)
    self:SetBorderWidth(kDefaultBorderWidth)
    
    self.buttonText = CreateTextItem(self)
    self.buttonText:SetFontSize(kDefaultFontSize)
    self.buttonText:SetColor(kDefaultFontColor)
    self.buttonText:SetFontName(kDefaultMenuButtonFontName)
    self.buttonText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.buttonText:SetTextAlignmentX(GUIItem.Align_Center)
    self.buttonText:SetTextAlignmentY(GUIItem.Align_Center)
    self:GetBackground():AddChild(self.buttonText)
    
    self:EnableHighlighting()
    
end

function MenuButton:SetTextColor(color, time, animateFunc, animName, callBack)
    self.buttonText:SetColor(color, time, animName, animateFunc, callBack)
end

function MenuButton:SetText(text, time, animateFunc, animName, callBack)
    self.buttonText:SetText(text, time, animName, animateFunc, callBack)
end

function MenuButton:SetFontSize(fontSize, time, animateFunc, animName, callBack)
    self.buttonText:SetFontSize(fontSize, time, animName, animateFunc, callBack)
end

function MenuButton:SetFontName(fontName)
    self.buttonText:SetFontName(fontName)
end

function MenuButton:SetIsScaling(isScaling)

    MenuElement.SetIsScaling(self, isScaling)
    
    self.buttonText:SetIsScaling(isScaling)
    
end