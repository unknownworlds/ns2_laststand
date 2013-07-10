// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\MenuElement.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Basic class for menu elements. Has a background and borders.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/WindowUtility.lua")
Script.Load("lua/menu/CSSParser.lua")

local LEFT = 1
local RIGHT = 2
local TOP = 3
local BOTTOM = 4

local kDefaultBorderWidth = 0
local kDefaultBackgroundSize = Vector(10, 10, 0)
local kDefaultBorderColor = Color(0.7, 0.4, 0.2)

local kDefaultColor = Color(0.7, 0.7, 0.7)
local kDefaultHighlightColor = Color(1, 1, 1)

class 'MenuElement'

local function SetRepeatTexturePixelCoords(self)
    local backgroundSize = self.background:GetSize()
    self.background:SetTexturePixelCoordinates(0, 0, backgroundSize.x, backgroundSize.y)
end

local function CreateBorders(self)

    self.border = {}

    self.border[TOP] = CreateGraphicItem(self)
    self.border[TOP]:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.border[TOP]:SetColor(kDefaultBorderColor)
    self.border[TOP]:SetIsVisible(false)
    
    self.border[BOTTOM] = CreateGraphicItem(self)
    self.border[BOTTOM]:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.border[BOTTOM]:SetColor(kDefaultBorderColor)
    self.border[BOTTOM]:SetIsVisible(false)
    
    self.border[LEFT] = CreateGraphicItem(self)
    self.border[LEFT]:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.border[LEFT]:SetColor(kDefaultBorderColor)
    self.border[LEFT]:SetIsVisible(false)
    
    self.border[RIGHT] = CreateGraphicItem(self)
    self.border[RIGHT]:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.border[RIGHT]:SetColor(kDefaultBorderColor)
    self.border[RIGHT]:SetIsVisible(false)
    
    for index, border in ipairs(self.border) do
        self.background:AddChild(border)
    end

end

local function DestroyBorders(self)

    if self.border then

        for index, border in ipairs(self.border) do
            DestroyGUIItem(border)
        end
    
    end
    
    self.border = {}

end

local function ReloadBorders(self, time, func, animName, callback)
    
    if not self.border and self.allowBorders ~= false then
        CreateBorders(self)
    end
    
    local isVisible = self.borderStyle.Width > 0
    for index, border in ipairs(self.border) do
        border:SetIsVisible(isVisible)
    end
    
    // continue only if the borders are visible
    if isVisible then
    
        local width = self.borderStyle.Width
    
        local borderSize = Vector(self.background:GetSize())
        borderSize.x = borderSize.x + 2 * width
        borderSize.y = borderSize.y

        // animname is only set for one element, otherwise we cause 8 callbacks instead of 1
        self.border[TOP]:SetIsScaling(self.isScaling)
        self.border[TOP]:SetPosition(Vector(-width, -width, 0), time, animName, func, callback)
        self.border[TOP]:SetSize(Vector(borderSize.x, width, 0), time, nil, func, callback)
        
        self.border[BOTTOM]:SetIsScaling(self.isScaling)
        self.border[BOTTOM]:SetPosition(Vector(-width, 0, 0), time, nil, func, callback)
        self.border[BOTTOM]:SetSize(Vector(borderSize.x, width, 0), time, nil, func, callback)

        self.border[LEFT]:SetIsScaling(self.isScaling)
        self.border[LEFT]:SetPosition(Vector(-width, 0, 0), time, nil, func, callback)
        self.border[LEFT]:SetSize(Vector(width, borderSize.y, 0), time, nil, func, callback)

        self.border[RIGHT]:SetIsScaling(self.isScaling)
        self.border[RIGHT]:SetPosition(Vector(0, 0, 0), time, nil, func, callback)
        self.border[RIGHT]:SetSize(Vector(width, borderSize.y, 0), time, nil, func, callback)
    
    end
        
end

local function InformParent(self)

    assert(not self.lockInformEvent)
    self.lockInformEvent = true

    local parent = self:GetParent()
    if parent and parent.OnChildChanged then
        parent:OnChildChanged(self)
    end
    
    self.lockInformEvent = false
 
end

