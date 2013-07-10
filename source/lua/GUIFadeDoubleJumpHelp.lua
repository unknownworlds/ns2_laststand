// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIFadeDoubleJumpHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kJumpTextureName = "ui/fade_double_jump.dds"

local kIconWidth = 128
local kIconHeight = 128

local kInvisibleColor = Color(1, 1, 1, 0)
local kVisibleColor = Color(1, 1, 1, 1)

local kFontName = "fonts/Stamp_large.fnt"

class 'GUIFadeDoubleJumpHelp' (GUIAnimatedScript)

function GUIFadeDoubleJumpHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("Jump")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.plusSymbol = self:CreateAnimatedTextItem()
    self.plusSymbol:SetAnchor(GUIItem.Right, GUIItem.Middle)
    self.plusSymbol:SetTextAlignmentX(GUIItem.Align_Center)
    self.plusSymbol:SetTextAlignmentY(GUIItem.Align_Center)
    self.plusSymbol:SetPosition(Vector(16, 0, 0))
    self.plusSymbol:SetColor(kAlienTeamColorFloat)
    self.plusSymbol:SetFontName(kFontName)
    self.plusSymbol:SetText("+")
    self.plusSymbol:AddAsChildTo(self.keyBackground)
    
    self.keyBackground2 = GUICreateButtonIcon("Jump")
    self.keyBackground2:SetAnchor(GUIItem.Right, GUIItem.Middle)
    local size = self.keyBackground2:GetSize()
    self.keyBackground2:SetPosition(Vector(22, -size.y / 2, 0))
    self.keyBackground:AddChild(self.keyBackground2)
    
    self.jumpImage = self:CreateAnimatedGraphicItem()
    self.jumpImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.jumpImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.jumpImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.jumpImage:SetTexture(kJumpTextureName)
    self.jumpImage:AddAsChildTo(self.keyBackground)
    
end

function GUIFadeDoubleJumpHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        if not self.doubleJumped and player:GetHasDoubleJumped() then
        
            self.doubleJumped = true
            HelpWidgetIncreaseUse(self, "GUIFadeDoubleJumpHelp")
            
        end
        
        if not self.doubleJumped and player:GetIsJumping() then
            self.keyBackground:SetColor(kInvisibleColor)
        else
            self.keyBackground:SetColor(kVisibleColor)
        end
        
        if not self.keyBackground:GetIsVisible() and not self.doubleJumped then
            HelpWidgetAnimateIn(self.jumpImage)
        end
        
        self.keyBackground:SetIsVisible(not self.doubleJumped)
        
    end
    
end

function GUIFadeDoubleJumpHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end