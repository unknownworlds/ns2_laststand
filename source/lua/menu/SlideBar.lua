// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\SlideBar.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
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

class 'SlideBar' (FormElement)

local function UpdateSizing(self)

    local sizeVector = self:GetBackground():GetSize()
    local horizontal = not self:HasCSSClass("vertical")

    if self.slideRegion and self.buttonMin and self.buttonMax then
    
        if horizontal then
    
            local buttonMinWidth = self.buttonMin:GetWidth()
            local buttonMaxWidth = self.buttonMax:GetWidth()
            
            self.slideRegion:SetTopOffset( 0 )
            self.slideRegion:SetLeftOffset( buttonMinWidth )
            self.slideRegion:SetWidth( sizeVector.x - buttonMinWidth - buttonMaxWidth )
            self.slideRegion:SetHeight( sizeVector.y )

        else
        
            local buttonMinHeight = self.buttonMin:GetHeight()
            local buttonMaxHeight = self.buttonMax:GetHeight()
            
            self.slideRegion:SetTopOffset( buttonMinHeight )
            self.slideRegion:SetLeftOffset( 0 )
            self.slideRegion:SetWidth( sizeVector.x )
            self.slideRegion:SetHeight( sizeVector.y - buttonMinHeight - buttonMaxHeight )
        
        end
        
    end
    
end
    
local function Scroll(self, newPos)

    local buttonMaxSize = self.buttonMin:GetBackground():GetSize()
    local buttonMinSize = self.buttonMax:GetBackground():GetSize()
    local buttonSize = self.slideButton:GetBackground():GetSize()
    local slideBarSize = self:GetAvailableSpace()
    
    local horizontal = not self:HasCSSClass("vertical")
    
    if slideBarSize.x < slideBarSize.y then
    
        buttonMaxSize.x = 0
        buttonMinSize.x = 0
        
    else
    
        buttonMaxSize.y = 0
        buttonMinSize.y = 0
        
    end
    
    local maxPos = Vector(0, 0, 0)
    maxPos.x = slideBarSize.x - buttonSize.x - buttonMaxSize.x
    maxPos.y = slideBarSize.y - buttonSize.y - buttonMaxSize.y

    local pos = self.slideButton:GetBackground():GetPosition()
    if horizontal then
        pos.x = Clamp(newPos.x, buttonMinSize.x, maxPos.x)
    else
        pos.y = Clamp(newPos.y, buttonMinSize.y, maxPos.y)
    end
    
    self.slideButton:GetBackground():SetPosition(pos)
    
    local slideFractionX = ConditionalValue(maxPos.x > 0, (pos.x - buttonMinSize.x) / (slideBarSize.x - buttonSize.x - buttonMaxSize.x - buttonMinSize.x), 0)
    local slideFractionY = ConditionalValue(maxPos.y > 0, (pos.y - buttonMinSize.y) / (slideBarSize.y - buttonSize.y - buttonMaxSize.y - buttonMinSize.y), 0)
    
    self:UpdateSlidePercentage(slideFractionX, slideFractionY)
    
end

local function Drag(self, mousePressed)

    if self.isDragged then
    
        if not mousePressed or not self:GetParent() then
        
            self.isDragged = false
            return
            
        end
    

        // Using self.background.scale here is a bit of a hack but it works!
        self.buttonPos = self.buttonPos + (MouseTracker_GetMouseMovement() / self.background.scale)

        Scroll(self:GetParent(), self.buttonPos)
        
    end
    
end
    

function SlideBar:Initialize()

    MenuElement.Initialize(self)
    
    self:GetBackground():SetColor(Color(0, 0, 0, 0))
    
    self.slideFractionX = 0
    self.slideFractionY = 0
    
    self:SetIgnoreMargin(true)
    self:SetBackgroundSize(kDefaultSize, true)
    self:SetBorderWidth(kDefaultBorderWidth)
    self:SetHorizontal()
    
    self.slideRegion = CreateMenuElement(self, "Image")
    self.slideRegion:SetBackgroundColor( Color(1, 0, 0, 1) )
    
    self.slideButton = CreateMenuElement(self, "MenuButton")
    self:SetIgnoreMargin(true)
    self.slideButton:SetBackgroundSize(kDefaultButtonSize)
    self.slideButton:SetCSSClass("slide_button")
    
    self.buttonMin = CreateMenuElement(self, "SlideButton")
    self.buttonMin:SetCSSClass("min")
    self.buttonMin:SetIgnoreMargin(true)
    
    self.buttonMax = CreateMenuElement(self, "SlideButton")
    self.buttonMax:SetCSSClass("max")
    self.buttonMax:SetIgnoreMargin(true)
    
    self.slideListeners = { }
    
    local eventCallbacks =
    {
        OnMouseOver = function (self, mousePressed)
            Drag(self, mousePressed)
        end,
        
        OnMouseOut = function (self, mousePressed)
            Drag(self, mousePressed)
        end,        
        
        OnMouseDown = function (self)

            self.isDragged = true
            self.buttonPos = self:GetBackground():GetPosition()
            
        end,        
        
        OnMouseUp = function (self)
            self.isDragged = false
        end
    }
    
    self.slideButton:AddEventCallbacks(eventCallbacks)
    
    // Allow clicks any where on the slide region
    self.slideRegion:AddEventCallbacks(
    {
        OnMouseDown = function(self)
            local slideButton = self:GetParent().slideButton
        // Move button to mouse position
            local sliderPos = self:GetParent():GetBackground():GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
            local relativeMousePos = (MouseTracker_GetCursorPos() - sliderPos)/slideButton.background.scale
            slideButton.buttonPos = relativeMousePos - slideButton.background:GetSize()/2
            Scroll(self:GetParent(), slideButton.buttonPos)
            slideButton.isDragged = true
        end,

        // We need this here, because if we clicked the region, it will get mouse over events, not the slide button
        OnMouseOver = function(self, mousePressed)
            local slideButton = self:GetParent().slideButton
            Drag(slideButton, mousePressed)
        end
            
    })
    
    self.buttonMin:AddEventCallbacks(
    {
        OnClick = function(self)
            self:GetParent():ScrollMin()
        end
    })
    
    self.buttonMax:AddEventCallbacks(
    {
        OnClick = function(self)
            self:GetParent():ScrollMax()
        end
    })
    
    // our own events here
    self.setValueCallbacks = {}
    