local function InformChildren(self)

    assert(not self.lockInformEvent)
    self.lockInformEvent = true
    
    for index, child in ipairs(self.children) do
        if child.OnParentChanged then
            child:OnParentChanged()
        end
    end
    
    
    self.lockInformEvent = false
end

function MenuElement:Initialize()
    
    self.desiredSize = Vector(0, 0, 0)
    self.desiredPos = Vector(0, 0, 0)
    
    self.isScaling = true
    self.ignoreMargin = true
    
    self.layer = 0
    
    self.minWidth = 0
    self.minHeight = 0
    
    self.background = CreateGraphicItem(self)
    self.background:SetSize(kDefaultBackgroundSize)
    
    self.borderStyle = {
        Width = kDefaultBorderWidth,
        OffSet = 0
    }
    
    if self.allowBorders ~= false then
        CreateBorders(self)
    end
    
    self.children = {}
    
    self.isVisible = true
    self.lockInformEvent = false
    self.verticalAlign = GUIItem.Top
    self.horizontalAlign = GUIItem.Left
    self.background:SetAnchor(self.horizontalAlign, self.verticalAlign)
    
    self.margin = {}
    self.margin[TOP] = 0
    self.margin[RIGHT] = 0
    self.margin[BOTTOM] = 0
    self.margin[LEFT] = 0
    
    self.texCoords = { 0.0, 0.0, 1.0, 1.0 }
    self.desiredTexCoords = { 0.0, 0.0, 1.0, 1.0 }
    
    self.backgroundHoverColor = kDefaultHighlightColor
    self.backgroundNormalColor = kDefaultColor
    
    self.mouseInCallbacks = {}    
    self.mouseOverCallbacks = {}
    self.mouseOutCallbacks = {}
    self.mouseWheelCallbacks = {}
    self.clickCallbacks = {}
    self.mouseDownCallbacks = {}
    self.mouseUpCallbacks = {}
    self.escapeCallbacks = {}
    self.enterCallbacks = {}
    self.tabCallbacks = {}
    self.showCallbacks = {}
    self.hideCallbacks = {}
    self.scrollUpCallbacks = {}
    self.scrollDownCallbacks = {}
    self.focusCallbacks = {}
    self.blurCallbacks = {}

end

function MenuElement:Uninitialize()
    
    if self.border then
        DestroyBorders(self)
        self.border = nil
    end
    
    if self.background then
        DestroyGUIItem(self.background)
        self.background = nil
    end
    
    local parent = self:GetParent()
    if parent then
        parent:RemoveChild(self)
    end
    
end

// not recommened to use, only for optimization
function MenuElement:DisableBorders()
    self.allowBorders = false
    DestroyBorders(self)
end

function MenuElement:EnableBorders()
    self.allowBorders = true
    CreateBorders(self)
end


function MenuElement:GetTagName()
    Print("WARNING: MenuElement:GetTagName(), no tag name specified!")
    return ""
end

function MenuElement:GetAnchor()
    return self:GetAlign()
end    

function MenuElement:GetAlign()
    return self.horizontalAlign, self.verticalAlign
end    

function MenuElement:GetIsVisible()
    return self.background:GetIsVisible()
end

function MenuElement:GetIsScaling()
    return self.isScaling
end

function MenuElement:GetFirstChild()
    return self.children[1]
end

function MenuElement:GetParent()
    return self.parent
end   

// searches recursively for the 'deepest' child at that point
function MenuElement:GetChildAtPos(pos)

    local toReturn = self
    
    if not self:GetChildrenIgnoreEvents() then
    
        for index, child in ipairs(self.children) do
        
            local isContained, _, _, size, screenPosition = GUIItemContainsPoint(child:GetBackground(), pos.x, pos.y)
            
            if gDebugGUI and isContained and not child:GetIgnoreEvents() then
            
                DebugGUIRectangle(screenPosition, size)
                DebugGUIMessage(child)
                
            end
            
            if child:GetIsVisible() and isContained and not child:GetIgnoreEvents() then
                return child:GetChildAtPos(pos)
            end
            
        end
        
    end
    
    return toReturn
    
end

function MenuElement:GetLayer()
    return self.layer
end

function MenuElement:GetBackground()
    return self.background
end

function MenuElement:GetParentTagName()
    if self.parent then
        return self.parent:GetTagName()
    end    
end

function MenuElement:GetChildrenIgnoreEvents()
    return self.childrenIgnoreEvents
