
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimapButtons.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Buttons for minimap action (commander ping).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIMinimapButtons' (GUIScript)

local kMinimapButtonTexture = "ui/minimap_buttons.dds"
local kPingIconTexture = "ui/ping_icon.dds"
local kPingIconTextureAlien = "ui/ping_icon_alien.dds"

local kBackgroundSize = GUIScale(Vector(40, 160, 0))
local kBackgroundPos = GUIScale(Vector(16, -6, 0))
local kBackgroundTexCoords = { 0, 0, 128, 386 }

local kButtonSize = GUIScale(Vector(60, 50, 0))
local kPingButtonTexCoords = { 128, 0, 128 + 80, 80 }
local kPingButtonActiveTexCoords = { 128, 80, 128 + 80, 160 }

function GUIMinimapButtons:Initialize()

    self.pingButtonActive = false
    
    local texture = kPingIconTexture
    
    if PlayerUI_GetTeamType() == kAlienTeamType then
        texture = kPingIconTextureAlien
    end
    
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetPosition(kBackgroundPos)
    self.background:SetSize(kBackgroundSize)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.background:SetTexture(kMinimapButtonTexture)
    self.background:SetColor(Color(1,1,1,0))
    self.background:SetTexturePixelCoordinates(unpack(kBackgroundTexCoords))
  
    self.pingButton = GetGUIManager():CreateGraphicItem()
    self.pingButton:SetSize(kButtonSize)
    self.pingButton:SetTexture(texture)
    
    self.background:AddChild(self.pingButton)
    
end

function GUIMinimapButtons:GetBackground()
    return self.background
end

function GUIMinimapButtons:Uninitialize()

    if self.background then
    
        GUI.DestroyItem(self.background)
        self.background = nil
        
    end
    
end

function GUIMinimapButtons:Update(deltaTime)

    local alpha = GetCommanderPingEnabled() and 1 or 0.7
    
    local useColor = kNeutralTeamColor
    
    if PlayerUI_IsOnAlienTeam() then
        useColor = Color(kAlienTeamColorFloat)
    elseif PlayerUI_IsOnMarineTeam() then
        useColor = Color(kMarineTeamColorFloat)
    end
    
    useColor.a = alpha
    
    self.pingButton:SetColor(useColor)
    
end

function GUIMinimapButtons:ContainsPoint(pointX, pointY)
    return GUIItemContainsPoint(self.background, pointX, pointY)
end

function GUIMinimapButtons:SendKeyEvent(key, down)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and CommanderUI_GetUIClickable() then
    
        if GUIItemContainsPoint(self.pingButton, mouseX, mouseY) then
        
            SetCommanderPingEnabled(true)
            return true
            
        end
        
    end
    
end