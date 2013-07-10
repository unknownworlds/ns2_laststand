// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIMarineFlashlightHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kFlashlightTextureName = "ui/marine_flashlight.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUIMarineFlashlightHelp' (GUIAnimatedScript)

function GUIMarineFlashlightHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("ToggleFlashlight")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.flashlightImage = self:CreateAnimatedGraphicItem()
    self.flashlightImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.flashlightImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.flashlightImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.flashlightImage:SetTexture(kFlashlightTextureName)
    self.flashlightImage:AddAsChildTo(self.keyBackground)
    
end

function GUIMarineFlashlightHelp:Update(dt)

    GUIAnimatedScript.Update(self, deltaTime)
    
    if not self.flashlightUsed then
    
        // Only display when the player is in a location that is not powered. A dark room.
        if PlayerUI_GetLocationPower()[3] == kLightMode.NoPower then
        
            if not self.keyBackground:GetIsVisible() then
                HelpWidgetAnimateIn(self.flashlightImage)
            end
            
            self.keyBackground:SetIsVisible(true)
            local player = Client.GetLocalPlayer()
            if player then
            
                if player:GetFlashlightOn() then
                
                    self.keyBackground:SetIsVisible(false)
                    self.flashlightUsed = true
                    HelpWidgetIncreaseUse(self, "GUIMarineFlashlightHelp")
                    
                end
                
            end
            
        end
        
    end
    
end

function GUIMarineFlashlightHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end