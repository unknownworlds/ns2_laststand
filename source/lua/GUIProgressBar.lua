
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIProgressBar.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Shows a simple progress bar and text.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIProgressBar' (GUIScript)

GUIProgressBar.kFontName = "fonts/AgencyFB_medium.fnt"
GUIProgressBar.kFontScale = GUIScale(Vector(1,1,0)) * 0.7

local kScale = 1.2

GUIProgressBar.kBgSize = GUIScale(Vector(230, 50, 0)) * kScale
GUIProgressBar.kSize = GUIProgressBar.kBgSize

GUIProgressBar.kBgPosition = Vector(GUIProgressBar.kBgSize.x * -.5, GUIScale(-150) * kScale, 0)

GUIProgressBar.kTextYOffset = GUIScale(6) * kScale

GUIProgressBar.kBarTexCoords = { 256, 0, 256 + 512, 64 }

local kBackgroundNoiseTexture = PrecacheAsset("ui/alien_commander_bg_smoke.dds")
local kSmokeyBackgroundSize = GUIScale(Vector(400, 200, 0)) * kScale
local kSmokeyBackgroundPos = -kSmokeyBackgroundSize * .5 + GUIScale(Vector(0, -100, 0)) * kScale

local kAlienColor = Color(1, 0.792, 0.227)
local kMarineColor = Color(0.725, 0.921, 0.949, 1)

local kBorderMaskPixelCoords = { 256, 384, 256 + 512, 384 + 512 }
local kBorderMaskCircleRadius = GUIScale(140)
local kRotationDuration = 4

local kProgressBarAlienShine = PrecacheAsset("ui/progress_bar_alien_shine.dds")
local kShineSize = GUIScale(Vector(400, 150, 0)) 
local kShinePos = Vector(-kShineSize.x * .5, -GUIScale(105), 0)

local kWhiteColor = Color(1, 1, 1, 1)

local kTextures =
{
    [kMarineTeamType] = PrecacheAsset("ui/progress_bar_marine.dds"),
    [kAlienTeamType] = PrecacheAsset("ui/progress_bar_alien.dds")
}

local kProgressBarMarineMask = PrecacheAsset("ui/progress_bar_marine_mask.dds")

local kUnitStatusNeutral = PrecacheAsset("ui/unitstatus_neutral.dds")

local kBackgroundPixelCoords = { 0, 0, 230, 50 }
local kForegroundPixelCoords = { 0, 50, 230, 100 }

kFadeOutDelay = 0

function GUIProgressBar:Initialize()

    self.timeLastProgress = 0
    
    self.teamType = PlayerUI_GetTeamType()
    
    local texture = kTextures[self.teamType]
    
    if self.teamType == kAlienTeamType then
        self:InitSmokeBg()
    end

    self.progressBarBg = GUIManager:CreateGraphicItem()
    self.progressBarBg:SetSize(GUIProgressBar.kBgSize)
    self.progressBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.progressBarBg:SetPosition(GUIProgressBar.kBgPosition)
    self.progressBarBg:SetTexture(texture)
    self.progressBarBg:SetTexturePixelCoordinates(unpack(kBackgroundPixelCoords))
    self.progressBarBg:SetLayer(kGUILayerPlayerHUD)
    self.progressBarBg:SetColor(Color(1,1,1,0))
    
    if self.teamType == kMarineTeamType then
        self:InitCircleMask()
    end
    
    self.progressBar = GUIManager:CreateGraphicItem()
    self.progressBar:SetSize(GUIProgressBar.kSize)
    self.progressBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.progressBar:SetTexture(texture)
    self.progressBar:SetTexturePixelCoordinates(unpack(kForegroundPixelCoords))
    self.progressBar:SetInheritsParentAlpha(true)
    self.progressBarBg:AddChild(self.progressBar)
    
    self.objectiveTextShadow = GUIManager:CreateTextItem()
    self.objectiveTextShadow:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.objectiveTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
    self.objectiveTextShadow:SetTextAlignmentY(GUIItem.Align_Min)
    self.objectiveTextShadow:SetPosition(Vector(1, GUIProgressBar.kTextYOffset + 1, 0))
    self.objectiveTextShadow:SetInheritsParentAlpha(true)
    self.objectiveTextShadow:SetFontName(GUIProgressBar.kFontName)
    self.objectiveTextShadow:SetScale(GUIProgressBar.kFontScale)
    self.objectiveTextShadow:SetColor(Color(0, 0, 0, 1))
    self.progressBarBg:AddChild(self.objectiveTextShadow)
    
    self.objectiveText = GUIManager:CreateTextItem()
    self.objectiveText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.objectiveText:SetTextAlignmentX(GUIItem.Align_Center)
    self.objectiveText:SetTextAlignmentY(GUIItem.Align_Min)
    self.objectiveText:SetPosition(Vector(0, GUIProgressBar.kTextYOffset, 0))
    self.objectiveText:SetInheritsParentAlpha(true)
    self.objectiveText:SetFontName(GUIProgressBar.kFontName)
    self.objectiveText:SetScale(GUIProgressBar.kFontScale)
    self.objectiveText:SetColor(Color(1,1,1,1))
    self.progressBarBg:AddChild(self.objectiveText)