end

function SlideBar:Reset()
    Scroll(self, Vector(0, 0, 0))
end

function SlideBar:GetMinButton()
    return self.buttonMin
end

function SlideBar:GetMaxButton()
    return self.buttonMax
end    

function SlideBar:GetTagName()
    return "slidebar"
end

function SlideBar:ScrollMin()
    Scroll(self, self.slideButton:GetBackground():GetPosition() - Vector(16, 16, 0))
end

function SlideBar:ScrollMax()
    Scroll(self, self.slideButton:GetBackground():GetPosition() + Vector(16, 16, 0))
end

function SlideBar:SetValue(value)

    // scrollValue set in UpdateSlidePercentage() below through the Scroll() function.
    local minButtonSize = self.buttonMin:GetAvailableSpace()
    local maxButtonSize = self.buttonMax:GetAvailableSpace()
    local buttonSize = self.slideButton:GetAvailableSpace()
    local slideBarSize = self:GetAvailableSpace()
    
    local backgroundSize = slideBarSize.x - minButtonSize.x - maxButtonSize.x - buttonSize.x
    
    Scroll(self, Vector((value * backgroundSize) + minButtonSize.x, 0, 0))
    
end

function SlideBar:GetValue()
    return self.scrollValue
end

function SlideBar:UpdateSlidePercentage(slideFractionX, slideFractionY)

    self.slideFractionX = slideFractionX
    self.slideFractionY = slideFractionY
    
    self.scrollValue = self:HasCSSClass("vertical") and self.slideFractionY or self.slideFractionX
    
    local parent = self:GetParent()
    
    // Notifiy listeners.
    for index, listener in ipairs(self.slideListeners) do
    
        local interest = listener.Interest
        local value = ConditionalValue(interest == SLIDE_VERTICAL, slideFractionY, slideFractionX)
        
        listener.Object:OnSlide(value, interest)
        
    end
    
    for _, callback in ipairs(self.setValueCallbacks) do
        callback(self)
    end
    
end

function SlideBar:Register(object, align)

    if align ~= SLIDE_VERTICAL and align ~= SLIDE_HORIZONTAL then
        Print("SlideBar:Register(object, align) wrong align passed.")
    end
    
    if object and object.OnSlide then
        table.insert( self.slideListeners, { Object = object, Interest = align } )
    else
        Print("SlideBar:Register(object, align) requires passed object to implement OnSlide(slideFraction, align).")
    end
    
end

function SlideBar:SetBackgroundColor(color, time, animateFunc, animName, callBack)

    if self.slideRegion then
        self.slideRegion:SetBackgroundColor(color)
    end
    
end

function SlideBar:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)
    
    FormElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)
    UpdateSizing(self)    
    
end

function SlideBar:SetVertical()

    self:RemoveClass('horizontal')
    self:AddClass('vertical')
    
    UpdateSizing(self)

end

function SlideBar:SetHorizontal() 

    self:RemoveClass('vertical')
    self:AddClass('horizontal')
    
    UpdateSizing(self)
    
end

function SlideBar:SetIsScaling(isScaling)

    FormElement.SetIsScaling(self, isScaling)
    
    self.slideButton:SetIsScaling(isScaling)
    self.buttonMin:SetIsScaling(isScaling)
    self.buttonMax:SetIsScaling(isScaling)
    
end

function SlideBar:SetCSSClass(cssClassName, updateChildren)

    MenuElement.SetCSSClass(self, cssClassName, updateChildren)
    
    if self.value then
        self:SetValue(self:GetValue())
    end
    
end
