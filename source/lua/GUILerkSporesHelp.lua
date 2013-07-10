// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUILerkSporesHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSporesTextureName = "ui/lerk_spores.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUILerkSporesHelp' (GUIAnimatedScript)

function GUILerkSporesHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetColor(Color(0, 0, 0, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.background:SetSize(Vector(200, 200, 0))
    self.background:SetPosition(Vector(-100, -100 + kHelpBackgroundYOffset, 0))
    
    self.keyBackground = GUICreateButtonIcon("Weapon" .. kSporesHUDSlot)
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
    
    self.sporesImage = self:CreateAnimatedGraphicItem()
    self.sporesImage:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.sporesImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.sporesImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.sporesImage:SetTexture(kSporesTextureName)
    self.sporesImage:SetIsVisible(false)
    self.sporesImage:AddAsChildTo(self.background)
    
end

function GUILerkSporesHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    self.keyBackground:SetIsVisible(false)
    self.attackKeyBackground:SetIsVisible(false)
    
    if not self.sporesUsed then
    
        local player = Client.GetLocalPlayer()
        if player then
        
            local sporesWeapon = player:GetWeaponInHUDSlot(kSporesHUDSlot)
            local displayWidget = not self.sporesUsed and sporesWeapon
            
            if displayWidget then
            
                if not self.sporesImage:GetIsVisible() then
                    HelpWidgetAnimateIn(self.sporesImage)
                end
                self.sporesImage:SetIsVisible(true)
                
                // Show the switch weapon key until they change to the spores.
                local sporesEquipped = player:GetActiveWeapon() == sporesWeapon
                self.keyBackground:SetIsVisible(sporesEquipped ~= true)
                self.attackKeyBackground:SetIsVisible(sporesEquipped == true)
                if sporesEquipped and player:GetPrimaryAttackLastFrame() then
                
                    self.keyBackground:SetIsVisible(false)
                    self.attackKeyBackground:SetIsVisible(false)
                    self.sporesImage:SetIsVisible(false)
                    self.sporesUsed = true
                    HelpWidgetIncreaseUse(self, "GUILerkSporesHelp")
                    
                end
                
            end
            
        end
        
    end
    
end

function GUILerkSporesHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
    GUI.DestroyItem(self.attackKeyBackground)
    self.attackKeyBackground = nil
    
    GUI.DestroyItem(self.sporesImage)
    self.sporesImage = nil
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
end