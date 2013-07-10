// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUISkulkLeapHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kLeapTextureName = "ui/skulk_jump.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUISkulkLeapHelp' (GUIAnimatedScript)

function GUISkulkLeapHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("SecondaryAttack")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.leapImage = self:CreateAnimatedGraphicItem()
    self.leapImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.leapImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.leapImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.leapImage:SetTexture(kLeapTextureName)
    self.leapImage:AddAsChildTo(self.keyBackground)
    
end

function GUISkulkLeapHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        if not self.leaped and player:GetIsLeaping() then
        
            self.leaped = true
            HelpWidgetIncreaseUse(self, "GUISkulkLeapHelp")
            
        end
        
        local activeWeapon = player:GetActiveWeapon()
        local displayLeap = not self.leaped and activeWeapon and activeWeapon:GetHasSecondary(player)
        
        if not self.keyBackground:GetIsVisible() and displayLeap then
            HelpWidgetAnimateIn(self.leapImage)
        end
        
        self.keyBackground:SetIsVisible(displayLeap == true)
        
    end
    
end

function GUISkulkLeapHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end