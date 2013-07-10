// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIMarineJetpackHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kJetpackImage = "ui/marine_jetpack.dds"
local kJetpackFrameWidth = 128
local kJetpackFrameHeight = 128

local kTimeNeededToLearnToFly = 6

local kGroundColor = Color(0.8, 0.8, 0.8, 1)
local kFlyingColor = Color(1, 1, 1, 1)

local kKeyScaleFlying = 0.9

class 'GUIMarineJetpackHelp' (GUIAnimatedScript)

function GUIMarineJetpackHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("Jump")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.defaultKeySize = size
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    
    self.jetpackImage = self:CreateAnimatedGraphicItem()
    self.jetpackImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.jetpackImage:SetSize(Vector(kJetpackFrameWidth, kJetpackFrameHeight, 0))
    self.jetpackImage:SetPosition(Vector(-kJetpackFrameWidth / 2, -kJetpackFrameHeight, 0))
    self.jetpackImage:SetTexture(kJetpackImage)
    self.jetpackImage:SetColor(kGroundColor)
    self.jetpackImage:AddAsChildTo(self.keyBackground)
    self.jetpackImage:SetIsVisible(false)
    
end

function GUIMarineJetpackHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if not self.learnedToFly and player then
    
        if not self.jetpackImage:GetIsVisible() then
        
            HelpWidgetAnimateIn(self.jetpackImage)
            self.jetpackImage:SetIsVisible(true)
            
        end
        
        self.totalAirTime = self.totalAirTime or 0
        self.totalAirTime = player:GetIsOnGround() and self.totalAirTime or self.totalAirTime + dt
        self.keyBackground:SetIsVisible(self.totalAirTime < kTimeNeededToLearnToFly)
        local size = player:GetIsJetpacking() and (self.defaultKeySize * kKeyScaleFlying) or self.defaultKeySize
        self.keyBackground:SetSize(size)
        self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
        self.jetpackImage:SetColor(player:GetIsJetpacking() and kFlyingColor or kGroundColor)
        
        if not self.learnedToFly and self.totalAirTime >= kTimeNeededToLearnToFly then
        
            self.learnedToFly = true
            HelpWidgetIncreaseUse(self, "GUIMarineJetpackHelp")
            
        end
        
    end
    
end

function GUIMarineJetpackHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end