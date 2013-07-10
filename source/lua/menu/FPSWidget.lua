// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\FPSWidget.lua
//
//    Created by:   Steven An (steve@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")
Script.Load("lua/menu/MenuButton.lua")
Script.Load("lua/menu/SlideButton.lua")

class 'FPSWidget' (FormElement)

local kDefaultOptionFontSize = 26
local kDefaultOptionFontName = "fonts/Arial_15.fnt"
local kDefaultOptionFontColor = Color(1,1,1,1)
local kDefaultSize = Vector(300, 48, 0)
local kDefaultBackgroundColor = Color(0,0,0,1)


function FPSWidget:Initialize()

    FormElement.Initialize(self)

    self:SetBorderHighlightColor( Color(0, 0, 0, 0) )
    self.optionTextColor = kDefaultOptionFontColor
    self.optionFontSize = kDefaultOptionFontSize
    self.optionFontName = kDefaultOptionFontName
    self:GetBackground():SetColor(Color(0, 0, 0, 0))

end
