// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_Location.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Spectator: Displays Location in upper left corner
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_Location' (GUIScript)

local kBackgroundTexture = "ui/location.dds"
local kFontName = "fonts/AgencyFB_large.fnt"
local kFontScale = GUIScale(Vector(1, 1, 0))

function GUIInsight_Location:Initialize()

    local ratio = 3.65789474 -- preserve aspect ratio of background image
    local size = GUIScale(Vector(100*ratio,100,0))
    self.locationBackground = GUIManager:CreateGraphicItem()
    self.locationBackground:SetSize(size)
    self.locationBackground:SetTexture(kBackgroundTexture)
    self.locationBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationBackground:SetTexturePixelCoordinates(unpack({0,0,556,152}))
    self.locationBackground:SetPosition(GUIScale(Vector(0, -10, 0)))

    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetFontName(kFontName)
    self.locationText:SetScale(kFontScale)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Center)
    self.locationText:SetPosition(GUIScale(Vector(10, -3, 0)))
    self.locationText:SetColor(Color(1, 1, 1, 1))
    self.locationText:SetText("")
    self.locationText:SetLayer(kGUILayerLocationText)
    self.locationBackground:AddChild(self.locationText)

    self.locationTextBack = GUIManager:CreateTextItem()
    self.locationTextBack:SetFontName(kFontName)
    self.locationTextBack:SetScale(kFontScale)
    self.locationTextBack:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.locationTextBack:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationTextBack:SetTextAlignmentY(GUIItem.Align_Center)
    self.locationTextBack:SetPosition(GUIScale(Vector(13, 0, 0)))
    self.locationTextBack:SetColor(Color(0, 0, 0, 0.9))
    self.locationTextBack:SetText("")
    self.locationTextBack:SetLayer(kGUILayerLocationText - 1)
    self.locationBackground:AddChild(self.locationTextBack)
        
    self.locationVisible = true
    
end

function GUIInsight_Location:Uninitialize()

    if self.locationText then
        GUI.DestroyItem(self.locationBackground)
        self.locationText = nil
    end
    
end

function GUIInsight_Location:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    
    self:Initialize()

end

function GUIInsight_Location:SetIsVisible(bool)

    self.locationVisible = bool
    self.locationBackground:SetIsVisible(bool)

end

function GUIInsight_Location:Update(deltaTime)
    
    if self.locationVisible then
    
        local player = Client.GetLocalPlayer()
        if player == nil then
            return
        end
        
        -- Location Text
        
        local nearestLocation = GetLocationForPoint(player:GetOrigin())
        if nearestLocation == nil then
            nearestLocationName = "Unknown"
        elseif nearestLocation.name == "Ball Court" then
            nearestLocationName = "Ball-in Court"
        else
            nearestLocationName = nearestLocation.name
        end
        self.locationText:SetText(nearestLocationName)
        self.locationTextBack:SetText(nearestLocationName)
        
    end
    
end