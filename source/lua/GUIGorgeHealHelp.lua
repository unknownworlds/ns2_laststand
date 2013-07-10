// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIGorgeHealHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kLeapTextureName = "ui/gorge_spit.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUIGorgeHealHelp' (GUIAnimatedScript)

function GUIGorgeHealHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("SecondaryAttack")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + kHelpBackgroundYOffset, 0))
    self.keyBackground:SetIsVisible(false)
    
    self.healImage = self:CreateAnimatedGraphicItem()
    self.healImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.healImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.healImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.healImage:SetTexture(kLeapTextureName)
    self.healImage:AddAsChildTo(self.keyBackground)
    
end

local function WeaponSupportsHeal(weapon)
    return weapon and HasMixin(weapon, "HealSpray")
end

local function GetHealingRequired(player)

    local status = PlayerUI_GetUnitStatusInfo()
    
    for s = 1, #status do
    
        local unitStatus = status[s].Status
        // Needs to be healable or buildable and within heal range.
        if (unitStatus == kUnitStatus.Damaged or unitStatus == kUnitStatus.Unbuilt) and
           (status[s].WorldOrigin - player:GetEyePos()):GetLengthSquared() <= (kHealsprayRadius * kHealsprayRadius) then
            return true
        end
        
    end
    
    return false
    
end

function GUIGorgeHealHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        local activeWeapon = player:GetActiveWeapon()
        local enableWidget = not self.healed and WeaponSupportsHeal(activeWeapon) and GetHealingRequired(player)
        if enableWidget and player:GetSecondaryAttackLastFrame() then
        
            self.healed = true
            HelpWidgetIncreaseUse(self, "GUIGorgeHealHelp")
            
        end
        
        local widgetVisible = enableWidget and not self.healed
        if not self.keyBackground:GetIsVisible() and widgetVisible then
            HelpWidgetAnimateIn(self.healImage)
        end
        
        self.keyBackground:SetIsVisible(widgetVisible == true)
        
    end
    
end

function GUIGorgeHealHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end