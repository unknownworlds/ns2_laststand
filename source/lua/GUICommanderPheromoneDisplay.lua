// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUICommanderPheromoneDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kTextureName =  "ui/buildmenu.dds"
local kOrderPixelWidth = 80
local kOrderPixelHeight = 80

local kStartScale = .3
local kGrowTime = .2
local kBaseScale = 1.0

local kPheromoneTextureCoords = { }
kPheromoneTextureCoords[kTechId.ThreatMarker] = { 0, 0, kOrderPixelWidth, kOrderPixelHeight }
kPheromoneTextureCoords[kTechId.LargeThreatMarker] = { 0, 0, kOrderPixelWidth, kOrderPixelHeight }
kPheromoneTextureCoords[kTechId.NeedHealingMarker] = { kOrderPixelWidth * 5, kOrderPixelWidth, kOrderPixelWidth * 6, kOrderPixelHeight * 2}
kPheromoneTextureCoords[kTechId.WeakMarker] = { kOrderPixelWidth * 5, kOrderPixelWidth, kOrderPixelWidth * 6, kOrderPixelHeight * 2}
kPheromoneTextureCoords[kTechId.ExpandingMarker] = { kOrderPixelWidth * 4, kOrderPixelWidth, kOrderPixelWidth * 5, kOrderPixelHeight * 2}

class 'GUICommanderPheromoneDisplay' (GUIScript)

function GUICommanderPheromoneDisplay:Initialize()
    self.pheromoneUIs = table.array(10)
end

function GUICommanderPheromoneDisplay:Uninitialize()

    for p = 1, #self.pheromoneUIs do
        GUI.DestroyItem(self.pheromoneUIs[p])
    end
    self.pheromoneUIs = table.array(10)
    
end

local function FreeAllPheromoneUIs(self)

    for p = 1, #self.pheromoneUIs do
        self.pheromoneUIs[p]:SetIsVisible(false)
    end
    
end

local function GetFreePheromoneUI(self)

    for p = 1, #self.pheromoneUIs do
    
        local currentUI = self.pheromoneUIs[p]
        if not currentUI:GetIsVisible() then
        
            currentUI:SetIsVisible(true)
            return currentUI
            
        end
        
    end
    
    local newUI = GUIManager:CreateGraphicItem()
    newUI:SetAnchor(GUIItem.Left, GUIItem.Top)
    newUI:SetColor(Color(1, 1, 1, 1))
    newUI:SetBlendTechnique(GUIItem.Add)
    newUI:SetTexture(kTextureName)
    table.insert(self.pheromoneUIs, newUI)
    return newUI
    
end

local kPheromoneColor = Color(kIconColors[kAlienTeamType])

function GUICommanderPheromoneDisplay:Update(deltaTime)

    FreeAllPheromoneUIs(self)
    
    local pheromones = CommanderUI_GetPheromones()
    for p = 1, #pheromones do
    
        local currentPheromone = pheromones[p]
        local ui = GetFreePheromoneUI(self)

        local timeSinceCreate = Shared.GetTime() - currentPheromone:GetCreateTime()
        local animationScalar = Clamp(timeSinceCreate / kGrowTime, 0, 1)
        
        // Animate size
        local startSize = Vector(kOrderPixelWidth, kOrderPixelHeight, 0) * (kStartScale)    
        local desiredSize = Vector(kOrderPixelWidth, kOrderPixelHeight, 0) * kBaseScale
        local size = startSize + (desiredSize - startSize) * math.sin(animationScalar * math.pi / 2)
        ui:SetSize(size)
        
        ui:SetPosition(Client.WorldToScreen(currentPheromone:GetOrigin()) - size / 2)
        ui:SetColor(Color(kPheromoneColor.r, kPheromoneColor.g, kPheromoneColor.b, 0.3 + 0.2 * timeSinceCreate ))
        ui:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(currentPheromone:GetType())))
        
    end
    
end