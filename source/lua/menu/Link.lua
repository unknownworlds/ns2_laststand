// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Link.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/Font.lua")

local kDefaultNormalColor = Color(.8, .5, .2, 1)
local kDefaultHoverColor = Color(.9, .7, .4, 1)

class 'Link' (Font)

function Link:Initialize()

    Font.Initialize(self)
    
    self:SetTextColor(kDefaultNormalColor)
    self:SetHoverTextColor(kDefaultHoverColor)
    
    self:SetIgnoreEvents(false)
    
end

function Link:GetTagName()
    return "link"
end