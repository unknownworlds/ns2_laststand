// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\GUIMarineTeamMessage.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

local kBackgroundTexture = PrecacheAsset("ui/objective_banner_marine.dds")
local kBackgroundSize = Vector(1024, 64, 0)
local kBackgroundPosition = Vector(-kBackgroundSize.x / 2, -300, 0)
// Color starts faded away and fades in.
local kMessageFontColor = Color(kMarineFontColor.r, kMarineFontColor.g, kMarineFontColor.b, 0)

local kDropDistance = Vector(0, 10, 0)

class 'GUIMarineTeamMessage' (GUIAnimatedScript)

function GUIMarineTeamMessage:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetPosition(kBackgroundPosition)
    self.background:SetSize(kBackgroundSize)
    self.background:SetTexture(kBackgroundTexture)
    self.background:SetBlendTechnique(GUIItem.Add)
    self.background:SetIsVisible(false)
    
    self.messageText = self:CreateAnimatedTextItem()
    self.messageText:SetFontName(kMarineFontName)
    self.messageText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.messageText:SetTextAlignmentX(GUIItem.Align_Center)
    self.messageText:SetTextAlignmentY(GUIItem.Align_Center)
    self.messageText:SetColor(kMarineFontColor)
    self.background:AddChild(self.messageText)
    
    self.messageTextScale = Vector(1, 1, 1)
    self.messageTextDir = 1
    
end

function GUIMarineTeamMessage:SetTeamMessage(message)

    self.background:DestroyAnimations()
    
    self.background:SetIsVisible(true)
    self.background:SetPosition(kBackgroundPosition)
    self.background:SetColor(Color(1, 1, 1, 0))
    self.background:SetScale(Vector(1, 1, 1))
    local fadeOutFunc = function() self.background:FadeOut(0.2, nil, AnimateLinear) end
    local pauseFunc = function() self.background:Pause(3, nil, nil, fadeOutFunc) end
    self.background:FadeIn(0.2, nil, AnimateLinear, pauseFunc)
    
    local shrinkFunc = function() self.background:SetScale(Vector(1, 0.1, 1), 0.5, "shrink", AnimateSin) end
    local dropDownFunc = function() self.background:SetPosition(kBackgroundPosition + kDropDistance, 0.3, "drop", AnimateLinear, shrinkFunc) end
    self.background:Pause(2.9, nil, nil, dropDownFunc)
    
    self.messageText:DestroyAnimations()
    
    self.messageText:SetColor(kMessageFontColor)
    local fadeOutFunc = function() self.messageText:FadeOut(0.5, nil, AnimateLinear, function() self.displayMessage = false end) end
    local pauseFunc = function() self.messageText:Pause(2.3, nil, nil, fadeOutFunc) end
    self.messageText:FadeIn(0.5, nil, AnimateLinear, pauseFunc)
    self.messageText:SetText(message)
    
    self.messageText:SetScale(Vector(2.5, 0.5, 1))
    local bounceEnd = function() self.messageText:SetScale(Vector(1, 1, 1), 0.2, "bounce_out", AnimateSin) end
    local bounceStart = function() self.messageText:SetScale(Vector(1.1, 1.1, 1), 0.2, "bounce_in", AnimateSin, bounceEnd) end
    self.messageText:SetScale(Vector(1, 1, 1), 0.25, "start", AnimateSin, bounceStart)
    
end