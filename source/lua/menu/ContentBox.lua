// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\ContentBox.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    A plain content box that provides at interface for slide bars.
//
// ========= For more inContentBoxation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/menu/SlideBar.lua")

local kDefaultSize = Vector(200, 200, 0)
local kDefaultColor = Color(0.3, 0.3, 0.3, 1)
local kDefaultBorderWidth = 1
local kContentHeight = 4000

class 'ContentBox' (MenuElement)

function ContentBox:Initialize()

    MenuElement.Initialize(self)

    self.contentStencil = CreateGraphicItem(self)
    
    self.contentStencil:SetIsStencil(true)
    self.contentStencil:SetInheritsParentStencilSettings(false)
    self.contentStencil:SetClearsStencilBuffer(true)
    self:GetBackground():AddChild(self.contentStencil)
    
    self:SetBackgroundSize(kDefaultSize, true)
    self:GetBackground():SetColor(kDefaultColor)
    self:SetBorderWidth(kDefaultBorderWidth)
    self.contentSize = kDefaultSize
    
    self.contentBackground = CreateGraphicItem(self)
    
    self.contentBackground:SetColor(Color(0,0,0,0))
    self:GetBackground():AddChild(self.contentBackground)

end

function ContentBox:SetIsScaling(isScaling)

    MenuElement.SetIsScaling(self, isScaling)
    
    self.contentStencil:SetIsScaling(isScaling)
    self.contentBackground:SetIsScaling(isScaling)
    
end

function ContentBox:GetTagName()
    return "content"
end

function ContentBox:GetAvailableSpace()
    local width = self:GetWidth()
    return Vector(width, kContentHeight, 0)
end

function ContentBox:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)

    MenuElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)
    self.contentStencil:SetSize(self:GetBackground():GetSize(), time, animName, animateFunc, callBack)
    
end

function ContentBox:GetContentPosition()
    return self.contentBackground:GetPosition()
end

function ContentBox:OnSlide(slideFraction, align)

    local overHeadSize = self:GetContentSize() - self:GetBackground():GetSize()

    overHeadSize.x = math.max(0, overHeadSize.x)
    overHeadSize.y = math.max(0, overHeadSize.y)
    
    local deltaPos = overHeadSize * slideFraction
    local currentPos = self.contentBackground:GetPosition()
    
    if align == SLIDE_HORIZONTAL then
        currentPos.x = -deltaPos.x
    elseif align == SLIDE_VERTICAL then
        currentPos.y = -deltaPos.y
    end
    
    self.contentBackground:SetPosition(currentPos)
    
    for _, child in ipairs(self.children) do
        
        if child.OnParentSlide then
            child:OnParentSlide()
        end
        
    end

end

function ContentBox:AddChild(child)

    table.insert(self.children, 1, child)
    self.contentBackground:AddChild(child:GetBackground())
    
    child:SetParent(self)
    
    child:GetBackground():SetInheritsParentStencilSettings(false)
    child:GetBackground():SetStencilFunc(GUIItem.NotEqual)

end