end

function GUIProgressBar:Uninitialize()

    if self.progressBarBg then
        GUI.DestroyItem(self.progressBarBg)
        self.progressBarBg = nil
    end    

    if self.smokeyBackground then
        GUI.DestroyItem(self.smokeyBackground)
        self.smokeyBackground = nil
    end
    
end

function GUIProgressBar:InitSmokeBg()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(kSmokeyBackgroundPos)
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetTexture("ui/alien_logout_smkmask.dds")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 0.6)
    self.smokeyBackground:SetFloatParameter("correctionY", 0.4)
    self.smokeyBackground:SetLayer(kGUILayerPlayerHUDBackground)
    
    self.smokeyBackground:SetInheritsParentAlpha(true)
    
    self.shine = GUIManager:CreateGraphicItem()
    self.shine:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.shine:SetSize(kShineSize)
    self.shine:SetPosition(kShinePos)
    self.shine:SetTexture(kProgressBarAlienShine)
    self.shine:SetInheritsParentAlpha(true)
    self.shine:SetBlendTechnique(GUIItem.Add)
    
    self.smokeyBackground:AddChild(self.shine)
    
end

function GUIProgressBar:InitCircleMask()

    self.borderMask = GUIManager:CreateGraphicItem()
    self.borderMask:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.borderMask:SetSize(GUIProgressBar.kBgSize)
    self.borderMask:SetTexture(kProgressBarMarineMask)
    self.borderMask:SetTexturePixelCoordinates(unpack(kBackgroundPixelCoords))
    self.borderMask:SetIsStencil(true)
    
    self.progressBarBg:AddChild(self.borderMask)
    
    self.circle = GUIManager:CreateGraphicItem()
    self.circle:SetTexture(kUnitStatusNeutral)
    self.circle:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.circle:SetBlendTechnique(GUIItem.Add)
    self.circle:SetTexturePixelCoordinates(unpack(kBorderMaskPixelCoords))
    self.circle:SetSize(Vector(kBorderMaskCircleRadius * 2, kBorderMaskCircleRadius * 2, 0))
    self.circle:SetPosition(Vector(-kBorderMaskCircleRadius, -kBorderMaskCircleRadius, 0))
    self.circle:SetStencilFunc(GUIItem.NotEqual)
    
    self.borderMask:AddChild(self.circle)
    
    self.circleRotation = Vector(0,0,0)

end

function GUIProgressBar:Update(deltaTime)
    
    PROFILE("GUIProgressBar:Update")

    local objectiveFraction, objectiveText, teamType = PlayerUI_GetObjectiveInfo()
    local showProgressBar = not PlayerUI_GetIsDead() and PlayerUI_GetIsPlaying() and not PlayerUI_IsACommander() and not PlayerUI_GetBuyMenuDisplaying()

    if showProgressBar and objectiveFraction then

        self.progressBarBg:SetColor(kWhiteColor) 

        if self.teamType == kAlienTeamType then
            self.smokeyBackground:SetColor(kWhiteColor)
        elseif self.teamType == kMarineTeamType then
            self.circle:SetColor(kWhiteColor)
        end
        
        local textColor = Color(1,1,1,1)        
        if teamType ~= self.teamType then
            textColor = Color(1, 0.3, 0.3, 1)
        end
        
        self.objectiveText:SetColor(textColor)
        
        self.timeLastProgress = Shared.GetTime()
    
    else
    
        if self.timeLastProgress + kFadeOutDelay < Shared.GetTime() then
    
            local useColor = self.progressBarBg:GetColor()
            useColor.a = math.max(0, useColor.a - deltaTime)
            self.progressBarBg:SetColor(useColor)
            
            if self.teamType == kAlienTeamType then
                self.smokeyBackground:SetColor(useColor)
            elseif self.teamType == kMarineTeamType then
                self.circle:SetColor(useColor)
            end
        
        end
    
    end
    
    if objectiveFraction then
    
        self.progressBar:SetSize(Vector(GUIProgressBar.kSize.x * objectiveFraction, GUIProgressBar.kSize.y, 0))
        
        local x2Coords = kForegroundPixelCoords[1] + (kForegroundPixelCoords[3] - kForegroundPixelCoords[1]) * objectiveFraction        
        self.progressBar:SetTexturePixelCoordinates(kForegroundPixelCoords[1], kForegroundPixelCoords[2], x2Coords, kForegroundPixelCoords[4])
    
    end
    
    if objectiveText then
    
        self.objectiveText:SetText(objectiveText)
        self.objectiveTextShadow:SetText(objectiveText)
        
    end
    
    if self.teamType == kAlienTeamType then
        self.shine:SetColor(Color(1,1,1, 0.5 + 0.25 * (1 + math.cos(Shared.GetTime() * 6))  ))
    elseif self.teamType == kMarineTeamType then
        
        self.circleRotation.z = ( (Shared.GetTime() % kRotationDuration) / kRotationDuration ) * math.pi * -2
        self.circle:SetRotation(self.circleRotation)
        
    end    
    
end