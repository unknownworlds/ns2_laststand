// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIObjectiveDisplay.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Shows enemy command structures
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIObjectiveDisplay' (GUIScript)

GUIObjectiveDisplay.kVisionExtents = GUIScale( Vector(100, 100, 0) )
GUIObjectiveDisplay.kVisionMinExtents = GUIScale( Vector(32, 32, 0) )
GUIObjectiveDisplay.kMaxDistance = 100
GUIObjectiveDisplay.kMinAlpha = 0.15 // 0.1
GUIObjectiveDisplay.kMaxAlpha = .5 // 0.1

local kTextures = { [kMarineTeamType] = "ui/objectives_marine.dds", [kAlienTeamType] = "ui/objectives_alien.dds" }

local function GetTextureForTeamType(teamType)
    return kTextures[teamType] or ""
end

local kPixelCoords = nil
local function GetPixelCoordsForType(type)

    if not kPixelCoords then
    
        kPixelCoords = {}
        kPixelCoords[kTechId.TechPoint] = { 0, 0, 256, 256 }
        kPixelCoords[kTechId.ResourcePoint] = { 256, 0, 512, 256 }
    
    end

    return kPixelCoords[type] or { 0, 0, 0, 0 }

end

local function CreateVisionElement(self)

    local guiItem = GetGUIManager():CreateGraphicItem()
    guiItem:SetSize(GUIObjectiveDisplay.kVisionExtents)
    guiItem:SetBlendTechnique(GUIItem.Add)
    return guiItem

end

function GUIObjectiveDisplay:Initialize()

    self.activeVisions = { }
    self.screenDiagonalLength = math.sqrt(Client.GetScreenHeight()/2) ^ 2 + (Client.GetScreenWidth()/2)
    
end

function GUIObjectiveDisplay:Uninitialize()
    
    for i, blip in ipairs(self.activeVisions) do
        GUI.DestroyItem(blip)
    end
    self.activeVisions = { }
    
end

function GUIObjectiveDisplay:OnResolutionChanged()

    self.screenDiagonalLength = math.sqrt(Client.GetScreenHeight()/2) ^ 2 + (Client.GetScreenWidth()/2)
    GUIObjectiveDisplay.kVisionExtents = GUIScale( Vector(64, 64, 0) )
    
end

function GUIObjectiveDisplay:Update(deltaTime)

    PROFILE("GUIObjectiveDisplay:Update")

    local unitVisions = PlayerUI_GetObjectives()
    local teamType = PlayerUI_GetTeamType()
    
    local numActiveVisions = #self.activeVisions
    local numCurrentVisions = #unitVisions
    
    local stencilUpdated = numActiveVisions ~= numCurrentVisions
    
    if numCurrentVisions > numActiveVisions then
    
        for i = 1, numCurrentVisions - numActiveVisions do
            table.insert(self.activeVisions, CreateVisionElement(self))
        end
    
    elseif numActiveVisions > numCurrentVisions then
    
        for i = 1, numActiveVisions - numCurrentVisions do
        
            GUI.DestroyItem(self.activeVisions[#self.activeVisions])
            table.remove(self.activeVisions, #self.activeVisions)
            
        end
    
    end

    local size = nil
    
    for index, currentVision in ipairs(unitVisions) do   
    
        local visionElement = self.activeVisions[index]
        
        local screenPosFraction = (math.abs( (currentVision.Position - Vector(Client.GetScreenWidth() * .5, Client.GetScreenHeight() * .5, 0)):GetLength() ) / (self.screenDiagonalLength * 0.5))
        
        local color = Color(1, 0, 0, 1)        
        color.a = GUIObjectiveDisplay.kMinAlpha + (GUIObjectiveDisplay.kMaxAlpha - GUIObjectiveDisplay.kMinAlpha) * screenPosFraction

        // Don't draw existing objective markers if we turn off hints        
        if Client.GetOptionBoolean( "showHints", true ) == false then
            color.a = 0
        end
        
        local size = (GUIObjectiveDisplay.kVisionExtents - GUIObjectiveDisplay.kVisionMinExtents) * currentVision.DistanceFraction + GUIObjectiveDisplay.kVisionMinExtents

        visionElement:SetPosition(currentVision.Position - size *.5)        
        visionElement:SetSize(size)
        visionElement:SetColor(color)
        visionElement:SetTexture(GetTextureForTeamType(teamType))
        visionElement:SetTexturePixelCoordinates(unpack(GetPixelCoordsForType(currentVision.TechId)))
        
    end

end