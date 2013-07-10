// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAnimatedItem.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages creation/destruction and update of animated gui items. There are no looping or oscilating
// animation types pre defined, but those can be easily realised through callbacks which gives way more
// control if desired.
//
// API:
//
// use "SetScale(scale)" to modify position, size changes
//
// 'SetFunction' should be whatever value you want to change (SetPosition, SetColor etc.))
// GUIAnimatedItem:SetFunction(value, time, animName, callBack, modFunction)
//
// exception: SetTexturePixelCoordinates(x1, y1, x2, y2, time ... )
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimationUtility.lua")

kAnimType = enum( {       'Text',
                          'WideText',
                          'NumberText',
                          'Color',
                          'Position',
                          'Size',
                          'Scale',
                          'TexCoords',
                          'TexPixCoords',
                          'FontSize',
                          'Fade',
                          'Pause',
                          'TextureAnimation'
                          
                          } )

local function SetAnimText(animatedItem, animation)
    
    local stringLengthFraction = math.ceil(animation.currentFraction * string.len(animation.endValue))
    local restLengthFraction = string.len(animatedItem.guiItem:GetText()) - stringLengthFraction
    
    local textFraction = string.sub(animation.endValue, 1, stringLengthFraction )
    local stringRest = string.sub(animatedItem.guiItem:GetText(), stringLengthFraction + 1)

    animatedItem.guiItem:SetText(textFraction .. stringRest)

end

local function SetAnimWideText(animatedItem, animation)
    
    local stringLengthFraction = math.ceil(animation.currentFraction * string.len(animation.endValue))
    local restLengthFraction = string.len(animatedItem.guiItem:GetWideText()) - stringLengthFraction
    
    local textFraction = string.sub(animation.endValue, 1, stringLengthFraction )
    local stringRest = string.sub(animatedItem.guiItem:GetWideText(), stringLengthFraction + 1)

    animatedItem.guiItem:SetWideText(textFraction .. stringRest)

end

local function SetNumberText(animatedItem, animation)

    local valueDifference = animation.endValue - animation.startValue
    local newValue = math.floor( (animation.startValue + (valueDifference * animation.currentFraction) ) * animatedItem.numberTextAccuracy) / animatedItem.numberTextAccuracy
    animatedItem.guiItem:SetText(tostring(newValue))

end

local function SetAnimColor(animatedItem, animation)
    
    local newColor = Color( animation.startValue.r + (animation.endValue.r - animation.startValue.r) * animation.currentFraction, 
                            animation.startValue.g + (animation.endValue.g - animation.startValue.g) * animation.currentFraction,
                            animation.startValue.b + (animation.endValue.b - animation.startValue.b) * animation.currentFraction,
                            animation.startValue.a + (animation.endValue.a - animation.startValue.a) * animation.currentFraction)

    animatedItem.guiItem:SetColor( newColor )
    
end

local function SetAnimPosition(animatedItem, animation)

    local valueDifference = animation.endValue - animation.startValue 

    if valueDifference.x == 0 then
        animation.startValue.x = animatedItem.guiItem:GetPosition().x
    end

    if valueDifference.y == 0 then
        animation.startValue.y = animatedItem.guiItem:GetPosition().y
    end
   
    animatedItem.guiItem:SetPosition( animation.startValue + (valueDifference * animation.currentFraction) )
    
end

local function SetAnimSize(animatedItem, animation)
    
    local valueDifference = animation.endValue - animation.startValue
    
    if valueDifference.x == 0 then
        animation.startValue.x = animatedItem.guiItem:GetSize().x
    end

    if valueDifference.y == 0 then
        animation.startValue.y = animatedItem.guiItem:GetSize().y
    end
    
    animatedItem.guiItem:SetSize( animation.startValue + (valueDifference * animation.currentFraction) )
    
end

local function SetAnimScale(animatedItem, animation)

    local valueDifference = animation.endValue - animation.startValue
    
    if valueDifference.x == 0 then
        animation.startValue.x = animatedItem.guiItem:GetScale().x
    end
    
    if valueDifference.y == 0 then
        animation.startValue.y = animatedItem.guiItem:GetScale().y
    end
    
    animatedItem.guiItem:SetScale(animation.startValue + (valueDifference * animation.currentFraction))
    
end

