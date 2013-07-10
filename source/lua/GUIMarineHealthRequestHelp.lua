// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIMarineHealthRequestHelp.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kRequestHealthImage = "ui/marine_health_call.dds"
local kRequestHealthFrameWidth = 128
local kRequestHealthFrameHeight = 128

class 'GUIMarineHealthRequestHelp' (GUIAnimatedScript)

function GUIMarineHealthRequestHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("RequestHealth")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.requestHealthImage = self:CreateAnimatedGraphicItem()
    self.requestHealthImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.requestHealthImage:SetSize(Vector(kRequestHealthFrameWidth, kRequestHealthFrameHeight, 0))
    self.requestHealthImage:SetPosition(Vector(-kRequestHealthFrameWidth / 2, -kRequestHealthFrameHeight, 0))
    self.requestHealthImage:SetTexture(kRequestHealthImage)
    self.requestHealthImage:AddAsChildTo(self.keyBackground)
    
end

function GUIMarineHealthRequestHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player and not self.requestedHelp then

        assert(HasMixin(player, "Live"))
        
        local needsMedpack = (player:GetHealth() <= 50)        

        local newVisibility = needsMedpack and (player.timeOfLastHealRequest == nil or (Shared.GetTime() > player.timeOfLastHealRequest + 20) )

        if self.keyBackground:GetIsVisible() and (newVisibility == false) then
        
            HelpWidgetIncreaseUse(self, "GUIMarineHealthRequestHelp")
            self.requestedHelp = true
            
        end
        
        if not self.keyBackground:GetIsVisible() and newVisibility then
            HelpWidgetAnimateIn(self.requestHealthImage)
        end
        
        self.keyBackground:SetIsVisible(newVisibility)
        
    end
    
end

function GUIMarineHealthRequestHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end