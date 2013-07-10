
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDamageIndicators.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the damage arrows pointing to the source of damage.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIDamageIndicators' (GUIAnimatedScript)

GUIDamageIndicators.kIndicatorSize = 128
GUIDamageIndicators.kArrowCenterOffset = 200
GUIDamageIndicators.kDefaultIndicatorPosition = Vector(-GUIDamageIndicators.kIndicatorSize / 2, -GUIDamageIndicators.kIndicatorSize / 2, 0)

local kNormalCoords = {0, 0, 1, 1}
local kFlippedCoords = {0, 1, 1, 0}

local kDamageTextures =
{
    [kDamageEffectType.Blood] = { "ui/damageFeedback/blood1.dds", "ui/damageFeedback/blood2.dds" },
    [kDamageEffectType.AlienBlood] = { "ui/damageFeedback/alien_blood1.dds", "ui/damageFeedback/alien_blood2.dds"},
    [kDamageEffectType.Sparks] = { } // "ui/damageFeedback/sparks1.dds" },
}

// considers GUIScale already
local kHitEffectSize = 800

function GUIDamageIndicators:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.indicatorItems = { }
    self.reuseItems = { }
    
    self.hitEffectSize = Vector(0,0,0)

end

function GUIDamageIndicators:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    for i, indicatorItem in ipairs(self.indicatorItems) do
        GUI.DestroyItem(indicatorItem)
    end
    self.indicatorItems = { }
    
    for i, indicatorItem in ipairs(self.reuseItems) do
        GUI.DestroyItem(indicatorItem)
    end
    self.reuseItems = { }
    
end

function GUIDamageIndicators:Update(deltaTime)

    PROFILE("GUIDamageIndicators:Update")

    GUIAnimatedScript.Update(self, deltaTime)

    local damageIndicators = PlayerUI_GetDamageIndicators()
    
    local numDamageIndicators = table.count(damageIndicators) / 2
    
    if numDamageIndicators ~= table.count(self.indicatorItems) then
        self:ResizeIndicatorList(numDamageIndicators)
    end
    
    local currentIndex = 1
    for i, indicatorItem in ipairs(self.indicatorItems) do
        local currentAlpha = damageIndicators[currentIndex]
        local currentAngle = damageIndicators[currentIndex + 1]
        indicatorItem:SetColor(Color(1, 1, 1, currentAlpha))
        indicatorItem:SetRotation(Vector(0, 0, currentAngle + math.pi))
        local direction = Vector(math.sin(currentAngle), math.cos(currentAngle), 0)
        direction:Normalize()
        local rotatedPosition = GUIDamageIndicators.kDefaultIndicatorPosition + (direction * GUIDamageIndicators.kArrowCenterOffset)
        indicatorItem:SetPosition(rotatedPosition)
        indicatorItem:SetBlendTechnique(GUIItem.Add)
        currentIndex = currentIndex + 2
    end
    
end

local function DestroyHitEffect(scriptHandle, hitEffectItem)
    hitEffectItem:Destroy()
end

function GUIDamageIndicators:OnTakeDamage(position, rotation, hitType)

    local textures = kDamageTextures[hitType]
    local useTexture = ""
    
    if not textures or #textures == 0 then
        return
    end
    
    local pixelCoords = ConditionalValue( math.random() > 0.5, kNormalCoords, kFlippedCoords  )
    
    // chose random texture if existant to get some variety
    if #textures > 1 then
        useTexture = textures[math.random(1, #textures)]
    else
        useTexture = textures[1]
    end

    self.hitEffectSize.x = GUIScale(kHitEffectSize)
    self.hitEffectSize.y = GUIScale(kHitEffectSize)

    local hitEffect = self:CreateAnimatedGraphicItem()
    hitEffect:SetIsScaling(false)
    hitEffect:SetTexture(useTexture)
    hitEffect:SetSize(self.hitEffectSize)
    hitEffect:SetPosition(position - self.hitEffectSize * .5)
    hitEffect:SetRotation(Vector(0, 0, rotation))
    hitEffect:SetTextureCoordinates(unpack(pixelCoords))
    hitEffect:SetLayer(0)
    
    hitEffect:FadeOut(1.8, "FADEOUT_HITEFFECT", AnimateCos, DestroyHitEffect)

end

function GUIDamageIndicators:ResizeIndicatorList(numIndicators)
    
    while numIndicators > table.count(self.indicatorItems) do
        local newIndicatorItem = self:CreateIndicatorItem()
        table.insert(self.indicatorItems, newIndicatorItem)
        newIndicatorItem:SetIsVisible(true)
    end
    
    while numIndicators < table.count(self.indicatorItems) do
        self.indicatorItems[1]:SetIsVisible(false)
        table.insert(self.reuseItems, self.indicatorItems[1])
        table.remove(self.indicatorItems, 1)
    end

end

function GUIDamageIndicators:CreateIndicatorItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseItems) > 0 then
        local returnIndicatorItem = self.reuseItems[1]
        table.remove(self.reuseItems, 1)
        return returnIndicatorItem
    end

    local newIndicator = GUIManager:CreateGraphicItem()
    newIndicator:SetSize(Vector(GUIDamageIndicators.kIndicatorSize, GUIDamageIndicators.kIndicatorSize, 0))
    newIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
    newIndicator:SetPosition(GUIDamageIndicators.kDefaultIndicatorPosition)
    newIndicator:SetTexture("ui/hud_damage_arrow.dds")
    newIndicator:SetIsVisible(false)
    return newIndicator
    
end
