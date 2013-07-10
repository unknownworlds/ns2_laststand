// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\DropDown.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inDropDownation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")
Script.Load("lua/menu/DropDownList.lua")

class 'DropDown' (FormElement)

local kDefaultOptionFontSize = 26
local kDefaultOptionFontName = "fonts/Arial_15.fnt"
local kDefaultOptionFontColor = Color(1,1,1,1)
local kDefaultSize = Vector(300, 48, 0)
local kDefaultBackgroundColor = Color(0,0,0,1)

function DropDown:Initialize()

    FormElement.Initialize(self)
    
    self:SetBorderHighlightColor( Color(0, 0, 0, 0) )
    
    self.optionTextColor = kDefaultOptionFontColor
    self.optionFontSize = kDefaultOptionFontSize
    self.optionFontName = kDefaultOptionFontName
    
    self:GetBackground():SetColor(Color(0, 0, 0, 0))
    
    self.dropdownlist = CreateMenuElement(self, "DropDownList", false)
    self.dropdownlist:SetIsVisible(false)
    self.dropdownlist:SetInitialVisible(false)
    
    self.activeOption = CreateMenuElement(self, "MenuButton", false)
    self.activeOption:SetBorderWidth(0)
    self.activeOption:SetBackgroundColor(Color(0, 0, 0, 1))
    self.activeOption:SetBackgroundTexture("")
    self.activeOption:SetCSSClass("activeoption")
    
    self.activeOption:AddEventCallbacks({ OnClick = function(self) self:GetParent():CicleDropDown() end })
    
    self.scrollLeftButton = CreateMenuElement(self, "MenuButton", false)
    self.scrollLeftButton:SetBorderWidth(0)
    self.scrollLeftButton:SetBackgroundTexture(kArrowHorizontalButtonTexture)
    self.scrollLeftButton:SetTextureCoords(kArrowMinCoords)
    self.scrollLeftButton:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.scrollLeftButton:SetCSSClass("dropdownarrow")
    self.scrollLeftButton:AddEventCallbacks({ OnClick = function(self) self:GetParent():SelectPrevious() end })
    self.scrollLeftButton:SetIsVisible(false)
    
    self.scrollRightButton = CreateMenuElement(self, "MenuButton", false)
    self.scrollRightButton:SetBorderWidth(0)
    self.scrollRightButton:SetBackgroundTexture(kArrowHorizontalButtonTexture)
    self.scrollRightButton:SetTextureCoords(kArrowMaxCoords)
    self.scrollRightButton:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.scrollRightButton:SetCSSClass("dropdownarrow")
    self.scrollRightButton:AddEventCallbacks({ OnClick = function(self) self:GetParent():SelectNext() end })
    self.scrollRightButton:SetIsVisible(false)
    
    self.options = { }
    
    self:SetBackgroundColor(kDefaultBackgroundColor)
    
    self:SetIsScaling(true)
    
    self:SetBackgroundSize(kDefaultSize, true)
    
    self:SetHeight(self.activeOption:GetHeight())
    
end

function DropDown:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)
    
    FormElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)
    
    self.scrollRightButton:SetRightOffset(0)
    
    local arrowButtonWidth = self.scrollRightButton:GetWidth()
    self.activeOption:SetLeftOffset(arrowButtonWidth)
    
    local widthMinusButtons = self:GetWidth() - 2 * arrowButtonWidth
    self.activeOption:SetWidth(widthMinusButtons)
    self.activeOption:SetHeight(sizeVector.y)

    self.dropdownlist:SetWidth(widthMinusButtons)
    self.dropdownlist:SetHeight(sizeVector.y)
    
end

function DropDown:OnChildChanged(child)

    if child == self.activeOption then
        self.dropdownlist:SetTopOffset(self.activeOption:GetHeight())
    end
    
end

function DropDown:GetTagName()
    return "dropdown"
end

function DropDown:SetValue(value)

    FormElement.SetValue(self, value)
    
    if self.activeOption then
        self.activeOption:SetText(ToString(value))
    end
    
end

local function UpdateButtonVisibility(self)

    local value = self:GetValue()
    self.scrollRightButton:SetIsVisible(value ~= self.options[#self.options])
    self.scrollLeftButton:SetIsVisible(value ~= self.options[1])
    
end

function DropDown:SetOptions(options)

    self.options = options
    self.dropdownlist:_Reload()
    
    UpdateButtonVisibility(self)
    
end

function DropDown:GetOptions(options)
    return self.options
end

function DropDown:SetOptionActive(index)

    self:SetValue(self.options[index])
    UpdateButtonVisibility(self)
    
end

function DropDown:GetActiveOptionIndex()

    local currentValue = self:GetValue()
    local currentIndex = 1
    
    for index, option in ipairs(self.options) do
    
        if option == currentValue then
        
            currentIndex = index
            break
            
        end
        
    end
    
    return currentIndex
    
end

function DropDown:SetBackgroundColor(color, time, animateFunc, animName, callBack)

    if self.dropdownlist then
        self.dropdownlist:SetBackgroundColor(color, time, animateFunc, animName, callBack)
    end
    
    if self.activeOption then
        self.activeOption:SetBackgroundColor(color, time, animateFunc, animName, callBack)
    end
    
end

function DropDown:SelectNext()

    local currentIndex = self:GetActiveOptionIndex()
    
    currentIndex = math.min(#self.options, currentIndex + 1)
    self:SetValue(self.options[currentIndex])
    
    UpdateButtonVisibility(self)
    
end

function DropDown:SelectPrevious()

    local currentIndex = self:GetActiveOptionIndex()
    
    currentIndex = math.max(1, currentIndex - 1)
    self:SetValue(self.options[currentIndex])
    
    UpdateButtonVisibility(self)
    
end

function DropDown:CicleDropDown()

    local optionsLength = table.getn(self.options)
	local currentIndex = self:GetActiveOptionIndex()
	
    currentIndex = currentIndex % optionsLength + 1
    self:SetValue(self.options[currentIndex])
    
    UpdateButtonVisibility(self)
	
end