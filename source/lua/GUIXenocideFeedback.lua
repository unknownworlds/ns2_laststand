// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIXenocideFeedback.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIXenocideFeedback' (GUIAnimatedScript)

GUIXenocideFeedback.kBuyMenuTexture = "ui/alien_buymenu.dds"

GUIXenocideFeedback.kCornerTextureCoordinates = { TopLeft = { 605, 1, 765, 145 },  BottomLeft = { 605, 145, 765, 290 }, TopRight = { 765, 1, 910, 145 }, BottomRight = { 765, 145, 910, 290 } }
GUIXenocideFeedback.kCornerWidths = { }
GUIXenocideFeedback.kCornerHeights = { }
for location, texCoords in pairs(GUIXenocideFeedback.kCornerTextureCoordinates) do
    GUIXenocideFeedback.kCornerWidths[location] = GUIScale(texCoords[3] - texCoords[1]) * 2
    GUIXenocideFeedback.kCornerHeights[location] = GUIScale(texCoords[4] - texCoords[2]) * 2
end

GUIXenocideFeedback.kFlashColorBegin = Color(1, 1, 0.5, 0)
GUIXenocideFeedback.kFlashColorEnd = Color(1, 0.7, 0.2, 0.7)

function GUIXenocideFeedback:Initialize()

    GUIAnimatedScript.Initialize(self)

    self:_InitializeCorners()
    
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetIsScaling(false)
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetColor(GUIXenocideFeedback.kFlashColorBegin)
    self.background:SetBlendTechnique(GUIItem.Add)

end

function GUIXenocideFeedback:_InitializeCorners()

    self.corners = { }
    
    local topLeftCorner = self:CreateAnimatedGraphicItem()
    topLeftCorner:SetIsScaling(false)
    topLeftCorner:SetAnchor(GUIItem.Left, GUIItem.Top)
    topLeftCorner:SetSize(Vector(GUIXenocideFeedback.kCornerWidths.TopLeft, GUIXenocideFeedback.kCornerHeights.TopLeft, 0))
    topLeftCorner:SetTexture(GUIXenocideFeedback.kBuyMenuTexture)
    topLeftCorner:SetTexturePixelCoordinates(unpack(GUIXenocideFeedback.kCornerTextureCoordinates.TopLeft))
    topLeftCorner:SetLayer(kGUILayerPlayerHUDBackground)
    topLeftCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    topLeftCorner:SetColor(Color(1,1,1,0))
    self.corners.TopLeft = topLeftCorner
    
    local bottomLeftCorner = self:CreateAnimatedGraphicItem()
    bottomLeftCorner:SetIsScaling(false)
    bottomLeftCorner:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    bottomLeftCorner:SetPosition(Vector(0, -GUIXenocideFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetSize(Vector(GUIXenocideFeedback.kCornerWidths.BottomLeft, GUIXenocideFeedback.kCornerHeights.BottomLeft, 0))
    bottomLeftCorner:SetTexture(GUIXenocideFeedback.kBuyMenuTexture)
    bottomLeftCorner:SetTexturePixelCoordinates(unpack(GUIXenocideFeedback.kCornerTextureCoordinates.BottomLeft))
    bottomLeftCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomLeftCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomLeftCorner:SetColor(Color(1,1,1,0))
    self.corners.BottomLeft = bottomLeftCorner
    
    local topRightCorner = self:CreateAnimatedGraphicItem()
    topRightCorner:SetIsScaling(false)
    topRightCorner:SetAnchor(GUIItem.Right, GUIItem.Top)
    topRightCorner:SetPosition(Vector(-GUIXenocideFeedback.kCornerWidths.TopRight, 0, 0))
    topRightCorner:SetSize(Vector(GUIXenocideFeedback.kCornerWidths.TopRight, GUIXenocideFeedback.kCornerHeights.TopRight, 0))
    topRightCorner:SetTexture(GUIXenocideFeedback.kBuyMenuTexture)
    topRightCorner:SetTexturePixelCoordinates(unpack(GUIXenocideFeedback.kCornerTextureCoordinates.TopRight))
    topRightCorner:SetLayer(kGUILayerPlayerHUDBackground)
    topRightCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    topRightCorner:SetColor(Color(1,1,1,0))
    self.corners.TopRight = topRightCorner
    
    local bottomRightCorner = self:CreateAnimatedGraphicItem()
    bottomRightCorner:SetIsScaling(false)
    bottomRightCorner:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    bottomRightCorner:SetPosition(Vector(-GUIXenocideFeedback.kCornerWidths.BottomRight, -GUIXenocideFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetSize(Vector(GUIXenocideFeedback.kCornerWidths.BottomRight, GUIXenocideFeedback.kCornerHeights.BottomRight, 0))
    bottomRightCorner:SetTexture(GUIXenocideFeedback.kBuyMenuTexture)
    bottomRightCorner:SetTexturePixelCoordinates(unpack(GUIXenocideFeedback.kCornerTextureCoordinates.BottomRight))
    bottomRightCorner:SetLayer(kGUILayerPlayerHUDBackground)
    bottomRightCorner:SetShader("shaders/GUIWavyNoMask.surface_shader")
    bottomRightCorner:SetColor(Color(1,1,1,0))
    self.corners.BottomRight = bottomRightCorner


end

function GUIXenocideFeedback:TriggerFlash(duration)

    self.background:SetColor(GUIXenocideFeedback.kFlashColorEnd, duration, "XENO_FLASH_ANIM", AnimateLinear, function(script, item) item:FadeOut(0.4) end )

    local veinDuration = duration * 0.7
    self.corners.TopLeft:FadeIn(veinDuration)
    self.corners.BottomLeft:FadeIn(veinDuration)
    self.corners.TopRight:FadeIn(veinDuration)
    self.corners.BottomRight:FadeIn(veinDuration)

end
