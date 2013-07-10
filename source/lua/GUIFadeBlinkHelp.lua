// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIFadeBlinkHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kBlinkTextureName = "ui/fade_blink.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUIFadeBlinkHelp' (GUIAnimatedScript)

function GUIFadeBlinkHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("SecondaryAttack")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.blinkImage = self:CreateAnimatedGraphicItem()
    self.blinkImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.blinkImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.blinkImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.blinkImage:SetTexture(kBlinkTextureName)
    self.blinkImage:AddAsChildTo(self.keyBackground)
    
end

function GUIFadeBlinkHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        if not self.blinked and player:GetIsBlinking() then
        
            self.blinked = true
            HelpWidgetIncreaseUse(self, "GUIFadeBlinkHelp")
            
        end
        
        local activeWeapon = player:GetActiveWeapon()
        local displayBlink = not self.blinked and activeWeapon and activeWeapon:GetHasSecondary(player)
        
        if not self.keyBackground:GetIsVisible() and displayBlink then
            HelpWidgetAnimateIn(self.blinkImage)
        end
        
        self.keyBackground:SetIsVisible(displayBlink == true)
        
    end
    
end

function GUIFadeBlinkHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end