local function SetAnimTexPixCoords(animatedItem, animation)
    
    local newCoords =  { animation.startValue[1] + (animation.endValue[1] - animation.startValue[1]) * animation.currentFraction, 
                         animation.startValue[2] + (animation.endValue[2] - animation.startValue[2]) * animation.currentFraction,
                         animation.startValue[3] + (animation.endValue[3] - animation.startValue[3]) * animation.currentFraction,
                         animation.startValue[4] + (animation.endValue[4] - animation.startValue[4]) * animation.currentFraction }
    
    // we need to store this coordinates since there is no get function at the guiItem
    animatedItem.guiItem.texPixCoords = newCoords
    animatedItem.guiItem:SetTexturePixelCoordinates(unpack(newCoords))

end

local function SetAnimTexCoords(animatedItem, animation)
    
    local newCoords =  { animation.startValue[1] + (animation.endValue[1] - animation.startValue[1]) * animation.currentFraction, 
                         animation.startValue[2] + (animation.endValue[2] - animation.startValue[2]) * animation.currentFraction,
                         animation.startValue[3] + (animation.endValue[3] - animation.startValue[3]) * animation.currentFraction,
                         animation.startValue[4] + (animation.endValue[4] - animation.startValue[4]) * animation.currentFraction }
    
    // we need to store this coordinates since there is no get function at the guiItem
    animatedItem.guiItem.texCoords = newCoords
    animatedItem.guiItem:SetTextureCoordinates(unpack(newCoords))

end

local function SetAnimFontSize(animatedItem, animation)
    
    local valueDifference = animation.endValue - animation.startValue    
    animatedItem.guiItem:SetFontSize( animation.startValue + (valueDifference * animation.currentFraction) )

end

local function SetFade(animatedItem, animation)

    local valueDifference = animation.endValue - animation.startValue
    local currentColor = animatedItem.guiItem:GetColor()
    currentColor.a = animation.startValue + (valueDifference * animation.currentFraction)
    animatedItem.guiItem:SetColor(currentColor)

end

local function SetTextureAnimation(animatedItem, animation)

    local valueDifference = animation.endValue - animation.startValue
    local frameNumber = math.floor(valueDifference * animation.currentFraction)

    local newTexPixelCoords = {
        animatedItem.guiItem.texPixCoords[1],
        animatedItem.guiItem.texPixCoords[4] * frameNumber,
        animatedItem.guiItem.texPixCoords[3],
        animatedItem.guiItem.texPixCoords[4] + animatedItem.guiItem.texPixCoords[4] * frameNumber
    }

    animatedItem.guiItem:SetTexturePixelCoordinates(unpack(newTexPixelCoords))

end

local function Dummy(animatedItem, animation)
end

local gValueFunction = {}
gValueFunction[kAnimType.Text] = SetAnimText
gValueFunction[kAnimType.WideText] = SetAnimWideText
gValueFunction[kAnimType.NumberText] = SetNumberText
gValueFunction[kAnimType.Color] = SetAnimColor
gValueFunction[kAnimType.Position] = SetAnimPosition
gValueFunction[kAnimType.Size] = SetAnimSize
gValueFunction[kAnimType.Scale] = SetAnimScale
gValueFunction[kAnimType.TexPixCoords] = SetAnimTexPixCoords
gValueFunction[kAnimType.TexCoords] = SetAnimTexCoords
gValueFunction[kAnimType.FontSize] = SetAnimFontSize
gValueFunction[kAnimType.Fade] = SetFade
gValueFunction[kAnimType.Pause] = Dummy
gValueFunction[kAnimType.TextureAnimation] = SetTextureAnimation

local function CheckParameters(duration, name, modFunction, callBack)

    if time ~= nil then
        asserttype("duration", "number", duration)
    end
    
    if animName ~= nil then
        asserttype("name", "string", name)
    end
    
    if modFunction ~= nil then
        asserttype("modFunction", "function", modFunction)
    end
    
    if callBack ~= nil then
        asserttype("callBack", "function", callBack)
    end
    
end

local function GenerateAnimation(item, animType, duration, modFunction, callBack, name, startValue, endValue)

    assert(item ~= nil)
    assert(startValue ~= nil) 
    assert(endValue ~= nil) 
    
    CheckParameters(duration, name, modFunction, callBack)
    
    if name then
        item:DestroyAnimation(name)
    end
    
    local newAnim = {}
    
    newAnim.item = item
    newAnim.type = animType
    newAnim.duration = duration
    
    if modFunction == nil then
        newAnim.modFunction = AnimateLinear
    else
        newAnim.modFunction = modFunction
    end
    
    newAnim.callBack = callBack
    newAnim.name = name
    newAnim.currentFraction = 0.0
    newAnim.startValue = startValue
    newAnim.endValue = endValue
    newAnim.startTime = GetAnimTime()
    
    item.owner:AddAnimatingItem(item)
    
    table.insert(item.animations, newAnim)
    
    return newAnim
    
