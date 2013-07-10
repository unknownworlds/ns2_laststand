// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIBabblerMoveIndicator.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")
Script.Load("lua/Babbler.lua")

class 'GUIBabblerMoveIndicator' (GUIScript)

local kIconSize = GUIScale(Vector(128, 128, 0))
local kIconAnimationVector = GUIScale(Vector(0, 16, 0))
local kIconTexture = "ui/babbler_move_icons.dds"

local kIconOffset = GUIScale(Vector(0, 196, 0))

local kMoveTypeTexCoords = {

    [kBabblerMoveType.Move] = { 0, 0, 128, 128 },
    [kBabblerMoveType.Attack] = { 128, 0, 256, 128 },
    [kBabblerMoveType.Cling] = { 256, 0, 384, 128 },

}

local function GetBabblerMoveType()

    local moveType = kBabblerMoveType.Move
    local player = Client.GetLocalPlayer()
    if player and player:GetActiveWeapon() and player:GetActiveWeapon():isa("BabblerAbility") then
        moveType = player:GetActiveWeapon():GetBabblerMoveType()
    end
    
    return moveType

end

function GUIBabblerMoveIndicator:Initialize()

    self.icon = GetGUIManager():CreateGraphicItem()
    self.icon:SetSize(kIconSize)
    self.icon:SetTexture(kIconTexture)
    self.icon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    self:Update(0)

end


function GUIBabblerMoveIndicator:Uninitialize()

    if self.icon then
        GUI.DestroyItem(self.icon)
        self.icon = nil
    end

end

function GUIBabblerMoveIndicator:Update(deltaTime)
    
    local currentMoveType = GetBabblerMoveType()
    local texCoords = kMoveTypeTexCoords[currentMoveType]
    
    if texCoords then
    
        self.icon:SetTexturePixelCoordinates(unpack(texCoords))
        self.icon:SetIsVisible(true)
        
        local animation = math.sin(Shared.GetTime() * 2)
        local iconPos = -kIconSize *.5 + kIconAnimationVector * animation + kIconOffset
        self.icon:SetPosition(iconPos)
        
    else
        self.icon:SetIsVisible(false)
    end    
    
end