end

function MenuElement:GetIgnoreEvents()
    return self.ignoreEvents
end    

function MenuElement:GetAvailableSpace()
    return self.background:GetSize()
end    

function MenuElement:GetMargin()
    return self.margin
end

function MenuElement:GetDesiredPosition()
    return self.desiredPos
end

function MenuElement:GetDesiredSize()
    return self.desiredSize
end    

function MenuElement:GetMarginLeft()
    return self.margin[LEFT]
end

function MenuElement:GetMarginTop()
    return self.margin[TOP]
end

function MenuElement:GetMarginRight()
    return self.margin[RIGHT]
end

function MenuElement:GetMarginBottom()
    return self.margin[BOTTOM]
end

function MenuElement:GetExtents()

    // consider align
    local offset = Vector(0,0,0)
    
    local parent = self:GetParent()
    if parent then
    
        local parentSize = self.parent:GetBackground():GetSize()
    
        if self.horizontalAlign == GUIItem.Right then        
            offset.x = parentSize.x        
        elseif self.verticalAlign == GUIItem.Middle then
            offset.x  = parentSize.x/2
        end
        
        if self.verticalAlign == GUIItem.Bottom then        
            offset.y = parentSize.y        
        elseif self.verticalAlign == GUIItem.Center then
            offset.y  = parentSize.y/2
        end
    
    end
    
    return self.desiredPos + self.desiredSize + offset

end

// calculates the desired space of child elements
function MenuElement:GetContentSize()

    local size = Vector(0,0,0)
    local currentExtents = Vector(0,0,0)
    for _, child in ipairs(self.children) do
    
        if child:GetIsVisible() then
    
            currentExtents = child:GetExtents()
            
            if currentExtents.x > size.x then
                size.x = currentExtents.x
            end   
            
            if currentExtents.y > size.y then
                size.y = currentExtents.y
            end
        
        end
    
    end
    
    return size

end

function MenuElement:DumpChildren()

    for _, child in ipairs(self.children) do
        Print(ToString(child))
    end

end

function MenuElement:GetMinHeight()
    return self.minHeight
end

function MenuElement:GetMinWidth()
    return self.minWidth
end

function MenuElement:GetScaleDivider()

    local scaleDivider = 1
    
    if self.parent then
        scaleDivider = ConditionalValue(not self.parent:GetIsScaling() and self:GetIsScaling(), self.background.scale, 1)
    else
        scaleDivider = ConditionalValue(self:GetIsScaling(), self.background.scale, 1)
    end

    return scaleDivider
    
end

function MenuElement:GetWidth()
    return self.background:GetSize().x
end

function MenuElement:GetHeight()
    return self.background:GetSize().y
end

function MenuElement:SetIsVisible(isVisible)   

    if isVisible ~= self:GetIsVisible() then
        
        local success = true

        if isVisible and self.OnShow then
            success = self:OnShow()
        end
        
        if not isVisible and self.OnHide then
            success = self:OnHide()
        end
        
        // in case no return value was given
        if success == nil then
            success = true
        end    

        if success then
        
            self.background:SetIsVisible(isVisible)
            self.isVisible = isVisible

            for index, child in ipairs(self.children) do
                if child:GetInitialVisible() then
                    child:SetIsVisible(isVisible)
                end
            end  
          
        end
    
    end
    
end

function MenuElement:SetIsScaling(isScaling)

    if isScaling ~= self.isScaling then
        self.background:SetIsScaling(isScaling)
        self.isScaling = isScaling
        self:ReloadCSSClass()
        ReloadBorders(self)
    end
    
end    

