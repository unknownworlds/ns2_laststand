// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\HUD\Marine\GUINotificationItem.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Notifications triggered by the commander. Shows structures/medpacks/ammopacks etc. being dropped.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

class 'GUINotificationItem'

GUINotificationItem.kNotificationIconsTexture = "ui/buildmenu.dds"
GUINotificationItem.kAlienNotificationIconsTexture = "ui/buildmenu.dds"

GUINotificationItem.kMarineNotificationTexture = PrecacheAsset("ui/marine_HUD_notification.dds")
GUINotificationItem.kAlienNotificationTexture = PrecacheAsset("ui/alien_HUD_notification.dds")

GUINotificationItem.kNotificationBorderCoords = { 0, 2, 263, 50 }
GUINotificationItem.kNotificationBgCoords = { 0, 50, 263, 98 }

GUINotificationItem.kNotificationYMargin = 5

GUINotificationItem.kNotificationScale = 1.2

GUINotificationItem.kIconSize = Vector(40, 40, 0)
GUINotificationItem.kIconAlpha = 0.5

GUINotificationItem.kNotificationSize = Vector( GUINotificationItem.kNotificationBorderCoords[3] - GUINotificationItem.kNotificationBorderCoords[1], 32, 0 )
GUINotificationItem.kNotificationStackOffset = Vector( -10, -2, 0) * GUINotificationItem.kNotificationScale

GUINotificationItem.kNotificationFontSize = 20 * GUINotificationItem.kNotificationScale

GUINotificationItem.kFontName = "fonts/AgencyFB_small.fnt"

// utility functions:
function CreateNotificationItem(scriptHandle, locationName, techId, scale, parent, useMarineStyle)

    local notification = GUINotificationItem()
    notification.scale = scale
    notification.parent = parent
    notification.script = scriptHandle
    notification.locationName = ConditionalValue(locationName ~= nil, locationName, "")
    notification.techId = techId
    notification.useMarineStyle = useMarineStyle
    notification:Initialize()
    
    return notification

end

function DestroyItem(script, item)
    item:Destroy()
end

// pass a GUIItem as parent
function GUINotificationItem:Initialize()

    self:ResetLifeTime()
    self.position = 0
    self.numChildren = 0

    self.background = self.script:CreateAnimatedGraphicItem()
    self.background:SetUniformScale(self.scale)
    self.background:SetSize(GUINotificationItem.kNotificationSize)    
    local texture = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineNotificationTexture, GUINotificationItem.kAlienNotificationTexture)
    self.background:SetTexture(texture)    
    self.background:SetTexturePixelCoordinates(unpack(GUINotificationItem.kNotificationBgCoords))
    self.background:SetColor(Color(1, 1, 1, GUINotificationItem.kIconAlpha))
    self.background:SetIsVisible(false)
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    
    self.background:Pause(0.2, nil, AnimateLinear, 
        function (script, item)
        
            item:SetIsVisible(true)
        
        end
    )
    
    if self.parent then
        self.background:AddAsChildTo(self.parent)
    end
    
    self.border = self.script:CreateAnimatedGraphicItem()
    self.border:SetUniformScale(self.scale)
    self.border:SetSize(GUINotificationItem.kNotificationSize)    
    texture = ConditionalValue(self.useMarineStyle, GUINotificationItem.kMarineNotificationTexture, GUINotificationItem.kAlienNotificationTexture)
    self.border:SetTexture(texture)    
    self.border:SetTexturePixelCoordinates(unpack(GUINotificationItem.kNotificationBorderCoords))
    self.border:AddAsChildTo(self.background)
    
    self.icon = self.script:CreateAnimatedGraphicItem()
    self.icon:SetUniformScale(self.scale)
    self.icon:SetSize(GUINotificationItem.kIconSize)
    self.icon:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.icon:SetPosition( Vector(40, -(GUINotificationItem.kIconSize.y/2), 0) )
    texture = ConditionalValue(self.useMarineStyle, GUINotificationItem.kNotificationIconsTexture, GUINotificationItem.kAlienNotificationIconsTexture)
    self.icon:SetTexture(texture)
    self.icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(self.techId, self.useMarineStyle)))
    self.icon:AddAsChildTo(self.background)
    
    self.locationText = self.script:CreateAnimatedTextItem()
    self.locationText:SetUniformScale(self.scale)
    self.locationText:SetText(string.upper(self.locationName))
    self.locationText:SetFontName(GUINotificationItem.kFontName)
    self.locationText:SetScale(GetScaledVector())
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Center)
    self.locationText:SetPosition( Vector(GUINotificationItem.kIconSize.x + 16, 0, 0) )
    self.locationText:SetFontSize(GUINotificationItem.kNotificationFontSize)
    self.locationText:AddAsChildTo(self.icon)
    
    self.children = {}
    self.destroyTime = 0

end

