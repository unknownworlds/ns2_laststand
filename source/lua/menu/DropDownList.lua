// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\DropDownList.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inDropDownListation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

class 'DropDownList' (MenuElement)

local kOptionTextSpacing = 6
local kDefaultSize = Vector(256, 256, 0)

local function ClearOptionsText(self)

    for index, optionText in ipairs(self.optionsText) do    
        optionText:Destroy()    
    end

    self.optionsText = {}
    
end

local function ReloadOptions(self)



end

function DropDownList:Initialize()

    MenuElement.Initialize(self)
    
    self.contentBox = CreateMenuElement(self, "ContentBox", false)
    
    self:SetBackgroundSize(kDefaultSize, true)
    
    self.optionsText = {}

end

function DropDownList:GetTagName()
    return "dropdownlist"
end

function DropDownList:OnOptionClicked(index)
    self:GetParent():SetOptionActive(index)
end

function DropDownList:_Reload()

    ClearOptionsText(self)
    
    local height = 24
    local totalheight = 0
    
    for index, option in ipairs(self:GetParent():GetOptions()) do
    
        local font = CreateMenuElement(self.contentBox, "Font", false)
        font:SetText(ToString(option))
        font.index = index
        font.dropdownHandle = self
        font:SetTopOffset( (index-1) * height )
        font:AddEventCallbacks({ OnClick = function (self) self.dropdownHandle:OnOptionClicked(self.index)  end })
        font:SetCSSClass("dropdownentry")
        
        totalheight = totalheight + height
    
    
    end
    
    totalheight = totalheight + 4
    self:SetHeight(totalheight)

end

function DropDownList:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)

    MenuElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)

    self.contentBox:SetBackgroundSize(self:GetBackground():GetSize(), absolute, time, animateFunc, animName, callBack)

end