function MenuElement:EnableHighlighting()

    local eventCallbacks = {
    
        OnMouseOver = function (self, buttonPressed)
            if self.backgroundHoverColor then
                self:GetBackground():SetColor(self.backgroundHoverColor)
            end
        end,

        OnMouseOut = function (self, buttonPressed)
            if self.backgroundNormalColor then
                self:GetBackground():SetColor(self.backgroundNormalColor)
            end
        end,
    
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    self:GetBackground():SetColor(self.backgroundNormalColor)
    
end

function MenuElement:ClearChildren()

    for i = 1, #self.children do
        self:GetFirstChild():Uninitialize()
    end
    
end 

function MenuElement:SetScriptHandle(scriptHandle)

    if self.scriptHandle then
        Print("WARNING: MenuElement already had a script handle assigned.")
    end
    
    self.scriptHandle = scriptHandle
    
end

function MenuElement:ReloadCSSClass(updateChildren)
    self:SetCSSClass()
end

function MenuElement:GetCSSClassNames()

    if self.cssClassNameTable then

        local names = ""
    
        for _, className in ipairs(self.cssClassNameTable) do
            
            names = names .. className .. " "

        end

        return names
    
    else
        return ""
    end

end

function MenuElement:SetCSSClass(cssClassName, updateChildren)

    if cssClassName ~= nil then
        self.cssClassNameTable = { cssClassName }
    end
    
    ApplyStylesTo(self,  "none")//self.cssClassNameTable and self.cssClassNameTable[1] or nil)
    
    if self.cssClassNameTable then
    
        for _, className in ipairs(self.cssClassNameTable) do
            ApplyStylesTo(self, className)
        end
    
    end
    
    if updateChildren ~= false then
    
        for index, child in ipairs(self.children) do
            child:ReloadCSSClass()
        end
        
    end
    
end

function MenuElement:HasCSSClass(className)
    return self.cssClassNameTable and table.contains(self.cssClassNameTable, className)
end

function MenuElement:AddCSSClass(cssClassName, updateChildren)

    if cssClassName ~= nil then

        if self.cssClassNameTable == nil then
            self.cssClassNameTable = {}
        end

        table.insert(self.cssClassNameTable, cssClassName)
        
    end

    self:ReloadCSSClass(updateChildren)

end

function MenuElement:AddClass(cssClassName, updateChildren)
    self:AddCSSClass(cssClassName, updateChildren)
end

function MenuElement:RemoveClass(cssClassName, updateChildren)

    if self.cssClassNameTable ~= nil then
        table.removevalue(self.cssClassNameTable, cssClassName)
    end

    self:ReloadCSSClass(updateChildren)

end

function MenuElement:SetParent(parent)

    self.parent = parent
    self:SetBackgroundPosition(self.desiredPos)
    
end

function MenuElement:AddChild(childElement)

    table.insert(self.children, 1, childElement)
    self.background:AddChild(childElement:GetBackground())
    
    childElement:SetParent(self)

end

function MenuElement:RemoveChild(childElement)
    table.removevalue(self.children, childElement)
end

function MenuElement:SetLayer(layer)

    self.layer = layer
    self.background:SetLayer(layer)

    for index, border in ipairs(self.border) do
        border:SetLayer(layer)
    end
    
    for index, child in ipairs(self.children) do
        child:SetLayer(layer)
    end

end

function MenuElement:OnMouseIn(buttonPressed)
    for _, callback in ipairs(self.mouseInCallbacks) do
        callback(self, buttonPressed)
    end
end

function MenuElement:OnMouseOver(buttonPressed)
    for _, callback in ipairs(self.mouseOverCallbacks) do
        callback(self, buttonPressed)
    end
end

function MenuElement:OnMouseOut(buttonPressed)
    for _, callback in ipairs(self.mouseOutCallbacks) do
        callback(self, buttonPressed)
    end
end

function MenuElement:OnMouseWheel(up)
    for _, callback in ipairs(self.mouseWheelCallbacks) do
        callback(self, up)
    end
end

function MenuElement:OnClick()
    for _, callback in ipairs(self.clickCallbacks) do
        callback(self)
    end
end

function MenuElement:OnMouseDown(key, doubleClick)
    for _, callback in ipairs(self.mouseDownCallbacks) do
        callback(self, key, doubleClick)
    end
end

function MenuElement:OnMouseUp(key)
    for _, callback in ipairs(self.mouseUpCallbacks) do
        callback(self, key)
    end
end

function MenuElement:OnEscape()

    local returnValues = {}
    
    for _, callback in ipairs(self.escapeCallbacks) do
    
        local returns = callback(self)
        
        if returns then
            table.insert(returnValues, returns)
        end
        
    end
    
    return unpack(returnValues)
    
end

function MenuElement:OnEnter()

    local returnValues = {}
    
    for _, callback in ipairs(self.enterCallbacks) do
    
        local returns = callback(self)
        
        if returns then
            table.insert(returnValues, returns)
        end
        
    end
    
    return unpack(returnValues)
end

function MenuElement:OnTab()

    local returnValues = {}
    
    for _, callback in ipairs(self.tabCallbacks) do
    
        local returns = callback(self)
        
        if returns then
            table.insert(returnValues, returns)
        end
        
    end
    
    return unpack(returnValues)
    
end

function MenuElement:OnShow()
    local returnValues = {}
    
    for _, callback in ipairs(self.showCallbacks) do
        local returns = callback(self)
        if returns ~= nil then
            table.insert(returnValues, returns)
        end
    end
    
    return unpack(returnValues)
end

function MenuElement:OnHide()
    local returnValues = {}
    
    for _, callback in ipairs(self.hideCallbacks) do
        local returns = callback(self)
        if returns ~= nil then
            table.insert(returnValues, returns)
        end
    end
    
    return unpack(returnValues)
end

function MenuElement:OnScrollUp()
    for _, callback in ipairs(self.scrollUpCallbacks) do
        callback(self)
    end
end

function MenuElement:OnScrollDown()
    for _, callback in ipairs(self.scrollDownCallbacks) do
        callback(self)
    end
end

function MenuElement:OnFocus()
    for _, callback in ipairs(self.focusCallbacks) do
        callback(self)
    end
end

function MenuElement:OnBlur()
    for _, callback in ipairs(self.blurCallbacks) do
        callback(self)
    end
end



function MenuElement:AddEventCallbacks(callbackMapping)

    if callbackMapping.OnMouseIn then
        table.insertunique(self.mouseInCallbacks, callbackMapping.OnMouseIn)
    end
    
    if callbackMapping.OnMouseOver then
        table.insertunique(self.mouseOverCallbacks, callbackMapping.OnMouseOver)
    end
    
    if callbackMapping.OnMouseOut then
        table.insertunique(self.mouseOutCallbacks, callbackMapping.OnMouseOut)
    end
    
    if callbackMapping.OnMouseWheel then
        table.insertunique(self.mouseWheelCallbacks, callbackMapping.OnMouseWheel)
    end
    
    if callbackMapping.OnClick then
        table.insertunique(self.clickCallbacks, callbackMapping.OnClick)
    end
    
    if callbackMapping.OnMouseDown then
        table.insertunique(self.mouseDownCallbacks, callbackMapping.OnMouseDown)
    end
    
    if callbackMapping.OnMouseUp then
        table.insertunique(self.mouseUpCallbacks, callbackMapping.OnMouseUp)
    end
    
    if callbackMapping.OnEscape then
        table.insertunique(self.escapeCallbacks, callbackMapping.OnEscape)
    end
    
    if callbackMapping.OnEnter then
        table.insertunique(self.enterCallbacks, callbackMapping.OnEnter)
    end
    
    if callbackMapping.OnTab then
        table.insertunique(self.tabCallbacks, callbackMapping.OnTab)
    end

    if callbackMapping.OnShow then
        table.insertunique(self.showCallbacks, callbackMapping.OnShow)
    end
    
    if callbackMapping.OnHide then
        table.insertunique(self.hideCallbacks, callbackMapping.OnHide)
    end   

    if callbackMapping.OnScrollUp then
        table.insertunique(self.scrollUpCallbacks, callbackMapping.OnScrollUp)
    end
  
    if callbackMapping.OnScrollDown then
        table.insertunique(self.scrollDownCallbacks, callbackMapping.OnScrollDown)
    end   
    
    if callbackMapping.OnFocus then
        table.insertunique(self.focusCallbacks, callbackMapping.OnFocus)
    end
    
    if callbackMapping.OnBlur then
        table.insertunique(self.blurCallbacks, callbackMapping.OnBlur)
    end

end

function MenuElement:SetChildrenIgnoreEvents(childrenIgnoreEvents)
    self.childrenIgnoreEvents = childrenIgnoreEvents
    
    for _, child in ipairs(self.children) do
        child:SetIgnoreEvents(self.childrenIgnoreEvents)
    end
    
end

function MenuElement:SetIgnoreEvents(ignoreEvents)
    self.ignoreEvents = ignoreEvents
end

function MenuElement:SetIgnoreMargin(ignoreMargin)
    self.ignoreMargin = ignoreMargin
    self:SetBackgroundSize(self.desiredSize)
    self:SetBackgroundPosition(self.desiredPos)
end

function MenuElement:SetBackgroundPosition(posVector, absolute, time, animateFunc, animName, callBack)

    if absolute == true then
        self.desiredPos = posVector
    end

    if self.parent and not self.ignoreMargin then
    
        local offset = Vector(0,0,0)
        local parentSize = self.parent:GetAvailableSpace() / self:GetScaleDivider()
        
        if self.horizontalAlign == GUIItem.Right then
            offset.x = -parentSize.x        
        elseif self.verticalAlign == GUIItem.Middle then
            offset.x  = -parentSize.x/2
        end
        
        if self.verticalAlign == GUIItem.Bottom then        
            offset.y = -parentSize.y        
        elseif self.verticalAlign == GUIItem.Center then
            offset.y  = -parentSize.y/2
        end
        
        local leftMargin = self.parent:GetMarginLeft() / self:GetScaleDivider()
        local rightMargin = self.parent:GetMarginTop() / self:GetScaleDivider()

        local minPos = Vector(0,0,0)
        minPos.x = leftMargin
        minPos.y = rightMargin
        minPos = minPos + offset
        
        posVector.x = posVector.x + leftMargin
        posVector.y = posVector.y + rightMargin
        
        local maxPos = Vector(0,0,0)
        maxPos.x = parentSize.x - self.parent:GetMarginRight() / self:GetScaleDivider()
        maxPos.y = parentSize.y - self.parent:GetMarginBottom() / self:GetScaleDivider()
        maxPos = maxPos + offset
        
        posVector.x = Clamp(posVector.x, minPos.x, maxPos.x)
        posVector.y = Clamp(posVector.y, minPos.y, maxPos.y)
        
    end

    self.background:SetPosition(posVector, time, animName, animateFunc, callBack)
    
    if not self.ignoreMargin then
        self:SetBackgroundSize(self.desiredSize, false)
    end

end

function MenuElement:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)

    if absolute == true then
        self.desiredSize = sizeVector
    end
    
    sizeVector.x = math.max(sizeVector.x, self.minWidth)
    sizeVector.y = math.max(sizeVector.y, self.minHeight)

    if self.parent and not self.ignoreMargin then
    
        local alignOffSet = Vector(0, 0, 0)
        local parentSize = self.parent:GetAvailableSpace() / self:GetScaleDivider()
        
        if self.horizontalAlign == GUIItem.Right then        
            alignOffSet.x = parentSize.x        
        elseif self.verticalAlign == GUIItem.Middle then
            alignOffSet.x  = parentSize.x/2
        end
        
        if self.verticalAlign == GUIItem.Bottom then        
            alignOffSet.y = parentSize.y        
        elseif self.verticalAlign == GUIItem.Center then
            alignOffSet.y  = parentSize.y/2
        end
    
        local extents = sizeVector + self.background:GetPosition()
        local maxSize = parentSize - Vector(self.parent:GetMarginRight() / self:GetScaleDivider(), self.parent:GetMarginBottom() / self:GetScaleDivider(), 0) - alignOffSet
        sizeVector.x = math.min(maxSize.x, extents.x)
        sizeVector.y = math.min(maxSize.y, extents.y)
        sizeVector = sizeVector - self.background:GetPosition()

    end

    self.background:SetSize(sizeVector, time, animName, animateFunc, callBack)

    InformParent(self)
    InformChildren(self)
    ReloadBorders(self)

    if self.backgroundRepeats then
        SetRepeatTexturePixelCoords(self)
    end
    
