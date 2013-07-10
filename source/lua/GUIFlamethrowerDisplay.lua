// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIFlamethrowerDisplay.lua
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

bulletDisplay  = nil

//GUIFlamethrowerDisplay.kClipDisplay = { 0, 198, 20, 103 }
local kBgTexCoords = { 0, 0, 128, 256 }
local kBarTexCoords = { 148, 34, 233, 238 }
local kClipHeight = 200

class 'GUIFlamethrowerDisplay' (GUIScript)

function GUIFlamethrowerDisplay:Initialize()

    self.weaponClip     = 0
    self.maxClip = 30
    
    self.flashInDelay = 1.2

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.background:SetSize( Vector(128, 256, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/FlamethrowerDisplay.dds")
    self.background:SetTexturePixelCoordinates(unpack(kBgTexCoords))
    
    self.clipDisplay = GUIManager:CreateGraphicItem()
    self.clipDisplay:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.clipDisplay:SetSize(Vector(85, -kClipHeight, 0))
    self.clipDisplay:SetPosition(Vector(20, 230, 0) )
    self.clipDisplay:SetTexture("ui/FlamethrowerDisplay.dds")
    self.clipDisplay:SetTexturePixelCoordinates(unpack(kBarTexCoords))

    self.background:AddChild(self.clipDisplay)
    self.background:SetIsVisible(false)
    
    self.flashInOverlay = GUIManager:CreateGraphicItem()
    self.flashInOverlay:SetSize( Vector(128, 256, 0) )
    self.flashInOverlay:SetPosition( Vector(0, 0, 0))    
    self.flashInOverlay:SetColor(Color(1,1,1,0.0))
    
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIFlamethrowerDisplay:Update(deltaTime)

    PROFILE("GUIFlamethrowerDisplay:Update")
    
    // Update the clip and ammo counter.
    local clipFraction = self.weaponClip / self.maxClip
    local clipHeigth = kClipHeight * clipFraction * -1
  
    self.clipDisplay:SetSize( Vector(85, clipHeigth, 0) )
    
    local y1 = (kBarTexCoords[2] - kBarTexCoords[4]) * clipFraction + kBarTexCoords[4]
    
    self.clipDisplay:SetTexturePixelCoordinates(kBarTexCoords[1], y1, kBarTexCoords[3], kBarTexCoords[4]  )

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

function GUIFlamethrowerDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUIFlamethrowerDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUIFlamethrowerDisplay:SetAmmo(weaponAmmo)
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

    GUI.SetSize( 128, 256 )

    bulletDisplay = GUIFlamethrowerDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(50)

end

Initialize()
