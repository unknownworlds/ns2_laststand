// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIGorgeBellySlideHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kBellyTextureName = "ui/gorge_slide.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUIGorgeBellySlideHelp' (GUIAnimatedScript)

function GUIGorgeBellySlideHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("MovementModifier")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.bellySlideImage = self:CreateAnimatedGraphicItem()
    self.bellySlideImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.bellySlideImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.bellySlideImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.bellySlideImage:SetTexture(kBellyTextureName)
    self.bellySlideImage:AddAsChildTo(self.keyBackground)
    
end

function GUIGorgeBellySlideHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if not self.bellySlideUsed and player then
    
        if player:GetVelocity():GetLength() > 1 then
        
            if not self.keyBackground:GetIsVisible() then
                HelpWidgetAnimateIn(self.bellySlideImage)
            end
            
            self.keyBackground:SetIsVisible(true)
            
            if player:GetIsBellySliding() then
            
                self.bellySlideUsed = true
                HelpWidgetIncreaseUse(self, "GUIGorgeBellySlideHelp")
                self.keyBackground:SetIsVisible(false)
                
            end
            
        else
            self.keyBackground:SetIsVisible(false)
        end
        
    end
    
end

function GUIGorgeBellySlideHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end