// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIRailgun.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays the charge amount for the Exo's Railgun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIDial.lua")

local kTexture = "models/marine/exosuit/exosuit_view_panel_rail2.dds"

local chargeCircle = nil
local shootSquares = { }
local cooldownSquares = { }
local time = 0

function UpdateCharge(dt, chargeAmount, timeSinceLastShot)

    PROFILE("GUIRailgun:UpdateCharge")
    
    local pulseAmt = (1 + math.cos(time * 20)) * 0.5
    local colorAmt = chargeAmount >= 1 and (pulseAmt * 0.5) or 1
    chargeCircle:GetLeftSide():SetColor(Color(1, colorAmt, colorAmt, 1))
    chargeCircle:GetRightSide():SetColor(Color(1, colorAmt, colorAmt, 1))
    
    for s = 1, #cooldownSquares do
        cooldownSquares[s]:SetIsVisible(timeSinceLastShot < (0.25 * s))
    end
    
    chargeCircle:SetPercentage(chargeAmount)
    chargeCircle:Update(dt)
    
    time = time + dt
    
end

local kWidth = 246
local kHeight = 256
function Initialize()

    GUI.SetSize(kWidth, kHeight)
    
    local chargeCircleSettings = { }
    chargeCircleSettings.BackgroundWidth = kWidth
    chargeCircleSettings.BackgroundHeight = kHeight
    chargeCircleSettings.BackgroundAnchorX = GUIItem.Left
    chargeCircleSettings.BackgroundAnchorY = GUIItem.Bottom
    chargeCircleSettings.BackgroundOffset = Vector(0, 0, 0)
    chargeCircleSettings.BackgroundTextureName = kTexture
    chargeCircleSettings.BackgroundTextureX1 = 0
    chargeCircleSettings.BackgroundTextureY1 = 0
    chargeCircleSettings.BackgroundTextureX2 = kWidth
    chargeCircleSettings.BackgroundTextureY2 = kHeight
    chargeCircleSettings.ForegroundTextureName = kTexture
    chargeCircleSettings.ForegroundTextureWidth = kWidth
    chargeCircleSettings.ForegroundTextureHeight = kHeight
    chargeCircleSettings.ForegroundTextureX1 = kWidth
    chargeCircleSettings.ForegroundTextureY1 = 0
    chargeCircleSettings.ForegroundTextureX2 = kWidth * 2
    chargeCircleSettings.ForegroundTextureY2 = kHeight
    chargeCircleSettings.InheritParentAlpha = true
    chargeCircle = GUIDial()
    chargeCircle:Initialize(chargeCircleSettings)
    chargeCircle:GetBackground():SetIsVisible(true)
    
    local x = 80
    for s = 1, 4 do
    
        table.insert(shootSquares, GUIManager:CreateGraphicItem())
        table.insert(cooldownSquares, GUIManager:CreateGraphicItem())
        
        shootSquares[s]:SetSize(Vector(20, 48, 0))
        cooldownSquares[s]:SetSize(Vector(20, 48, 0))
        shootSquares[s]:SetTexturePixelCoordinates(492, 0, 512, 48)
        cooldownSquares[s]:SetTexturePixelCoordinates(492, 48, 512, 96)
        shootSquares[s]:SetPosition(Vector(x, 100, 0))
        cooldownSquares[s]:SetPosition(Vector(x, 100, 0))
        x = x + 22
        shootSquares[s]:SetTexture(kTexture)
        cooldownSquares[s]:SetTexture(kTexture)
        
        cooldownSquares[s]:SetIsVisible(false)
        
    end
    
end

Initialize()