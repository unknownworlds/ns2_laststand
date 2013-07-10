
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUINotifications.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the displaying any text notifications on the screen.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUINotifications' (GUIAnimatedScript)

// Tooltip constants.
GUINotifications.kTooltipXOffset = 50
GUINotifications.kTooltipYOffset = -300
GUINotifications.kTooltipBackgroundHeight = 28
// The number of pixels that buffer the text on the left and right.
GUINotifications.kTooltipBackgroundWidthBuffer = 5
GUINotifications.kTooltipBackgroundColor = Color(0.4, 0.4, 0.4, 0.5)
GUINotifications.kTooltipBackgroundVisibleTimer = 5
// Defines at which point in the kTooltipBackgroundVisibleTimer does it start to fade out.
GUINotifications.kTooltipBackgroundFadeoutTimer = 0.5
GUINotifications.kTooltipFontSize = 20
GUINotifications.kTooltipTextColor = Color(1, 1, 1, 1)

// Score popup constants.
GUINotifications.kScoreDisplayFontName = "fonts/AgencyFB_medium.fnt"
GUINotifications.kScoreDisplayTextColor = Color(0.75, 0.75, 0.1, 1)
GUINotifications.kScoreDisplayFontHeight = 80
GUINotifications.kScoreDisplayMinFontHeight = 50
GUINotifications.kScoreDisplayYOffset = -96
GUINotifications.kScoreDisplayPopTimer = 0.15
GUINotifications.kScoreDisplayFadeoutTimer = 2

GUINotifications.kMarineColor = Color(205/255, 245/255, 1, 1)
GUINotifications.kTooltipMarineYOffset = -60

GUINotifications.kIconSize = Vector(64, 80, 0)
GUINotifications.kIconBigSize = Vector(96, 120, 0)

GUINotifications.kMarineTexture = PrecacheAsset("ui/marine_tooltips.dds")
GUINotifications.kMarineIconPixelCoords = { 0, 0, 64, 80 }

GUINotifications.kGeneralFont = "fonts/Arial_15.fnt"
GUINotifications.kMarineFont = "fonts/AgencyFB_small.fnt"

local kAlienFont = "fonts/AgencyFB_small.fnt"

function GUINotifications:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.lastTooltipText = ""
    
    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetPosition(Vector(20, 20, 0))
    self.locationText:SetColor(Color(1, 1, 1, 1))
    self.locationText:SetText(PlayerUI_GetLocationName())
    self.locationText:SetLayer(kGUILayerLocationText)
    
    self:InitializeTooltip()
    
    self:InitializeScoreDisplay()

end

function GUINotifications:EnableMarineStyle()

    PROFILE("GUINotifications:EnableMarineStyle")

    self.locationText:SetColor(GUINotifications.kMarineColor)
    self.locationText:SetFontName(GUINotifications.kMarineFont)
    self.tooltipBackground:SetColor(Color(1,1,1,0))
    self.tooltipText:SetColor(GUINotifications.kMarineColor)
    self.scoreDisplay:SetColor(GUINotifications.kMarineColor)
    self.tooltipBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local currentWidth = self.tooltipBackground:GetSize().x
    self.tooltipBackground:SetPosition(Vector(-currentWidth / 2, GUINotifications.kTooltipMarineYOffset, 0))
    
    self.toolTipIcon:SetTexture(GUINotifications.kMarineTexture)
    self.toolTipIcon:SetTexturePixelCoordinates(unpack(GUINotifications.kMarineIconPixelCoords))
    
    self.toolTipIcon:SetIsVisible(true)
    
end

function GUINotifications:EnableAlienStyle()

    PROFILE("GUINotifications:EnableAlienStyle")

    self.locationText:SetColor(kAlienTeamColorFloat)
    self.locationText:SetFontName(kAlienFont)
    self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
    self.tooltipText:SetColor(kAlienTeamColorFloat)
    self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
    self.tooltipBackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.toolTipIcon:SetIsVisible(false)
    
end

function GUINotifications:EnableGeneralStyle()

    PROFILE("GUINotifications:EnableGeneralStyle")

    self.locationText:SetColor(GUINotifications.kTooltipTextColor)
    self.locationText:SetFontName(GUINotifications.kGeneralFont)
    self.tooltipBackground:SetPosition(Vector(GUINotifications.kTooltipXOffset, GUINotifications.kTooltipYOffset, 0))
    self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
    self.tooltipText:SetColor(GUINotifications.kTooltipTextColor)
    self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
    self.tooltipBackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.toolTipIcon:SetIsVisible(false)
    
end

function GUINotifications:Uninitialize()

    GUI.DestroyItem(self.locationText)
    self.locationText = nil
    
    self:UninitializeTooltip()
    
    self:UninitializeScoreDisplay()
    
    GUIAnimatedScript.Uninitialize(self)
    
