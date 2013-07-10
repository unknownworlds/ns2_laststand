// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIFadeShadowStepHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kShadowTextureName = "ui/fade_shadow.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUIFadeShadowStepHelp' (GUIAnimatedScript)

function GUIFadeShadowStepHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("MovementModifier")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.shadowImage = self:CreateAnimatedGraphicItem()
    self.shadowImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.shadowImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.shadowImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.shadowImage:SetTexture(kShadowTextureName)
    self.shadowImage:AddAsChildTo(self.keyBackground)
    
end

function GUIFadeShadowStepHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        if not self.shadowStepped and not self.keyBackground:GetIsVisible() then
            HelpWidgetAnimateIn(self.shadowImage)
        end
        
        if not self.shadowStepped and player:GetIsShadowStepping() then
        
            self.shadowStepped = true
            HelpWidgetIncreaseUse(self, "GUIFadeShadowStepHelp")
            
        end
        
        self.keyBackground:SetIsVisible(not self.shadowStepped)
        
    end
    
end

function GUIFadeShadowStepHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end