
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPing.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Shows a commander triggered ping.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIPing' (GUIScript)

local kMaxSize = GUIScale(Vector(400, 400, 0))
local kMinSize = GUIScale(Vector(128, 128, 0))
local kMaxPingDistance = 30

local kBorderColor = Color(1, 0, 0, 0)
local kMarkColor = Color(1, 1, 1, 1)

function GUIPing:Initialize()

    self.pingItem = GUICreateCommanderPing()
    self.screenDiagonalLength = math.sqrt(Client.GetScreenHeight() / 2) ^ 2 + (Client.GetScreenWidth() / 2)
    
end

function GUIPing:Uninitialize()

    if self.pingItem then
    
        GUI.DestroyItem(self.pingItem.Frame)
        self.pingItem = nil
        
    end
    
end

function GUIPing:OnResolutionChanged()

    self.screenDiagonalLength = math.sqrt(Client.GetScreenHeight() / 2) ^ 2 + (Client.GetScreenWidth() / 2)
    kMaxSize = GUIScale(Vector(400, 400, 0))
    kMinSize = GUIScale(Vector(128, 128, 0))
    
end

function GUIPing:Update(deltaTime)

    local timeSincePing, position, distance, locationName = PlayerUI_GetCommanderPingInfo(false)
    
    local distanceFraction = 1 - Clamp(distance / kMaxPingDistance, 0, 1)
    local pingSize = kMinSize + distanceFraction * (kMaxSize - kMinSize)
    
    GUIAnimateCommanderPing(self.pingItem.Mark, self.pingItem.Border, self.pingItem.Location, pingSize, timeSincePing, kBorderColor, kMarkColor)
    
    // Fade out when closer to screen center.
    local distanceToScreenCenter = math.abs((position - Vector(Client.GetScreenWidth() * 0.5, Client.GetScreenHeight() * 0.5, 0)):GetLength())
    self.pingItem.Frame:SetColor(Color(1, 1, 1, (distanceToScreenCenter / self.screenDiagonalLength) + 0.5))
    
    self.pingItem.Frame:SetPosition(position)
    
    if locationName == nil then
        locationName = ""
    end
    
    self.pingItem.Location:SetText(locationName)
    
end