end

function MenuElement:GetInitialVisible()
    return self.initialVisible
end

function MenuElement:SetInitialVisible(visible)
    self.initialVisible = visible
end  

function MenuElement:SetAnchor(horizontalAlign, verticalAlign)
    self:SetAlign(horizontalAlign, verticalAlign)
end    

function MenuElement:SetAlign(horizontalAlign, verticalAlign)
    self.background:SetAnchor(horizontalAlign, verticalAlign)
    self.horizontalAlign = horizontalAlign
    self.verticalAlign = verticalAlign
end

function MenuElement:SetMinWidth(value)
    self.minWidth = value
end

function MenuElement:SetMinHeight(value)
    self.minHeight = value
end 
  
// called by css parser, API:

local gReuseVector = Vector(1,1,1)
function MenuElement:SetFontScale(fontScale, time, animateFunc, animName)
    self.background:SetScale(gReuseVector * fontScale)
end

function MenuElement:SetVerticalAlign(verticalAlign)
    self:SetAlign(self.horizontalAlign, verticalAlign)
end

function MenuElement:SetHorizontalAlign(horizontalAlign)
    self:SetAlign(horizontalAlign, self.verticalAlign)
end

function MenuElement:SetWidth(width, isPercentage, time, animateFunc, callBack)

    local newSize = self.background:GetSize()
    
    if isPercentage then
        
        if self.parent then
            width = width * self.parent:GetAvailableSpace().x / self:GetScaleDivider()
        else
            width = width * Client.GetScreenWidth() / self:GetScaleDivider()
        end
    
    end
    
    newSize.x = width
    
    self:SetBackgroundSize(newSize, true, time, animateFunc, callBack)

