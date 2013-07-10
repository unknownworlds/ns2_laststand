// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPoisonedFeedback.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIPoisonedFeedback' (GUIAnimatedScript)

GUIPoisonedFeedback.kBuyMenuTexture = "ui/alien_buymenu.dds"

GUIPoisonedFeedback.kCornerTextureCoordinates = { TopLeft = { 605, 1, 765, 145 },  BottomLeft = { 605, 145, 765, 290 }, TopRight = { 765, 1, 910, 145 }, BottomRight = { 765, 145, 910, 290 } }
GUIPoisonedFeedback.kCornerWidths = { }
GUIPoisonedFeedback.kCornerHeights = { }
for location, texCoords in pairs(GUIPoisonedFeedback.kCornerTextureCoordinates) do
    GUIPoisonedFeedback.kCornerWidths[location] = GUIScale(texCoords[3] - texCoords[1]) * 2
    GUIPoisonedFeedback.kCornerHeights[location] = GUIScale(texCoords[4] - texCoords[2]) * 2
end

GUIPoisonedFeedback.kRegenVeinColor = Color(0.2, 0.6, 0, 0)
GUIPoisonedFeedback.kRegenPulseDuration = 1

function GUIPoisonedFeedback:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.corners = { }
    
    local bottomLeftCorner = self:CreateAnimatedGraphicItem()
    bottomLeftCorner:SetIsScaling(false)
    bottomLeftCorner:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    bottomLeftCorner:SetPosition(Vector(0, -GUIPoisonedFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetSize(Vector(GUIPoisonedFeedback.kCornerWidths.BottomLeft, GUIPoisonedFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetTexture(GUIPoisonedFeedback.kBuyMenuTexture)
    bottomLeftCorner:SetTexturePixelCoordinates(unpack(GUIPoisonedFeedback.kCornerTextureCoordinates.BottomLeft))
    bottomLeftCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomLeftCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomLeftCorner:SetColor(GUIPoisonedFeedback.kRegenVeinColor)
    self.corners.BottomLeft = bottomLeftCorner

    
    local bottomRightCorner = self:CreateAnimatedGraphicItem()
    bottomRightCorner:SetIsScaling(false)
    bottomRightCorner:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    bottomRightCorner:SetPosition(Vector(-GUIPoisonedFeedback.kCornerWidths.BottomRight, -GUIPoisonedFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetSize(Vector(GUIPoisonedFeedback.kCornerWidths.BottomRight, GUIPoisonedFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetTexture(GUIPoisonedFeedback.kBuyMenuTexture)
    bottomRightCorner:SetTexturePixelCoordinates(unpack(GUIPoisonedFeedback.kCornerTextureCoordinates.BottomRight))
    bottomRightCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomRightCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomRightCorner:SetColor(GUIPoisonedFeedback.kRegenVeinColor)
    self.corners.BottomRight = bottomRightCorner


end

function GUIPoisonedFeedback:GetIsAnimating()
    return self.corners.BottomLeft:GetIsAnimating()
end

function GUIPoisonedFeedback:TriggerPoisonEffect()

    local PulseOut = function(script, item)
        item:FadeOut(GUIPoisonedFeedback.kRegenPulseDuration,"ANIM_REGEN_VEIN", AnimateSin)
    end

    self.corners.BottomLeft:FadeIn(GUIPoisonedFeedback.kRegenPulseDuration, "ANIM_REGEN_VEIN", AnimateSin, PulseOut)
    self.corners.BottomRight:FadeIn(GUIPoisonedFeedback.kRegenPulseDuration, "ANIM_REGEN_VEIN", AnimateSin, PulseOut)

end