function GUINotificationItem:Destroy()

    if self.border then
        self.border:Destroy()
        self.border = nil
    end
    
    if self.icon then
        self.icon:Destroy()
        self.icon = nil
    end
    
    if self.locationText then
        self.locationText:Destroy()
        self.locationText = nil
    end
    
    for index, child in ipairs(self.children) do
        child:Destroy()
    end

    if self.background then
        self.background:Destroy()
        self.background = nil
    end

end

function GUINotificationItem:GetCreationTime()
    return self.creationTime
end

function GUINotificationItem:ResetLifeTime()
    self.creationTime = Client.GetTime()
end

function GUINotificationItem:ShiftDown()

    self.position = self.position + 1
    self.background:DestroyAnimation("SHIFT_DOWN")
    self.background:SetPosition( Vector(0, GUINotificationItem.kNotificationSize.y + GUINotificationItem.kNotificationYMargin, 0) * self.position, 0.5, "SHIFT_DOWN", AnimateSin)

end

function GUINotificationItem:MatchesTo(locationName, techId)
    return techId == self.techId and locationName == self.locationName
end

function GUINotificationItem:SetLayer(layer)

    if self.background then
        self.background:SetLayer(layer)
    end
    
    if self.border then
        self.border:SetLayer(layer)
    end
    
    if self.locationText then
        self.locationText:SetLayer(layer)
    end
        
    if self.icon then
        self.icon:SetLayer(layer)
    end

end

// will trigger fade out on itself and all children and destroy all GUIItems
function GUINotificationItem:FadeIn(animDuration)

    if self.border then
        self.border:SetColor(Color(1,1,1,0))
        self.border:FadeIn(animDuration, nil, AnimateLinear)
    end    
    
    if self.icon then
        self.icon:SetColor(Color(1,1,1,0))
        self.icon:FadeIn(animDuration, nil, AnimateLinear)
    end   
    
    if self.locationText then
        local color = Color(ConditionalValue(self.useMarineStyle, kMarineFontColor, kAlienFontColor))
        color.a = 0
        self.locationText:SetColor(color)
        self.locationText:FadeIn(animDuration, nil, AnimateLinear)
    end   
    
    if self.background then
        self.background:SetColor(Color(1,1,1,0))
        self.background:FadeIn(animDuration, nil, AnimateLinear)
    end
    
    for index, child in ipairs(self.children) do
        child:FadeIn(animDuration)
    end

end

// will trigger fade out on itself and all children and destroy all GUIItems
function GUINotificationItem:FadeOut(animDuration)

    if self.destroyTime ~= 0 then
        return
    end

    if self.border then
        self.border:FadeOut(animDuration, nil, AnimateLinear)
    end    
    
    if self.icon then
        self.icon:FadeOut(animDuration, nil, AnimateLinear)
    end   
    
    if self.locationText then
        self.locationText:FadeOut(animDuration, nil, AnimateLinear)
    end   
    
    if self.background then
        self.background:FadeOut(animDuration, nil, AnimateLinear)
    end
    
    for index, child in ipairs(self.children) do
        child:FadeOut(animDuration)
    end

    self.destroyTime = Client.GetTime() + animDuration

end

function GUINotificationItem:GetIsReadyToBeDestroyed()
    return self.destroyTime ~= 0 and self.destroyTime < Client.GetTime()
end

// removed text and icon and sets border and background transparent
function GUINotificationItem:SetTransparent()

        if self.background then
            self.background:SetColor(Color(1, 1, 1, GUINotificationItem.kIconAlpha * 0.5))
        end
        
        if self.border then
            self.border:SetColor(Color(1,1,1,0.5))
        end
    
        if self.locationText then
            self.locationText:Destroy()
            self.locationText = nil
        end

        if self.icon then
            self.icon:Destroy()
            self.icon = nil
        end

end

// set all notifications transparent and add the last on top of the stack
function GUINotificationItem:AddNotification(notificationItem)

    /*
    self:SetTransparent()

    for index, child in ipairs(self.children) do
        child:SetTransparent()
    end
    
    local numChildren = table.count(self.children)
    
    local lastItem = self
    
    if numChildren > 0 then
        lastItem = self.children[numChildren]
    end
    
    notificationItem.background:AddAsChildTo(lastItem.background)
    notificationItem.background:SetPosition(GUINotificationItem.kNotificationStackOffset)
    notificationItem:SetLayer(numChildren + 1)
    
    table.insert(self.children, notificationItem)
    */
    
    local stackText = ""
    
    self.numChildren = self.numChildren + 1
    
    if self.numChildren > 0 then
        stackText = "  (" .. tostring(self.numChildren + 1) .. ")"
    end
    
    self.locationText:SetText(string.upper(self.locationName) .. stackText)
    
    self:ResetLifeTime()

end

function GUINotificationItem:GetNumChildren()
    return table.count(self.children)
end