end


function MenuElement:SetHeight(height, isPercentage, time, animateFunc, animName, callBack)

    local newSize = self.background:GetSize()
    
    if isPercentage then
        
        if self.parent then
            height = height * self.parent:GetAvailableSpace().y / self:GetScaleDivider()
        else
            height = height * Client.GetScreenHeight() / self:GetScaleDivider()
        end
    
    end
    
    newSize.y = height
    
    self:SetBackgroundSize(newSize, true, time, animateFunc, animName, callBack)

end

function MenuElement:SetBackgroundTexture(fileName)

    self.background:SetTexture(fileName)
    self.background:SetTextureCoordinates(unpack(self.texCoords))
    
end

function MenuElement:SetTextureCoords(texCoords, time, animateFunc, animName, callBack)

    self.texCoords = texCoords
    local x1, y1, x2, y2 = unpack(texCoords)
    self.background:SetTextureCoordinates(x1, y1, x2, y2, time, animName, animateFunc, callBack)

end 

function MenuElement:SetTexturePixelCoords(texPixelCoords, time, animateFunc, animName, callBack)

    self.texPixelCoords = texPixelCoords
    local x1, y1, x2, y2 = unpack(texPixelCoords)
    self.background:SetTexturePixelCoordinates(x1, y1, x2, y2, time, animName, animateFunc, callBack)


