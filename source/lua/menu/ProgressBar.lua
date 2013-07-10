// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\ProgressBar.lua
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")
Script.Load("lua/menu/MenuButton.lua")
Script.Load("lua/menu/SlideButton.lua")

local kDefaultSize = Vector(200, 32, 0)
local kDefaultButtonSize = Vector(16, 16, 0)
local kDefaultColor = Color(0.3, 0.3, 0.3, 0.0)
local kDefaultBorderWidth = 1

local kSlideButtonTexture = ""

SLIDE_VERTICAL = 1
SLIDE_HORIZONTAL = 2

class 'ProgressBar' (FormElement)

local function UpdateSizing(self)

    local sizeVector = self:GetBackground():GetSize()
    local horizontal = not self:HasCSSClass("vertical")
    
    local barSizeVector
    if self.bar ~= nil then
        barSizeVector = self.bar:GetBackground():GetSize()            
    else
        barSizeVector = sizeVector
    end

    if horizontal then
        barSizeVector.x = sizeVector.x
    else
        barSizeVector.y = sizeVector.y
    end

    if self.backgroundArea ~= nil then

        self.backgroundArea:SetTopOffset( 0 )
        self.backgroundArea:SetLeftOffset( 0 )
        self.backgroundArea:SetWidth( sizeVector.x )
        self.backgroundArea:SetHeight( sizeVector.y )
            
    end

    if self.bar ~= nil then    
        if self.value ~= nil and self.value > 0 then
        
            self.bar:SetIsVisible(true)        
            
            local width = barSizeVector.x
            local height = barSizeVector.y
            
            if horizontal then
                width = self.value * width                
            else
                height = self.value * height
            end
            
            self.bar:SetTopOffset( (sizeVector.y - barSizeVector.y) / 2 )
            self.bar:SetLeftOffset( (sizeVector.x - barSizeVector.x) / 2 )
            self.bar:SetWidth(width)
            self.bar:SetHeight(height)

        else
            self.bar:SetIsVisible(false)        
        end
    end
    
end

function ProgressBar:Initialize()

    MenuElement.Initialize(self)
    
    self:GetBackground():SetColor(Color(0, 0, 0, 0))
        
    self:SetIgnoreMargin(true)
    self:SetBackgroundSize(kDefaultSize, true)
    self:SetBorderWidth(kDefaultBorderWidth)
    self:SetHorizontal()
        
    self.backgroundArea = CreateMenuElement(self, "Image")
    self.backgroundArea:SetBackgroundColor( Color(1, 0, 0, 1) )
    
    self.bar = CreateMenuElement(self, "Image")
    self.bar:SetBackgroundColor( Color(0.8, 0.8, 0.8, 1) )
    self.bar:SetCSSClass("bar")
    
end

function ProgressBar:GetTagName()
    return "progressbar"
end

function ProgressBar:SetValue(value)
    self.value = Clamp(value, 0, 1)
    UpdateSizing(self)
end

function ProgressBar:GetValue()
    return self.value
end

function ProgressBar:SetBackgroundColor(color, time, animateFunc, animName, callBack)

    if self.backgroundArea then
        self.backgroundArea:SetBackgroundColor(color)
    end
    
end

function ProgressBar:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)
    
    FormElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)
    UpdateSizing(self)
    
end

function ProgressBar:SetVertical()

    self:RemoveClass('horizontal')
    self:AddClass('vertical')
    
    UpdateSizing(self)

end

function ProgressBar:SetHorizontal() 

    self:RemoveClass('vertical')
    self:AddClass('horizontal')
    
    UpdateSizing(self)
    
end

function ProgressBar:SetIsScaling(isScaling)

    FormElement.SetIsScaling(self, isScaling)
    self.backgroundArea:SetIsScaling(isScaling)
    self.bar:SetIsScaling(isScaling)
        
end

function ProgressBar:SetCSSClass(cssClassName, updateChildren)

    MenuElement.SetCSSClass(self, cssClassName, updateChildren)
    
    if self.value then
        self:SetValue(self:GetValue())
    end
    
end
