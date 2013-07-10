// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIAlienVisionHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kVisionTextureName = "ui/alien_night_vision.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUIAlienVisionHelp' (GUIAnimatedScript)

function GUIAlienVisionHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("ToggleFlashlight")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.visionImage = self:CreateAnimatedGraphicItem()
    self.visionImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.visionImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.visionImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.visionImage:SetTexture(kVisionTextureName)
    self.visionImage:AddAsChildTo(self.keyBackground)
    
end

function GUIAlienVisionHelp:Update(dt)

    GUIAnimatedScript.Update(self, deltaTime)
    
    if not self.alienVisionUsed then
    
        // Only display when the player is in a location that is not powered. A dark room.
        if PlayerUI_GetLocationPower()[3] == kLightMode.NoPower then
        
            if not self.keyBackground:GetIsVisible() then
                HelpWidgetAnimateIn(self.visionImage)
            end
            
            self.keyBackground:SetIsVisible(true)
            local player = Client.GetLocalPlayer()
            if player then
            
                if player:GetDarkVisionEnabled() then
                
                    self.keyBackground:SetIsVisible(false)
                    self.alienVisionUsed = true
                    HelpWidgetIncreaseUse(self, "GUIAlienVisionHelp")
                    
                end
                
            end
            
        end
        
    end
    
end

function GUIAlienVisionHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end