end

// wrapper class for gui items. all functions are implemented and animations are added in case
// time has a value higher than 0
class 'GUIAnimatedItem'

function GUIAnimatedItem:Initialize(owner)

    self.guiItem = GUI.CreateItem()
    self.owner = owner
    self.animations = {}
    self.scale = 1
    self.numberTextAccuracy = 1
    self.isScaling = true
    self.fontSize = 20
    self.children = {}
    
end

// removes all handles
local function Cleanup(self)

    if self.guiItem then
        GUI.DestroyItem(self.guiItem)
        self.guiItem = nil
        self.owner:RemoveItem(self)
    end
    
    for index, child in ipairs(self.children) do    
        Cleanup(child)    
    end

end

function GUIAnimatedItem:Destroy()
    Cleanup(self)
end

function GUIAnimatedItem:NotifyGUIItemDestroyed(destroyedItem)

    if self.guiItem == destroyedItem then
    
        Print("WARNING: guiItem has been destroyed and not cleaned up properly")
        self.guiItem = nil
        self.owner:RemoveItem(self)
        
    end

end

function GUIAnimatedItem:Update(deltaTime)

    PROFILE("GUIAnimatedItem:Update")
    
    local animations = self.animations
    local numAnimations = #animations
    
    if numAnimations == 0 then
        return nil, true
    end

    local remainingAnimations = { }
    local events = { }
    
    for index = 1, numAnimations do
    
        local animation = animations[index]
        animation.currentFraction = animation.modFunction(animation.startTime, animation.duration)
        
        // store the value
        gValueFunction[animation.type](self, animation)
        
        if animation.duration + animation.startTime <= GetAnimTime() then
            table.insert(events, { ItemHandle = self, Name = animation.name, Callback = animation.callBack } )
        else
            table.insert(remainingAnimations, animation)
        end
        
    end
    
    self.animations = remainingAnimations
    return events, #self.animations == 0

end

// ----------------------------------------------- animateable set functions -----------------------------------------------
function GUIAnimatedItem:SetText(textValue, time, animName, modFunction, callBack)
    ASSERT(type(textValue) == "string")
    if time == nil or (time <= 0) then  
        self.guiItem:SetText(textValue)
        return
    end
    
    GenerateAnimation(self, kAnimType.Text, time, modFunction, callBack, animName, self:GetText(), textValue)
end

function GUIAnimatedItem:SetWideText(textValue, time, animName, modFunction, callBack)
    //ASSERT(type(textValue) == "wstring")
    if time == nil or (time <= 0) then  
        self.guiItem:SetWideText(textValue)
        return
    end
    
    GenerateAnimation(self, kAnimType.WideText, time, modFunction, callBack, animName, self:GetWideText(), textValue)
end

function GUIAnimatedItem:SetNumberText(number, time, animName, modFunction, callBack)
    ASSERT(type(time) == "number")
    if time == nil or (time <= 0) then  
        self.guiItem:SetText(math.floor(number * self.numberTextAccuracy) * self.numberTextAccuracy)
        return
    end
    
    local oldValue = tonumber(self.guiItem:GetText())
    
    if oldValue == nil then   
        oldValue = 0
    end
    
    GenerateAnimation(self, kAnimType.NumberText, time, modFuncDummy, callBack, animName, oldValue, number)
end

function GUIAnimatedItem:SetColor(colorValue, time, animName, modFunction, callBack)
    ASSERT(colorValue:isa("Color"))
    if time == nil or (time <= 0) then  
        self.guiItem:SetColor(colorValue)
        return
    end
    
    GenerateAnimation(self, kAnimType.Color, time, modFunction, callBack, animName, self.guiItem:GetColor(), colorValue)
end

function GUIAnimatedItem:SetRotation(rotationVector, time, animName, modFunction, callBack)
    // TODO
    self.guiItem:SetRotation(rotationVector)
end

function GUIAnimatedItem:SetRotationOffset(offset)
    self.guiItem:SetRotationOffset(offset)
end

