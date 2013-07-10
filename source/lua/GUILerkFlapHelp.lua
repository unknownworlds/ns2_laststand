// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUILerkFlapHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kFlapFrames = { "ui/lerk_fly1.dds", "ui/lerk_fly2.dds" }
local kFlapFrameWidth = 128
local kFlapFrameHeight = 128

local kTimeNeededToLearnToFly = 8

local kKeyScaleFlying = 0.9

class 'GUILerkFlapHelp' (GUIAnimatedScript)

function GUILerkFlapHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("Jump")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.defaultKeySize = size
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.currentFlapFrame = 1
    self.flapImage = self:CreateAnimatedGraphicItem()
    self.flapImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.flapImage:SetSize(Vector(kFlapFrameWidth, kFlapFrameHeight, 0))
    self.flapImage:SetPosition(Vector(-kFlapFrameWidth / 2, -kFlapFrameHeight, 0))
    self.flapImage:SetTexture(kFlapFrames[self.currentFlapFrame])
    self.flapImage:AddAsChildTo(self.keyBackground)
    
end

function GUILerkFlapHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        local timeOfLastFlap = player:GetTimeOfLastFlap()
        self.timeOfLastFlap = self.timeOfLastFlap or 0
        if math.abs(self.timeOfLastFlap - timeOfLastFlap) > 0.05 then
        
            self.timeOfLastFlap = timeOfLastFlap
            self.currentFlapFrame = self.currentFlapFrame + 1
            self.flapImage:SetTexture(kFlapFrames[(self.currentFlapFrame % #kFlapFrames) + 1])
            
        end
        
        self.totalAirTime = self.totalAirTime or 0
        self.totalAirTime = player:GetIsOnGround() and self.totalAirTime or self.totalAirTime + dt
        
        local visible = self.totalAirTime < kTimeNeededToLearnToFly
        
        if not self.keyBackground:GetIsVisible() and visible then
            HelpWidgetAnimateIn(self.flapImage)
        end
        
        self.keyBackground:SetIsVisible(visible)
        
        // Make the key background smaller shortly after the player has flapped to indicate multiple presses.
        local size = ((Shared.GetTime() - timeOfLastFlap) < 0.2) and (self.defaultKeySize * kKeyScaleFlying) or self.defaultKeySize
        size.y = self.defaultKeySize.y
        self.keyBackground:SetSize(size)
        self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
        
        if not self.learnedToFly and self.totalAirTime >= kTimeNeededToLearnToFly then
        
            self.learnedToFly = true
            HelpWidgetIncreaseUse(self, "GUILerkFlapHelp")
            
        end
        
    end
    
end

function GUILerkFlapHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end