end

function GUINotifications:InitializeTooltip()

    self.tooltipBackground = GUIManager:CreateGraphicItem()
    self.tooltipBackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.tooltipBackground:SetSize(Vector(0, GUINotifications.kTooltipBackgroundHeight, 0))
    self.tooltipBackground:SetPosition(Vector(GUINotifications.kTooltipXOffset, GUINotifications.kTooltipYOffset, 0))
    self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
    self.tooltipBackground:SetIsVisible(false)
    
    self.tooltipText = self:CreateAnimatedTextItem()
    self.tooltipText:SetIsScaling(false)
    self.tooltipText:SetFontSize(GUINotifications.kTooltipFontSize)
    self.tooltipText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.tooltipText:SetPosition(Vector(GUINotifications.kTooltipBackgroundWidthBuffer, 0, 0))
    self.tooltipText:SetTextAlignmentX(GUIItem.Align_Min)
    self.tooltipText:SetTextAlignmentY(GUIItem.Align_Center)
    self.tooltipText:SetColor(GUINotifications.kTooltipTextColor)
    self.tooltipText:SetText(PlayerUI_GetLocationName())
    
    self.toolTipIcon = self:CreateAnimatedGraphicItem()
    self.toolTipIcon:SetSize(GUINotifications.kIconSize)
    self.toolTipIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.toolTipIcon:SetPosition(Vector(-GUINotifications.kIconSize.x, -GUINotifications.kIconSize.y / 2, 0))
    
    self.tooltipText:AddAsChildTo(self.tooltipBackground)
    self.toolTipIcon:AddAsChildTo(self.tooltipBackground)
    
    self.tooltipBackgroundVisibleTime = 0
    
end

function GUINotifications:UninitializeTooltip()

    GUI.DestroyItem(self.tooltipBackground)
    self.tooltipBackground = nil
    self.tooltipText = nil
    
end

function GUINotifications:InitializeScoreDisplay()

    self.scoreDisplay = GUIManager:CreateTextItem()
    self.scoreDisplay:SetFontName(GUINotifications.kScoreDisplayFontName)
    self.scoreDisplay:SetScale(Vector(1, 1, 1))
    self.scoreDisplay:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.scoreDisplay:SetPosition(Vector(0, GUINotifications.kScoreDisplayYOffset, 0))
    self.scoreDisplay:SetTextAlignmentX(GUIItem.Align_Center)
    self.scoreDisplay:SetTextAlignmentY(GUIItem.Align_Center)
    self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
    self.scoreDisplay:SetIsVisible(false)
    
    self.scoreDisplayPopupTime = 0
    self.scoreDisplayPopdownTime = 0
    self.scoreDisplayFadeoutTime = 0

end

function GUINotifications:UninitializeScoreDisplay()

    GUI.DestroyItem(self.scoreDisplay)
    self.scoreDisplay = nil
    
end

local function UpdateScoreDisplay(self, deltaTime)

    PROFILE("GUINotifications:UpdateScoreDisplay")
    
    if self.scoreDisplayFadeoutTime > 0 then
    
        self.scoreDisplayFadeoutTime = math.max(0, self.scoreDisplayFadeoutTime - deltaTime)
        local fadeRate = 1 - (self.scoreDisplayFadeoutTime / GUINotifications.kScoreDisplayFadeoutTimer)
        local fadeColor = self.scoreDisplay:GetColor()
        fadeColor.a = 1
        fadeColor.a = fadeColor.a - (fadeColor.a * fadeRate)
        self.scoreDisplay:SetColor(fadeColor)
        if self.scoreDisplayFadeoutTime == 0 then
            self.scoreDisplay:SetIsVisible(false)
        end
        
    end
    
    if self.scoreDisplayPopdownTime > 0 then
    
        self.scoreDisplayPopdownTime = math.max(0, self.scoreDisplayPopdownTime - deltaTime)
        local popRate = self.scoreDisplayPopdownTime / GUINotifications.kScoreDisplayPopTimer
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        local scale = fontSize / GUINotifications.kScoreDisplayFontHeight
        self.scoreDisplay:SetScale(Vector(scale, scale, scale))
        if self.scoreDisplayPopdownTime == 0 then
            self.scoreDisplayFadeoutTime = GUINotifications.kScoreDisplayFadeoutTimer
        end
        
    end
    
    if self.scoreDisplayPopupTime > 0 then
    
        self.scoreDisplayPopupTime = math.max(0, self.scoreDisplayPopupTime - deltaTime)
        local popRate = 1 - (self.scoreDisplayPopupTime / GUINotifications.kScoreDisplayPopTimer)
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        local scale = fontSize / GUINotifications.kScoreDisplayFontHeight
        self.scoreDisplay:SetScale(Vector(scale, scale, scale))
        if self.scoreDisplayPopupTime == 0 then
            self.scoreDisplayPopdownTime = GUINotifications.kScoreDisplayPopTimer
        end
        
    end
    
    local newScore, resAwarded = ScoreDisplayUI_GetNewScore()
    if newScore > 0 then
    
        // Restart the animation sequence.
        self.scoreDisplayPopupTime = GUINotifications.kScoreDisplayPopTimer
        self.scoreDisplayPopdownTime = 0
        self.scoreDisplayFadeoutTime = 0
        
        local resAwardedString = ""
        if resAwarded > 0 then
            resAwardedString = string.format(" (+%d res)", resAwarded)
        end
        
        self.scoreDisplay:SetText(string.format("+%s%s", tostring(newScore), resAwardedString))
        self.scoreDisplay:SetScale(Vector(0.5, 0.5, 0.5))
        self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
        self.scoreDisplay:SetIsVisible(true)
        
    end
    