function GUIAnimatedItem:SetSize(sizeVector, time, animName, modFunction, callBack)

    assert(sizeVector:isa("Vector"))
    
    sizeVector = sizeVector * ConditionalValue(self.isScaling, self.scale, 1)
    
    local currentSize = self.guiItem:GetSize()
    if currentSize == sizeVector then
        return
    end
    
    if time == nil or time <= 0 then
    
        if sizeVector.x < 1 and sizeVector.x > -1 then
            sizeVector.x = 1
        end
        
        if sizeVector.y < 1 and sizeVector.y > -1 then
            sizeVector.y = 1
        end
        
        self.guiItem:SetSize(sizeVector)
        return
        
    end
    
    GenerateAnimation(self, kAnimType.Size, time, modFunction, callBack, animName, currentSize, sizeVector)
    
end

function GUIAnimatedItem:SetScale(scaleVector, time, animName, modFunction, callBack)

    assert(scaleVector:isa("Vector"))
    
    local currentScale = self.guiItem:GetScale()
    if currentScale == scaleVector then
        return
    end
    
    if time == nil or time <= 0 then
    
        self.guiItem:SetScale(scaleVector)
        return
        
    end
    
    GenerateAnimation(self, kAnimType.Scale, time, modFunction, callBack, animName, currentScale, scaleVector)
    
end

function GUIAnimatedItem:SetPosition(positionValue, time, animName, modFunction, callBack, startPosition)

    assert(positionValue:isa("Vector"))
    
    local currentPos = self:GetPosition()
    if currentPos == positionValue then
        return
    end
    
    positionValue = positionValue * ConditionalValue(self.isScaling, self.scale, 1)
    
    if time == nil or time <= 0 then
    
        self.guiItem:SetPosition(positionValue)
        return
        
    end
    
    if startPosition == nil then
        startPosition = self.guiItem:GetPosition()
    end
    
    GenerateAnimation(self, kAnimType.Position, time, modFunction, callBack, animName, self.guiItem:GetPosition(), positionValue)
    
end

function GUIAnimatedItem:SetTexturePixelCoordinates(x1, y1, x2, y2, time, animName, modFunction, callBack)
    ASSERT(type(x1) == "number" and type(y1) == "number" and type(x2) == "number" and type(y2) == "number")
    if time == nil or (time <= 0) then  
        self.guiItem:SetTexturePixelCoordinates(x1, y1, x2, y2)
        self.guiItem.texPixCoords = { x1, y1, x2, y2 }
        return
    end
    
    // in case we forgot to initialize TexturePixelCoordinates we use default values
    local currentTexPixCoords = {0, 0, 0, 0}
    if self.guiItem.texPixCoords ~= nil then
        currentTexPixCoords = self.guiItem.texPixCoords
    end
    
    GenerateAnimation(self, kAnimType.TexPixCoords, time, modFunction, callBack, animName, currentTexPixCoords, {x1, y1, x2, y2} )

end

function GUIAnimatedItem:SetTextureCoordinates(x1, y1, x2, y2, time, animName, modFunction, callBack)
    ASSERT(type(x1) == "number" and type(y1) == "number" and type(x2) == "number" and type(y2) == "number")
    if time == nil or (time <= 0) then  
        self.guiItem:SetTextureCoordinates(x1, y1, x2, y2)
        self.guiItem.texCoords = { x1, y1, x2, y2 }
        return
    end

    // in case we forgot to initialize TextureCoordinates we use default values
    local currentTexCoords = {0, 0, 0, 0}
    if self.guiItem.texCoords ~= nil then
        currentTexCoords = self.guiItem.texCoords
    end
    
    GenerateAnimation(self, kAnimType.TexCoords, time, modFunction, callBack, animName, currentTexCoords, {x1, y1, x2, y2} )

end

function GUIAnimatedItem:SetFontSize(fontSize, time, animName, modFunction, callBack)
    ASSERT(type(fontSize) == "number")

    fontSize = fontSize * ConditionalValue(self.isScaling, self.scale, 1)

    if time == nil or (time <= 0) then  
        self.guiItem:SetFontSize(fontSize)
        self.fontSize = fontSize
        return
    end
    
    local currentFontSize = 0
    
    if self.fontSize then
        currentFontSize = self.fontSize
    end
    
    GenerateAnimation(self, kAnimType.FontSize, time, modFunction, callBack, animName, currentFontSize, fontSize)
end

