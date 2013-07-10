// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\GUIMineDisplay.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Displays the current number of bullets and clips for the ammo counter on a bullet weapon
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")
Script.Load("lua/Utility.lua")

weaponClip = 0

class 'GUIMineDisplay' (GUIScript)

local kBackgroundColor = Color(0.302, 0.859, 1, 0.2)

function GUIMineDisplay:Initialize()

    self.weaponClip = 0
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(256, 512, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetColor(kBackgroundColor)
    self.background:SetIsVisible(true)
    
    // Slightly larger copy of the text for a glow effect
    self.ammoTextBg = GUIManager:CreateTextItem()
    self.ammoTextBg:SetFontName("fonts/MicrogrammaDMedExt_large.fnt")
    self.ammoTextBg:SetScale(Vector(1.5, 1.5, 1.5))
    self.ammoTextBg:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoTextBg:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoTextBg:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.ammoTextBg:SetColor(Color(1, 1, 1, 0.25))
    
    // Text displaying the amount of ammo in the clip
    self.ammoText = GUIManager:CreateTextItem()
    self.ammoText:SetFontName("fonts/MicrogrammaDMedExt_large.fnt")
    self.ammoText:SetScale(Vector(1.5, 1.5, 1.5))
    self.ammoText:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    self.flashInOverlay = GUIManager:CreateGraphicItem()
    self.flashInOverlay:SetSize(Vector(256, 512, 0))
    self.flashInOverlay:SetPosition(Vector(0, 0, 0))    
    self.flashInOverlay:SetColor(Color(1, 1, 1, 0.7))
    
    // Force an update so our initial state is correct.
    self:Update(0)
    
end

function GUIMineDisplay:SetClip(clip)
    self.weaponClip = clip
end

function GUIMineDisplay:Update(deltaTime)

    PROFILE("GUIMineDisplay:Update")
    
    local ammoFormat = string.format("%d", self.weaponClip) 
    self.ammoText:SetText(ammoFormat)
    self.ammoTextBg:SetText(ammoFormat)
    
    local flashInAlpha = self.flashInOverlay:GetColor().a
    
    if flashInAlpha > 0 then
    
        local alphaPerSecond = 0.5 
        flashInAlpha = Clamp(flashInAlpha - alphaPerSecond * deltaTime, 0, 1)
        self.flashInOverlay:SetColor(Color(1, 1, 1, flashInAlpha))
        
    end
    
end

mineDisplay = nil

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    PROFILE("GUIMineDisplay Update")

    mineDisplay:SetClip(weaponClip)
    mineDisplay:Update(deltaTime)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize(256, 417)
    
    mineDisplay = GUIMineDisplay()
    mineDisplay:Initialize()
    
end

Initialize()