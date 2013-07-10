// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUISkulkParasiteHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kParasiteTextureName = "ui/parasite.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUISkulkParasiteHelp' (GUIAnimatedScript)

function GUISkulkParasiteHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetColor(Color(0, 0, 0, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.background:SetSize(Vector(200, 200, 0))
    self.background:SetPosition(Vector(-100, -100 + kHelpBackgroundYOffset, 0))
    
    self.keyBackground = GUICreateButtonIcon("Weapon" .. kParasiteHUDSlot)
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y / 2 + 16, 0))
    self.background:AddChild(self.keyBackground)
    
    self.attackKeyBackground = GUICreateButtonIcon("PrimaryAttack")
    self.attackKeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    size = self.attackKeyBackground:GetSize()
    self.attackKeyBackground:SetPosition(Vector(-size.x / 2, -size.y / 2 + 16, 0))
    self.attackKeyBackground:SetIsVisible(false)
    self.background:AddChild(self.attackKeyBackground)
    
    self.parasiteImage = self:CreateAnimatedGraphicItem()
    self.parasiteImage:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.parasiteImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.parasiteImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.parasiteImage:SetTexture(kParasiteTextureName)
    self.parasiteImage:SetIsVisible(false)
    self.parasiteImage:AddAsChildTo(self.background)
    
end

function GUISkulkParasiteHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    self.keyBackground:SetIsVisible(false)
    self.attackKeyBackground:SetIsVisible(false)
    
    if not self.parasiteUsed then
    
        local player = Client.GetLocalPlayer()
        if player then
        
            if not self.parasiteImage:GetIsVisible() then
                HelpWidgetAnimateIn(self.parasiteImage)
            end
            self.parasiteImage:SetIsVisible(true)
            
            // Show the switch weapon key until they change to the parasite.
            local parasiteEquipped = player:GetActiveWeapon() and player:GetActiveWeapon():isa("Parasite")
            self.keyBackground:SetIsVisible(parasiteEquipped ~= true)
            self.attackKeyBackground:SetIsVisible(parasiteEquipped == true)
            if parasiteEquipped and player:GetPrimaryAttackLastFrame() then
            
                self.keyBackground:SetIsVisible(false)
                self.attackKeyBackground:SetIsVisible(false)
                self.parasiteImage:SetIsVisible(false)
                self.parasiteUsed = true
                HelpWidgetIncreaseUse(self, "GUISkulkParasiteHelp")
                
            end
            
        end
        
    end
    
end

function GUISkulkParasiteHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
    GUI.DestroyItem(self.attackKeyBackground)
    self.attackKeyBackground = nil
    
    GUI.DestroyItem(self.parasiteImage)
    self.parasiteImage = nil
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
end