function GUIAnimatedItem:FadeOut(time, animName, modFunction, callBack)
    ASSERT(type(time) == "number")
    
    local currentAlpha = self.guiItem:GetColor().a

    GenerateAnimation(self, kAnimType.Fade, time, modFunction, callBack, animName, currentAlpha, 0.0)
end

function GUIAnimatedItem:FadeIn(time, animName, modFunction, callBack)
    ASSERT(type(time) == "number")
    
    local currentAlpha = self.guiItem:GetColor().a

    GenerateAnimation(self, kAnimType.Fade, time, modFunction, callBack, animName, currentAlpha, 1.0)
end

function GUIAnimatedItem:SetTextureAnimation(frameCount, time, animName, modFunction, callBack)
    ASSERT(type(frameCount) == "number" and type(time) == "number")
    
    GenerateAnimation(self, kAnimType.TextureAnimation, time, modFunction, callBack, animName, 0, frameCount )
end

function GUIAnimatedItem:GetIsVisible()
    return self.guiItem:GetIsVisible()
end

// modFunction will be ignored, we add an anonymous function that does nothing
function GUIAnimatedItem:Pause(time, animName, modFunction, callBack)
    ASSERT(type(time) == "number")

    local modFuncDummy = function(s, d) return 0.0 end
    
    GenerateAnimation(self, kAnimType.Pause, time, modFuncDummy, callBack, animName, 0.0, 1.0)
end

// ----------------------------------------------- not animateable -----------------------------------------------^

/**
 * This scale will affect the GUIItem uniformly in both the X and Y axis.
 */
function GUIAnimatedItem:SetUniformScale(scale)

    assert(type(scale) == "number")
    
    local prevPos = self:GetPosition()
    local prevSize = self:GetSize()
    local fontSize = self:GetFontSize()
    
    self.scale = scale
    
    self:SetPosition(prevPos)
    self:SetSize(prevSize)
    self:SetFontSize(fontSize)
    
end

function GUIAnimatedItem:SetShader(name)
    self.guiItem:SetShader(name)
end

function GUIAnimatedItem:SetAdditionalTexture(setName, setTexture)
    self.guiItem:SetAdditionalTexture(setName, setTexture)
end

function GUIAnimatedItem:SetFloatParameter(setName, setParam)
    self.guiItem:SetFloatParameter(setName, setParam)
end

function GUIAnimatedItem:SetParentRenders(renders)
    self.guiItem:SetParentRenders(renders)
end

function GUIAnimatedItem:SetInheritsParentAlpha(inheritsAlpha)
    self.guiItem:SetInheritsParentAlpha(inheritsAlpha)
end

function GUIAnimatedItem:SetNumberTextAccuracy(accuracy)
    if accuracy ~= 0 then
        self.numberTextAccuracy = accuracy
    else
        Print("called GUIAniamtedItem:SetNumberTextAccuracy(%s)", tostring(accuracy))
    end
end

function GUIAnimatedItem:SetStencilFunc(stencilFunc)
    self.guiItem:SetStencilFunc(stencilFunc)
end

function GUIAnimatedItem:SetIsStencil(isStencil)
    self.guiItem:SetIsStencil(isStencil)
end

function GUIAnimatedItem:SetInheritsParentStencilSettings(setInherits)
    self.guiItem:SetInheritsParentStencilSettings(setInherits)
end

function GUIAnimatedItem:SetClearsStencilBuffer(clearStencil)
    self.guiItem:SetClearsStencilBuffer(clearStencil)
end

function GUIAnimatedItem:SetIsVisible(visState)
    self.guiItem:SetIsVisible(visState)
end

function GUIAnimatedItem:SetTexture(texture)
    self.guiItem:SetTexture(texture)
end

function GUIAnimatedItem:AddChild(item)

    if item:isa("GUIItem") then
        self.guiItem:AddChild(item)
    else
        self.guiItem:AddChild(item.guiItem)
        table.insertunique(self.children, item)
    end
    
end

function GUIAnimatedItem:AddAsChildTo(item)
    item:AddChild(self.guiItem)
end

function GUIAnimatedItem:SetAnchor(horizontalAlignment, verticalAlignment)
    self.guiItem:SetAnchor(horizontalAlignment, verticalAlignment)
end

function GUIAnimatedItem:SetLayer(hudLayerId)
    self.guiItem:SetLayer(hudLayerId)
end

function GUIAnimatedItem:SetFontIsBold(isBold)
    self.guiItem:SetFontIsBold(isBold)
end

