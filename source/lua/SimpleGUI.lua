Script.Load('lua/easing.lua')

// Constants

local kSGRegionX = 1
local kSGRegionY = 2
local kSGRegionWidth = 3
local kSGRegionHeight = 4
local kSGRegionTexture = 5

local kSGGet = 1
local kSGSet = 2
local kSGLerp = 3


// Properties
local function _Lerp(from, to, t)
    return from + (to - from) * t
end

local function _LerpColor(from, to, t)
    return ColorLerp(from, to, t)
end

local function _SetItemSize(item, value)
    item:SetSize(value)
end

kSGColor = { GUIItem.GetColor, GUIItem.SetColor, _LerpColor }
kSGPosition = { GUIItem.GetPosition, GUIItem.SetPosition, _Lerp }
kSGSize = { GUIItem.GetSize, GUIItem.SetSize, _Lerp }
kSGScale = { GUIItem.GetScale, GUIItem.SetScale, _Lerp }

// Texture atlas
function SGMakeAtlas(name, regions)
    local texture = PrecacheAsset(name)
    // Append the texture to each region
    for name, region in pairs(regions) do
        table.insert(region, texture)
    end
    return regions
end

function SGMakeRegion(name, width, height)
    return {0, 0, width, height, PrecacheAsset(name)}
end

function SGGetRegionSize(region)
    return region[kSGRegionWidth], region[kSGRegionHeight]
end

// Misc helpers
function SGSetSizeAndCenter(item, width, height)
    item:SetSize(Vector(width, height, 0))
    item:SetAnchor(GUIItem.Middle, GUIItem.Center)    
    item:SetPosition(Vector(-width/2, -height/2, 0))
end

function SGSetTexture(item, region)
    local x, y = region[kSGRegionX], region[kSGRegionY] 
    local width, height = region[kSGRegionWidth], region[kSGRegionHeight] 
    item:SetSize(Vector(width, height, 0))
    item:SetTexture(region[kSGRegionTexture])
    item:SetTexturePixelCoordinates(x, y, x + width - 1, y + height - 1)
end

function SGDelay(curve, waitTime, totalTime)
    return function(t)
        local realTime = t * totalTime
        if realTime < waitTime then
            return 0
        else
            return curve((realTime - waitTime) / (totalTime - waitTime))
        end    
    end
end

// Menu
function SGCreateMenu()
    return {
        items={},
        anims={},
    }
end

function SGDestroyMenu(menu)
    if menu ~= nil then
        for i = 1, #menu.items do
            GUI.DestroyItem(menu.items[i])
        end
    end
end

function SGUpdateMenu(menu, deltaTime)
    
    local x, y = Client.GetCursorPosScreen()
    for i = 1, #menu.items do    
        local item = menu.items[i]
        local newIsMouseOver = GUIItemContainsPoint(item, x, y)
        if newIsMouseOver ~= item.isMouseOver then
            if newIsMouseOver and item.OnMouseEnter then
                item:OnMouseEnter()
            end
            if not newIsMouseOver and item.OnMouseExit then
                item:OnMouseExit()
            end
            item.isMouseOver = newIsMouseOver
        end        
    end
    
    local newAnims = {}
    local callbacks = {}
    for i = 1, #menu.anims do
        local anim = menu.anims[i]
        anim.time = math.min(anim.time + deltaTime, anim.duration)
        anim.func(anim.time / anim.duration)
        if anim.time < anim.duration then
            table.insert(newAnims, anim)
        else
            if anim.callback then
                table.insert(callbacks, anim.callback)
            end    
        end
    end
    menu.anims = newAnims
    
    for i = 1, #callbacks do
        callbacks[i]()
    end
        
end

function SGSendKeyEvent(menu, key, down)

    for i = 1, #menu.items do    
        local item = menu.items[i]        
        if item.isMouseOver and item.OnSendKeyEvent then
            item:OnSendKeyEvent(key, down)
        end        
    end
    
end

function SGAddGraphic(menu, parent, region)
    local graphicItem = GUIManager:CreateGraphicItem()
    graphicItem.isMouseOver = false
    
    table.insert(menu.items, graphicItem)
    
    if parent ~= nil then
        parent:AddChild(graphicItem)
    end
    
    if region ~= nil then
        SGSetTexture(graphicItem, region)
    end
    
    return graphicItem
end

function SGAddText(menu, parent, text, fontName, color)

    local textItem = GUIManager:CreateTextItem()
    textItem.isMouseOver = false
    
    table.insert(menu.items, textItem)
    
    if parent ~= nil then
        parent:AddChild(textItem)
    end
    
    if text ~= nil then
        textItem:SetText(text)
    end
    
    if fontName ~= nil then
        textItem:SetFontName(fontName)
    end
    
    if color ~= nil then
        textItem:SetColor(color)
    end
    
    return textItem

end

function SGAddAnim(menu, duration, func, callbackFunc)
    anim = {duration=duration, time=0, func=func, callback=callbackFunc}
    table.insert(menu.anims, anim)
    return anim
end

function SGAddPropertyAnim(menu, item, property, newValue, duration, curveFunc, callbackFunc)   
    
    // Remove previous animation of this property
    for i = 1, #menu.anims do
        local anim = menu.anims[i]
        if anim.item == item and anim.property == property then
            table.remove(menu.anims, i)
            break
        end
    end
        
    if duration == nil then
        duration = 0.2
    end

    local oldValue = property[kSGGet](item)
    
    local function func(t)
        if curveFunc then
            t = curveFunc(t)
        end
        local lerped = property[kSGLerp](oldValue, newValue, t)
        property[kSGSet](item, lerped)
    end
    
    local anim = SGAddAnim(menu, duration, func, callbackFunc)
    anim.item = item
    anim.property = property
    return anim
    
end