end

function MenuElement:SetOpacity(opacityFraction, time, animateFunc, animName, callBack)

    local currentColor = self.background:GetColor()
    currentColor.a = opacityFraction

    self:SetBackgroundColor(currentColor, time, animateFunc, animName, callBack)
    
end

function MenuElement:SetBorderWidth(borderWidth, time, animateFunc, animName, callBack)

    self.borderStyle.Width = borderWidth
    
    if self.allowBorders ~= false then
        ReloadBorders(self, time, animateFunc, animName, callback)
    end
    
end

function MenuElement:SetBorderColor(color, time, animateFunc, animName, callBack)

    if self.allowBorders ~= false then

        self.border[TOP]:SetColor(color, time, animName, animateFunc, callBack)
        self.border[RIGHT]:SetColor(color, time, nil, animateFunc, callBack)
        self.border[BOTTOM]:SetColor(color, time, nil, animateFunc, callBack)
        self.border[LEFT]:SetColor(color, time, nil, animateFunc, callBack)
    
    end

end

function MenuElement:SetBackgroundColor(color, time, animateFunc, animName, callBack)
    
    self.backgroundNormalColor = color
    
    self.background:SetColor(color, time, animName, animateFunc, callBack)
    
end

function MenuElement:SetBackgroundRepeat(backgroundRepeats)
    self.backGroundRepeats = backgroundRepeats
    SetRepeatTexturePixelCoords(self)
end    

function MenuElement:SetBackgroundHoverColor(color)

    self.backgroundHoverColor = color
    
end

function MenuElement:SetTopOffset(yPos, isPercentage, time, animateFunc, animName, callBack)

    if isPercentage then
        
        local parent = self:GetParent()
        if parent then
            yPos = yPos * self.parent:GetAvailableSpace().y / self:GetScaleDivider()
        else
            yPos = yPos * Client.GetScreenHeight() / self:GetScaleDivider()
        end
    
    end

    local pos = self.background:GetPosition()
    pos.y = yPos
    self:SetBackgroundPosition(pos, true, time, animateFunc, animName, callBack)
    
