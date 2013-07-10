// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIGrenadelauncherDisplay.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Displays the ammo counter for the shotgun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")
Script.Load("lua/Utility.lua")

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0
pitch          = 0

bulletDisplay  = nil

//GUIGrenadelauncherDisplay.kammoDisplay = { 0, 198, 20, 103 }
local kViewPitchTexCoords = { 12, 32, 105, 221 }
local kBgTexCoords = { 128, 0, 256, 225 }
local kGrenadeBlueTexCoords = { 104, 231, 175, 252 }
local kGrenadeRedTexCoords = { 181, 231, 252, 252 }
local kClipHeight = 200
local kNumGrenades = 4
local kGrenadeHeight = 30
local kGrenadeOffset = -4
local kGrenadeWidth = 75

local kTexture = "models/marine/grenadelauncher/grenade_launcher_view_display.dds"

class 'GUIGrenadelauncherDisplay' (GUIScript)

function GUIGrenadelauncherDisplay:Initialize()

    self.maxClip = 30
    self.weaponClip = 0
    self.weaponAmmo = 0
    
    self.flashInDelay = 1.2
    
    self.viewPitch = GUIManager:CreateGraphicItem()
    self.viewPitch:SetSize( Vector(128, 256, 0) )
    self.viewPitch:SetPosition( Vector(0, 0, 0))    
    self.viewPitch:SetTexture(kTexture)
    self.viewPitch:SetTexturePixelCoordinates(unpack(kViewPitchTexCoords))
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(128, 256, 0) )
    self.background:SetPosition( Vector(128, 0, 0))    
    self.background:SetTexture(kTexture)
    self.background:SetTexturePixelCoordinates(unpack(kBgTexCoords))
    
    self.ammoDisplay = GUIManager:CreateTextItem()
    self.ammoDisplay:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.ammoDisplay:SetFontName("fonts/MicrogrammaDMedExt_large.fnt")
    self.ammoDisplay:SetScale(Vector(0.5, 0.5, 0))
    self.ammoDisplay:SetPosition(Vector(0, -50, 0))
    self.ammoDisplay:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoDisplay:SetTextAlignmentY(GUIItem.Align_Center)

    self.background:SetIsVisible(false)
    
    self.flashInOverlay = GUIManager:CreateGraphicItem()
    self.flashInOverlay:SetSize( Vector(128, 256, 0) )
    self.flashInOverlay:SetPosition( Vector(0, 0, 0))    
    self.flashInOverlay:SetColor(Color(1,1,1,0.0))
    
    self.background:AddChild(self.ammoDisplay)
    self.background:AddChild(self.flashInOverlay)
    
    self.grenadeIcons = {}
    
    for i = 1, kNumGrenades do
    
        local grenadeIcon = GUIManager:CreateGraphicItem()
        grenadeIcon:SetTexture(kTexture)
        grenadeIcon:SetSize(Vector(kGrenadeWidth, kGrenadeHeight, 0))
        grenadeIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
        grenadeIcon:SetPosition(Vector(kGrenadeWidth * -.5, (kGrenadeHeight + 6) * i + kGrenadeOffset, 0))
        grenadeIcon:SetTexturePixelCoordinates(unpack(kGrenadeBlueTexCoords))
        grenadeIcon:SetBlendTechnique(GUIItem.Add)
        
        self.background:AddChild(grenadeIcon)
        
        table.insert(self.grenadeIcons, grenadeIcon)
    
    end
    
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIGrenadelauncherDisplay:Update(deltaTime)

    PROFILE("GUIGrenadelauncherDisplay:Update")

    self.ammoDisplay:SetText(ToString(self.weaponAmmo))

    for i = 1, kNumGrenades do
    
        local grenadeIcon = self.grenadeIcons[i]
        grenadeIcon:SetIsVisible(kNumGrenades - weaponClip < i)
    
        if i == kNumGrenades then
        
            if self.weaponClip == 1 then
                grenadeIcon:SetTexturePixelCoordinates(unpack(kGrenadeRedTexCoords))
            else
                grenadeIcon:SetTexturePixelCoordinates(unpack(kGrenadeBlueTexCoords))
            end
            
        end
    
    end

    if self.flashInDelay > 0 then
    
        self.flashInDelay = Clamp(self.flashInDelay - deltaTime, 0, 5)
        
        if self.flashInDelay == 0 then
            self.flashInOverlay:SetColor(Color(1,1,1,0.7))
            self.background:SetIsVisible(true)
        end
    
    else
    
        local flashInAlpha = self.flashInOverlay:GetColor().a    
        if flashInAlpha > 0 then
        
            local alphaPerSecond = .5        
            flashInAlpha = Clamp(flashInAlpha - alphaPerSecond * deltaTime, 0, 1)
            self.flashInOverlay:SetColor(Color(1, 1, 1, flashInAlpha))
            
        end
    
    end
    
end

function GUIGrenadelauncherDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUIGrenadelauncherDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUIGrenadelauncherDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:Update(deltaTime)
        
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 256 )

    bulletDisplay = GUIGrenadelauncherDisplay()
    bulletDisplay:Initialize()

end

Initialize()
