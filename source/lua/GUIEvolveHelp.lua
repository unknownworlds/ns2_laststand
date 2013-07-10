// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIEvolveHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kEvolveGraphic = "ui/alien_evolution.dds"
local kWidth = 128
local kHeight = 128

class 'GUIEvolveHelp' (GUIAnimatedScript)

function GUIEvolveHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("Buy")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.currentFlapFrame = 1
    self.evolveGraphic = self:CreateAnimatedGraphicItem()
    self.evolveGraphic:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.evolveGraphic:SetSize(Vector(kWidth, kHeight, 0))
    self.evolveGraphic:SetPosition(Vector(-kWidth / 2, -kHeight, 0))
    self.evolveGraphic:SetTexture(kEvolveGraphic)
    self.evolveGraphic:AddAsChildTo(self.keyBackground)
    
end

function GUIEvolveHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local helpVisible = false
    local player = Client.GetLocalPlayer()
    if player then
    
        if not self.learnedToEvolve and player:GetGameStarted() then
        
            local nearHive = #GetEntitiesForTeamWithinRange("Hive", player:GetTeamNumber(), player:GetOrigin(), 10) > 0
            local nearbyUnitsUnderAttack = GetAnyNearbyUnitsInCombat(player:GetOrigin(), 20, player:GetTeamNumber())
            if nearHive and not nearbyUnitsUnderAttack then
            
                if player:GetBuyMenuIsDisplaying() then
                
                    self.learnedToEvolve = true
                    HelpWidgetIncreaseUse(self, "GUIEvolveHelp")
                    
                else
                    helpVisible = true
                end
                
            end
            
        end
        
    end
    
    if not self.keyBackground:GetIsVisible() and helpVisible then
        HelpWidgetAnimateIn(self.evolveGraphic)
    end
    
    self.keyBackground:SetIsVisible(helpVisible)
    
end

function GUIEvolveHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end