function GUIAnimatedItem:SetTextAlignmentX(alignment)
    self.guiItem:SetTextAlignmentX(alignment)
end

function GUIAnimatedItem:SetTextAlignmentY(alignment)
    self.guiItem:SetTextAlignmentY(alignment)
end

function GUIAnimatedItem:SetFontName(fontName)
    self.guiItem:SetFontName(fontName)
end

function GUIAnimatedItem:SetBlendTechnique(blendTechnique)
    self.guiItem:SetBlendTechnique(blendTechnique)
end

function GUIAnimatedItem:SetTextClipped(setTextClipped, setWidth, setHeight)
    self.guiItem:SetTextClipped(setTextClipped, setWidth, setHeight)
end

function GUIAnimatedItem:SetIsScaling(isScaling)

    local fullSize = self:GetSize()
    local fullPos = self:GetPosition()
    local fullFontSize = self:GetFontSize()
    
    self.isScaling = isScaling
    
    self:SetSize(fullSize)
    self:SetPosition(fullPos)
    self:SetFontSize(fullFontSize)
    
end

/**
 * Wipes all animations without considering callBacks / event.
 */
function GUIAnimatedItem:DestroyAnimations()
    self.animations = { }
end

// destroy the first found animation with the passed name
function GUIAnimatedItem:DestroyAnimation(animationName)

    local foundIndex = 0
    local success = false
    
    for index, animation in ipairs(self.animations) do
    
        if animation.name == animationName then
        
            foundIndex = index
            success = true
            break
            
        end
        
    end
    
    if foundIndex ~= 0 then
        table.remove(self.animations, foundIndex)
    end
    
    return success
    
end

// puts all animations to their final state without considering callBacks / event
function GUIAnimatedItem:EndAnimations()

    for index, animation in ipairs(self.animations) do
    
        animation.currentFraction = 1.0
        gValueFunction[animation.type](self, animation)
        
    end
    
    self.animations = { }
    
end

// puts all animations to their initial state without considering callBacks / event
function GUIAnimatedItem:ResetAnimations()

    for index, animation in ipairs(self.animations) do
    
        animation.currentFraction = 0.0
        gValueFunction[animation.type](self, animation)
        
    end
    
    self.animations = { }
    
end

// ----------------------------------------------- get functions -----------------------------------------------
function GUIAnimatedItem:GetText()
    return self.guiItem:GetText()
end

function GUIAnimatedItem:GetWideText()
    return self.guiItem:GetWideText()
end

function GUIAnimatedItem:GetIsScaling()
    return self.isScaling
end

function GUIAnimatedItem:GetTextWidth(text)
    if self.isScaling then
        return self.guiItem:GetTextWidth(text) / self.scale
    end
    return self.guiItem:GetTextWidth(text)
end

function GUIAnimatedItem:GetTextHeight(text)
    if self.isScaling then
        return self.guiItem:GetTextHeight(text) / self.scale
    end
    return self.guiItem:GetTextHeight(text)
end

function GUIAnimatedItem:GetSize()
    if self.isScaling then
        return self.guiItem:GetSize() / self.scale
    end
    return self.guiItem:GetSize() 
end

function GUIAnimatedItem:GetColor()
    return self.guiItem:GetColor()
end

function GUIAnimatedItem:GetPosition()

    if self.isScaling then
        return self.guiItem:GetPosition() / self.scale
    end
    return self.guiItem:GetPosition()
    
end

function GUIAnimatedItem:GetScreenPosition(x, y)
    return self.guiItem:GetScreenPosition(x, y)
end

function GUIAnimatedItem:GetFontSize()
    if self.isScaling then
        return self.fontSize / self.scale
    end
    return self.fontSize
end

function GUIAnimatedItem:GetTexturePixelCoordinates()
    return self.guiItem.texPixCoords[1], self.guiItem.texPixCoords[2], self.guiItem.texPixCoords[3], self.guiItem.texPixCoords[4]
end

function GUIAnimatedItem:GetTextureCoordinates()
    return self.guiItem:GetTextureCoordinates()
end

function GUIAnimatedItem:GetIsAnimating()
    return table.count(self.animations) > 0
end

function GUIAnimatedItem:GetInheritsParentAlpha()
    return self.guiItem:GetInheritsParentAlpha()
end

function GUIAnimatedItem:GetHasAnimation(animationName)

    for index, animation in ipairs(self.animations) do
    
        if animation.name == animationName then
        
            return true
            
        end
        
    end
    
    return false
    
end
