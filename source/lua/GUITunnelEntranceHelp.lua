// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUITunnelEntranceHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kBlinkTextureName = "ui/enter_tunnel.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUITunnelEntranceHelp' (GUIAnimatedScript)

function GUITunnelEntranceHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.tunnelImage = self:CreateAnimatedGraphicItem()
    self.tunnelImage:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.tunnelImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.tunnelImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight + kHelpBackgroundYOffset, 0))
    self.tunnelImage:SetTexture(kBlinkTextureName)
    self.tunnelImage:SetIsVisible(false)
    
    self.wasInTunnel = false
    
end

function GUITunnelEntranceHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player and not self.wasInTunnel then
    
        if GetIsPointInGorgeTunnel(player:GetOrigin()) then
        
            HelpWidgetIncreaseUse(self, "GUITunnelEntranceHelp")   
            self.wasInTunnel = true 
            
        else
        
            local entrances = GetEntitiesWithinRange("TunnelEntrance", player:GetOrigin(), 4)
            local showWidget = #entrances > 0 and entrances[1]:GetIsBuilt()
            if showWidget and not self.tunnelImage:GetIsVisible() then
                HelpWidgetAnimateIn(self.tunnelImage)
            end
            
            self.tunnelImage:SetIsVisible(showWidget)
        
        end
        
    end
    
end

function GUITunnelEntranceHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end