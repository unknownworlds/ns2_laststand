// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIHealthCircle.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays the health for structures.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/GUIDial.lua")

local healthCircle = nil

// Global state that can be externally set to adjust the circle.
healthPercentage = 0
buildPercentage = 0
armorPercentage = 0
ringAlpha = 1
useAlienStyle = 0

local kHealthCircleWidth = 512
local kHealthCircleHeight = 512

local kArmorCircleMinSize = Vector(374, 374, 0)
local kArmorCircleMaxSize = Vector(480, 480, 0)

local kArmorCircleSize = Vector(kHealthCircleWidth, kHealthCircleHeight, 0)
local kHealthCircleSize = Vector(kHealthCircleWidth, kHealthCircleHeight, 0)

local kHealthTextureName = "ui/health_circle.dds"
local kAlienHealthTextureName = "ui/health_circle_alien.dds"

local kBuildColor = Color(1, 0, 1)
// Colors to interpolate between starting from no health to full health.
local kHealthColorsMarine = { Color(0.8, 0, 0), Color(0.8, 0.7, 0), Color(0.7, 0.7, 0.7) }
local kHealthColorsAlien = { Color(0.8, 0, 0), Color(0.8, 0.5, 0), Color(0.7, 0.7, 0.7) }
local kNumberHealthColors = table.maxn(kHealthColorsMarine)

local kArmorCircleStencilCoords = { 512, 512, 1024, 1024 }
local kArmorCircleCoords = { 0, 512, 512, 1024 }

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    healthCircle:Update(deltaTime)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( kHealthCircleWidth, kHealthCircleHeight )

    healthCircle = GUIHealthCircle()
    healthCircle:Initialize()

end

class 'GUIHealthCircle'

function GUIHealthCircle:Initialize()
    
    local healthCircleSettings = { }
    healthCircleSettings.BackgroundWidth = kHealthCircleSize.x
    healthCircleSettings.BackgroundHeight = kHealthCircleSize.y
    healthCircleSettings.BackgroundAnchorX = GUIItem.Left
    healthCircleSettings.BackgroundAnchorY = GUIItem.Bottom
    healthCircleSettings.BackgroundOffset = Vector(0, 0, 0)
    healthCircleSettings.BackgroundTextureName = kHealthTextureName
    healthCircleSettings.BackgroundTextureX1 = 0
    healthCircleSettings.BackgroundTextureY1 = 0
    healthCircleSettings.BackgroundTextureX2 = kHealthCircleWidth
    healthCircleSettings.BackgroundTextureY2 = kHealthCircleHeight
    healthCircleSettings.ForegroundTextureName = kHealthTextureName
    healthCircleSettings.ForegroundTextureWidth = kHealthCircleWidth
    healthCircleSettings.ForegroundTextureHeight = kHealthCircleHeight
    healthCircleSettings.ForegroundTextureX1 = kHealthCircleWidth
    healthCircleSettings.ForegroundTextureY1 = 0
    healthCircleSettings.ForegroundTextureX2 = kHealthCircleWidth * 2
    healthCircleSettings.ForegroundTextureY2 = kHealthCircleHeight
    healthCircleSettings.InheritParentAlpha = true
    self.healthCircle = GUIDial()
    self.healthCircle:Initialize(healthCircleSettings)
    
    self.armorCircleStencil = GUIManager:CreateGraphicItem()
    self.armorCircleStencil:SetTexture(kHealthTextureName)
    self.armorCircleStencil:SetSize(kArmorCircleMinSize)
    self.armorCircleStencil:SetTexturePixelCoordinates(unpack(kArmorCircleStencilCoords))
    self.armorCircleStencil:SetIsStencil(true)
    self.armorCircleStencil:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    self.armorCircle = GUIManager:CreateGraphicItem()
    self.armorCircle:SetTexture(kHealthTextureName)
    self.armorCircle:SetSize(kArmorCircleSize)
    self.armorCircle:SetTexturePixelCoordinates(unpack(kArmorCircleCoords))
    self.armorCircle:SetStencilFunc(GUIItem.NotEqual)
    
end

function GUIHealthCircle:Uninitialize()

    if self.healthCircle then
        self.healthCircle:Uninitialize()
        self.healthCircle = nil
    end
    
end

function GUIHealthCircle:Update(deltaTime)

    PROFILE("GUIHealthCircle:Update")

    local usePercentage = math.min(math.max(healthPercentage, 0), 100) / 100

    local colorIndex = math.max(math.ceil(kNumberHealthColors * usePercentage), 1)
    local useColor = ConditionalValue(useAlienStyle == 1, kHealthColorsAlien[colorIndex], kHealthColorsMarine[colorIndex])
    useColor.a = ringAlpha
    
    self.healthCircle:SetPercentage(usePercentage)
    self.healthCircle:Update(deltaTime)
    self.healthCircle:GetLeftSide():SetColor(useColor)
    self.healthCircle:GetRightSide():SetColor(useColor)

    self.armorCircle:SetColor(Color(0.6, 0.6, 0.6, ringAlpha))
    
    local size = kArmorCircleMinSize + (kArmorCircleMaxSize - kArmorCircleMinSize) * (armorPercentage/100)
    self.armorCircleStencil:SetSize(size)
    self.armorCircleStencil:SetPosition(Vector(-size.x/2, -size.y/2, 0))
    
    if useAlienStyle == 1 then
        self.healthCircle:SetBackgroundTexture(kAlienHealthTextureName)
        self.healthCircle:SetForegroundTexture(kAlienHealthTextureName)
        self.armorCircle:SetTexture(kAlienHealthTextureName)
    else
        self.healthCircle:SetBackgroundTexture(kHealthTextureName)
        self.healthCircle:SetForegroundTexture(kHealthTextureName)
        self.armorCircle:SetTexture(kHealthTextureName)
    end
    
end

Initialize()