// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIHarvesterColor.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

local kTextureName = "models/alien/harvester/harvester_illum.dds"
local kTextureResolution = { 2048, 2048 }

// Global state that can be externally set to adjust the display.
resourceScalar     = 0

harvesterTexture  = nil

class 'GUIHarvesterColor' (GUIScript)

function GUIHarvesterColor:Initialize()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(kTextureResolution[1], kTextureResolution[2], 0))
    self.background:SetTexture(kTextureName)

end

function GUIHarvesterColor:SetIntensity(intensity)

    local intensity = intensity / 100
    self.background:SetColor(Color(math.min(1, intensity + .5), intensity, intensity, 1))

end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    harvesterTexture:SetIntensity(resourceScalar)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( unpack(kTextureResolution) )

    harvesterTexture = GUIHarvesterColor()
    harvesterTexture:Initialize()

end

Initialize()