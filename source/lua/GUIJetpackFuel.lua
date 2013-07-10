// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIJetpackFuel.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages the marine buy/purchase menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIJetpackFuel' (GUIScript)

GUIJetpackFuel.kJetpackFuelTexture = "ui/marine_jetpackfuel.dds"


GUIJetpackFuel.kFont = "fonts/MicrogrammaDMedExt_medium.fnt"

GUIJetpackFuel.kBackgroundWidth = GUIScale(32)
GUIJetpackFuel.kBackgroundHeight = GUIScale(144)
GUIJetpackFuel.kBackgroundOffsetX = 20
GUIJetpackFuel.kBackgroundOffsetY = GUIScale(-240)

GUIJetpackFuel.kBarWidth = GUIScale(20)
GUIJetpackFuel.kBarHeight = GUIScale(123)

GUIJetpackFuel.kBgCoords = {0, 0, 32, 144}

GUIJetpackFuel.kBarCoords = {39, 10, 39 + 18, 10 + 123}

GUIJetpackFuel.kFuelBlueIntensity = .8

GUIJetpackFuel.kBackgroundColor = Color(0, 0, 0, 0.5)
GUIJetpackFuel.kFuelBarOpacity = 0.8

function GUIJetpackFuel:GetBackgroundOffsetX()
    return GUIJetpackFuel.kBackgroundOffsetX
end

function GUIJetpackFuel:Initialize()    
    
    // jetpack fuel display background
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(GUIJetpackFuel.kBackgroundWidth, GUIJetpackFuel.kBackgroundHeight, 0) )
    self.background:SetPosition(Vector(GUIJetpackFuel.kBackgroundWidth / 2 + self:GetBackgroundOffsetX(), -GUIJetpackFuel.kBackgroundHeight / 2 + GUIJetpackFuel.kBackgroundOffsetY, 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom) 
    self.background:SetLayer(kGUILayerPlayerHUD)
    self.background:SetTexture(GUIJetpackFuel.kJetpackFuelTexture)
    self.background:SetTexturePixelCoordinates(unpack(GUIJetpackFuel.kBgCoords))
    
    // fuel bar
    
    self.fuelBar = GUIManager:CreateGraphicItem()
    self.fuelBar:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.fuelBar:SetPosition( Vector(-GUIJetpackFuel.kBarWidth / 2, -10, 0))
    self.fuelBar:SetTexture(GUIJetpackFuel.kJetpackFuelTexture)
    self.fuelBar:SetTexturePixelCoordinates(unpack(GUIJetpackFuel.kBarCoords))
 
    self.background:AddChild(self.fuelBar)
    self:Update(0)

end

function GUIJetpackFuel:SetFuel(fraction)

    self.fuelBar:SetSize( Vector(GUIJetpackFuel.kBarWidth, -GUIJetpackFuel.kBarHeight * fraction, 0) )
    self.fuelBar:SetColor( Color(1 - fraction * GUIJetpackFuel.kFuelBlueIntensity, 
                                 GUIJetpackFuel.kFuelBlueIntensity * fraction * 0.8 , 
                                 GUIJetpackFuel.kFuelBlueIntensity * fraction ,
                                 GUIJetpackFuel.kFuelBarOpacity) )

end


function GUIJetpackFuel:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    
    if player and player.GetFuel then
        self:SetFuel(player:GetFuel())
    end

end


function GUIJetpackFuel:Uninitialize()

    GUI.DestroyItem(self.fuelBar)
    GUI.DestroyItem(self.background)

end