end

function MenuElement:SetLeftOffset(xPos, isPercentage, time, animateFunc, animName, callBack)

    if isPercentage then
        
        local parent = self:GetParent()
        if parent then
            xPos = xPos * self.parent:GetAvailableSpace().y / self:GetScaleDivider()
        else
            xPos = xPos* Client.GetScreenWidth() / self:GetScaleDivider()
        end
    
    end

    local pos = self.background:GetPosition()
    pos.x = xPos
    self:SetBackgroundPosition(pos, true, time, animateFunc, animName, callBack)
    
end

function MenuElement:SetBottomOffset(bottomPos, isPercentage, time, animateFunc, animName, callBack)

    local positionOffset = 0

    if self.verticalAlign == GUIItem.Bottom then
    
        positionOffset = 0
    
    elseif self.verticalAlign == GUIItem.Center then
    
        if self.parent then
            positionOffset = self.parent:GetAvailableSpace().y / 2        
        else
            positionOffset = Client.GetScreenHeight() / 2
        end
    
    else
    
        if self.parent then        
            positionOffset = self.parent:GetAvailableSpace().y / self:GetScaleDivider()
        else
            positionOffset = Client.GetScreenHeight() / self:GetScaleDivider()
        end
        
    end
    
    if isPercentage then
        
        if self.parent then
            bottomPos = bottomPos * self.parent:GetAvailableSpace():GetSize().y / self:GetScaleDivider()
        else
            bottomPos = bottomPos* Client.GetScreenHeight() / self:GetScaleDivider()
        end
    
    end

    local pos = self.background:GetPosition()
    pos.y = positionOffset - bottomPos - self.background:GetSize().y
    
    
    self:SetBackgroundPosition(pos, true, time, animateFunc, animName, callBack)

end

function MenuElement:SetRightOffset(rightPos, isPercentage, time, animateFunc, animName, callBack)

    local positionOffset = 0

    if self.horizontalAlign == GUIItem.Right then
    
        positionOffset = 0
    
    elseif self.horizontalAlign == GUIItem.Middle then
    
        if self.parent then        
            positionOffset = self.parent:GetAvailableSpace().x / 2        
        else
            positionOffset = Client.GetScreenHeight() / 2
        end
    
    else
    
        if self.parent then        
            positionOffset = self.parent:GetAvailableSpace().x / self:GetScaleDivider()
        else
            positionOffset = Client.GetScreenWidth() / self:GetScaleDivider()
        end
        
    end
    
    if isPercentage then
        
        local parent = self:GetParent()
        if parent then
            rightPos = rightPos * self:GetParent():GetBackground():GetSize().y
        else
            rightPos = rightPos* Client.GetScreenWidth()
        end
    
    end

    local pos = self.background:GetPosition()

    pos.x = positionOffset - rightPos - self.background:GetSize().x
    self:SetBackgroundPosition(pos, true, time, animateFunc, animName, callBack)

end

function MenuElement:SetMarginTop(offset)
    self.margin[TOP] = offset
end

function MenuElement:SetMarginRight(offset)
    self.margin[RIGHT] = offset
end

function MenuElement:SetMarginBottom(offset)
    self.margin[BOTTOM] = offset
end

function MenuElement:SetMarginLeft(offset)
    self.margin[LEFT] = offset
end

function MenuElement:SetFrameCount(framecount, time, animateFunc, animName, callBack)
    self.background:SetTextureAnimation(framecount, time, animName, animateFunc, callBack)
end

function MenuElement:SetInheritOpacity(inheritOpacity)

    self.inheritOpacity = inheritOpacity
    self.background:SetInheritsParentAlpha(inheritOpacity)
    
    if self.allowBorders ~= false then
    
        self.border[TOP]:SetInheritsParentAlpha(inheritOpacity)
        self.border[RIGHT]:SetInheritsParentAlpha(inheritOpacity)
        self.border[BOTTOM]:SetInheritsParentAlpha(inheritOpacity)
        self.border[LEFT]:SetInheritsParentAlpha(inheritOpacity)
    
    end
    
end    