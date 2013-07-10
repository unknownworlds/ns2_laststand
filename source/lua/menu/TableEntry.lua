// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\TableEntry.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inTableEntryation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

class 'TableEntry' (MenuElement)

local kDefaultEntryWidth = 64
local kDefaultEntryHeight = 16
local kDefaultColor = Color(1, 1, 0, 0.5)

function TableEntry:Initialize()

    MenuElement.Initialize(self)
    
    self:SetIgnoreMargin(true)
    //self:SetIsScaling(false)
    self:SetBackgroundColor(kDefaultColor)
    self:SetWidth(kDefaultEntryWidth)
    self:SetHeight(kDefaultEntryHeight)
    self:EnableHighlighting()

end

function TableEntry:GetTagName()
    return "entry"
end

function TableEntry:SetHeight(height, isPercentage, time, animateFunc, animName, callBack)

    MenuElement.SetHeight(self, height, isPercentage, time, animateFunc, animName, callBack)
    local parent = self:GetParent()
    if parent and parent.InformRowHeight then
        parent:InformHeight(height)
    end   

end