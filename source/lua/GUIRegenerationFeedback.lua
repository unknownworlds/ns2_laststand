// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIRegenerationFeedback.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIRegenerationFeedback' (GUIAnimatedScript)

GUIRegenerationFeedback.kBuyMenuTexture = "ui/alien_buymenu.dds"

GUIRegenerationFeedback.kCornerTextureCoordinates = { TopLeft = { 605, 1, 765, 145 },  BottomLeft = { 605, 145, 765, 290 }, TopRight = { 765, 1, 910, 145 }, BottomRight = { 765, 145, 910, 290 } }
GUIRegenerationFeedback.kCornerWidths = { }
GUIRegenerationFeedback.kCornerHeights = { }
for location, texCoords in pairs(GUIRegenerationFeedback.kCornerTextureCoordinates) do
    GUIRegenerationFeedback.kCornerWidths[location] = GUIScale(texCoords[3] - texCoords[1]) * 2
    GUIRegenerationFeedback.kCornerHeights[location] = GUIScale(texCoords[4] - texCoords[2]) * 2
end

GUIRegenerationFeedback.kRegenVeinColor = Color(0.2, 0.6, 0, 0)
GUIRegenerationFeedback.kRegenPulseDuration = 0.5

function GUIRegenerationFeedback:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.corners = { }
    
    local bottomLeftCorner = self:CreateAnimatedGraphicItem()
    bottomLeftCorner:SetIsScaling(false)
    bottomLeftCorner:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    bottomLeftCorner:SetPosition(Vector(0, -GUIRegenerationFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetSize(Vector(GUIRegenerationFeedback.kCornerWidths.BottomLeft, GUIRegenerationFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetTexture(GUIRegenerationFeedback.kBuyMenuTexture)
    bottomLeftCorner:SetTexturePixelCoordinates(unpack(GUIRegenerationFeedback.kCornerTextureCoordinates.BottomLeft))
    bottomLeftCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomLeftCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomLeftCorner:SetColor(GUIRegenerationFeedback.kRegenVeinColor)
    self.corners.BottomLeft = bottomLeftCorner

    
    local bottomRightCorner = self:CreateAnimatedGraphicItem()
    bottomRightCorner:SetIsScaling(false)
    bottomRightCorner:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    bottomRightCorner:SetPosition(Vector(-GUIRegenerationFeedback.kCornerWidths.BottomRight, -GUIRegenerationFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetSize(Vector(GUIRegenerationFeedback.kCornerWidths.BottomRight, GUIRegenerationFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetTexture(GUIRegenerationFeedback.kBuyMenuTexture)
    bottomRightCorner:SetTexturePixelCoordinates(unpack(GUIRegenerationFeedback.kCornerTextureCoordinates.BottomRight))
    bottomRightCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomRightCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomRightCorner:SetColor(GUIRegenerationFeedback.kRegenVeinColor)
    self.corners.BottomRight = bottomRightCorner


end

function GUIRegenerationFeedback:GetIsAnimating()
    return self.corners.BottomLeft:GetIsAnimating()
end

function GUIRegenerationFeedback:TriggerRegenEffect()  

    local PulseOut = function(script, item)
        item:FadeOut(GUIRegenerationFeedback.kRegenPulseDuration,"ANIM_REGEN_VEIN", AnimateSin)
    end

    self.corners.BottomLeft:FadeIn(GUIRegenerationFeedback.kRegenPulseDuration, "ANIM_REGEN_VEIN", AnimateSin, PulseOut)
    self.corners.BottomRight:FadeIn(GUIRegenerationFeedback.kRegenPulseDuration, "ANIM_REGEN_VEIN", AnimateSin, PulseOut)

end
