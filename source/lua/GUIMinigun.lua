// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUILeftMinigunDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays the heat amount for the Exo's Minigun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local animHeatAmount = 0
local animHeatDir = 1

local background = nil

local foreground = nil
local foregroundMask = nil

local alertLight = nil

local time = 0

local kTexture = "models/marine/exosuit/exosuit_view_panel_mini2.dds"

function UpdateOverHeat(dt, heatAmount)

    PROFILE("GUILeftMinigunDisplay:Update")
    
    foregroundMask:SetSize(Vector(242, 720 * (1 - heatAmount), 0))
    
    local alertColor = Color(1, 1, 1, 1)
    if heatAmount > 0.5 then
    
        animHeatAmount = animHeatAmount + ((animHeatDir * dt) * 10 * heatAmount)
        if animHeatAmount > 1 then
        
            animHeatAmount = 1
            animHeatDir = -1
            
        elseif animHeatAmount < 0 then
        
            animHeatAmount = 0
            animHeatDir = 1
            
        end
        alertColor = Color(heatAmount, animHeatAmount * (1 - ((heatAmount - 0.5) / 0.5)), 0, 1)
        
    end
    alertLight:SetColor(alertColor)
    
    time = time + dt
    
end

function Initialize()

    GUI.SetSize(242, 720)
    
    background = GUI.CreateItem()
    background:SetSize(Vector(242, 720, 0))
    background:SetPosition(Vector(0, 0, 0))
    background:SetTexturePixelCoordinates(0, 0, 230, 512)
    background:SetTexture(kTexture)
    
    foreground = GUI.CreateItem()
    foreground:SetSize(Vector(230, 720, 0))
    foreground:SetPosition(Vector(0, 0, 0))
    foreground:SetTexturePixelCoordinates(300, 0, 512, 512)
    foreground:SetTexture(kTexture)
    foreground:SetStencilFunc(GUIItem.Equal)
    
    foregroundMask = GUI.CreateItem()
    foregroundMask:SetSize(Vector(242, 720, 0))
    foregroundMask:SetPosition(Vector(0, 0, 0))
    foregroundMask:SetIsStencil(true)
    foregroundMask:SetClearsStencilBuffer(true)
    
    foregroundMask:AddChild(foreground)
    
    alertLight = GUI.CreateItem()
    alertLight:SetSize(Vector(60, 720, 0))
    alertLight:SetPosition(Vector(0, 0, 0))
    alertLight:SetTexturePixelCoordinates(240, 0, 290, 512)
    alertLight:SetTexture(kTexture)
    
    background:AddChild(foregroundMask)
    background:AddChild(alertLight)
    
end

Initialize()