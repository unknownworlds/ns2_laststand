// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\SlideButton.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load('lua/menu/MenuElement.lua')

local kDefaultSlideButtonFontSize = 24
local kDefaultSize = Vector(16, 16, 0)
local kDefaultBorderWidth = 1
local kDefaultTexture = ""
local kDefaultSlideButtonFontName = "fonts/Arial_15.fnt"
local kDefaultFontSize = 18
local kDefaultFontColor = Color(0.77, 0.44, 0.22)

class 'SlideButton' (MenuElement)

local function UpdatePosition(self)

    if self.verticalAlign == GUIItem.Bottom or self.horizontalAlign == GUIItem.Right then
        
        self:SetBottomOffset(0)
        self:SetRightOffset(0)
    
    end

end

function SlideButton:GetTagName()
    return "slidebutton"
end

function SlideButton:Initialize()

    MenuElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize)
    self:SetBorderWidth(kDefaultBorderWidth)
    self:SetBackgroundTexture(kDefaultTexture)
    self:SetIgnoreMargin(true)
    
    self:EnableHighlighting()

end

function SlideButton:SetWidth(width, isPercentage, time, animateFunc, callBack)

    MenuElement.SetWidth(self, width, isPercentage, time, animateFunc, callBack)
    
    UpdatePosition(self)
    
end

function SlideButton:SetHeight(height, isPercentage, time, animateFunc, animName, callBack)

    MenuElement.SetHeight(self, height, isPercentage, time, animateFunc, animName, callBack)
    
    UpdatePosition(self)
    
end