end

function GUINotifications:Update(deltaTime)

    PROFILE("GUINotifications:Update")
    
    GUIAnimatedScript.Update(self, deltaTime)
    
    // The commander has their own location text.
    if PlayerUI_IsACommander() or PlayerUI_IsOnMarineTeam() then
        self.locationText:SetIsVisible(false)
    else
    
        self.locationText:SetIsVisible(true)
        self.locationText:SetText(PlayerUI_GetLocationName())
        
    end
    
    if PlayerUI_IsOnMarineTeam() then
        self:EnableMarineStyle()
    elseif PlayerUI_IsOnAlienTeam() then
        self:EnableAlienStyle()
    else
        self:EnableGeneralStyle()
    end
    
    self:UpdateTooltip(deltaTime)
    
    UpdateScoreDisplay(self, deltaTime)
    
end

local function GetBackgroundColor()

    if PlayerUI_IsOnMarineTeam() then
        return Color(1, 1, 1, 1)
    end
    
    return GUINotifications.kTooltipBackgroundColor
    
end

function GUINotifications:UpdateTooltip(deltaTime)

    PROFILE("GUINotifications:UpdateTooltip")
    
    if self.tooltipBackgroundVisibleTime > 0 then
    
        self.tooltipBackgroundVisibleTime = math.max(0, self.tooltipBackgroundVisibleTime - deltaTime)
        if self.tooltipBackgroundVisibleTime <= GUINotifications.kTooltipBackgroundFadeoutTimer then
        
            local fadeRate = 1 - (self.tooltipBackgroundVisibleTime / GUINotifications.kTooltipBackgroundFadeoutTimer)
            local fadeColor = GetBackgroundColor()
            fadeColor.a = fadeColor.a - (fadeColor.a * fadeRate)
            self.tooltipBackground:SetColor(fadeColor)
            local textFadeColor = Color(GUINotifications.kTooltipTextColor)
            textFadeColor.a = textFadeColor.a - (textFadeColor.a * fadeRate)
            self.tooltipText:SetColor(textFadeColor)
            
        end
        
        if self.tooltipBackgroundVisibleTime == 0 then
            self.tooltipBackground:SetIsVisible(false)
        end
        
    end
    
    local newMessage = HudTooltipUI_GetMessage()
    
    if self.lastTooltipText ~= newMessage and string.len(newMessage) > 0 then
    
        if PlayerUI_IsOnMarineTeam() then
        
            self.tooltipText:SetText("")
            self.tooltipText:SetText(newMessage, 1, "TOOL_TIP_TEXT_ANIM")
            
            self.toolTipIcon:SetSize(GUINotifications.kIconBigSize)
            self.toolTipIcon:SetSize(GUINotifications.kIconSize, 1, "TOOL_TIP_ICON_SIZE_ANIM")
            self.toolTipIcon:SetPosition(Vector(-GUINotifications.kIconBigSize.x, -GUINotifications.kIconBigSize.y / 2, 0))
            self.toolTipIcon:SetPosition(Vector(-GUINotifications.kIconSize.x, -GUINotifications.kIconSize.y / 2, 0), 1, "TOOL_TIP_ICON_POS_ANIM")
            
        else
            self.tooltipText:SetText(newMessage)
        end
        
        self.lastTooltipText = newMessage
        
    end
    
    if string.len(newMessage) > 0 then
    
        self.tooltipBackgroundVisibleTime = GUINotifications.kTooltipBackgroundVisibleTimer
        self.tooltipBackground:SetIsVisible(true)
        local tooltipWidth = self.tooltipText:GetTextWidth(newMessage)
        tooltipWidth = tooltipWidth + (GUINotifications.kTooltipBackgroundWidthBuffer * 2)
        self.tooltipBackground:SetSize(Vector(tooltipWidth, GUINotifications.kTooltipBackgroundHeight, 0))
        self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
        
    end
    
end