// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPlayerNameTags.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays name tags above the heads of nearby players.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kNameTagFontSize = 20
local kNameTagRange = 15
local kCommNameTagRange = 40
local kNameTagHeightOffset = 0.05
local kBadgeWidth = 32
local kBadgeHeight = 32
local kBadgeIconOffset = Vector(-kBadgeWidth / 2, -kBadgeHeight / 2, 0)

local kTextures = { [kMarineTeamType] = "ui/unitstatus_neutral.dds", [kAlienTeamType] = "ui/unitstatus_neutral.dds", [kNeutralTeamType] = "ui/unitstatus_neutral.dds" }

local kUnitStatusBarTexCoords = { 256, 0, 256 + 512, 64 }

local kBorderCoords = { 256, 256, 256 + 512, 256 + 128 }
local kBorderMaskPixelCoords = { 256, 384, 256 + 512, 384 + 512 }
local kBorderMaskCircleRadius = GUIScale(130)

local kNameOffset = Vector(0, GUIScale(-12), 0)

local kFontScale = GUIScale(Vector(1, 1, 1)) * 0.7

local kHealthBarWidth = GUIScale(130)
local kHealthBarHeight = GUIScale(8)


local kArmorBarWidth = GUIScale(130)
local kArmorBarHeight = GUIScale(4)

local kBorderSize = Vector(180, 60, 0)
// How much space to allow on the left and right side of the border when
// the name is very wide.
local kBorderNameWidthBuffer = 8

local kRotationDuration = 8

class 'GUIPlayerNameTags' (GUIScript)

function GUIPlayerNameTags:Initialize()
    self.nameTags = { }
end

function GUIPlayerNameTags:Uninitialize()

    for _, nameTag in ipairs(self.nameTags) do
    
        GUI.DestroyItem(nameTag.Badge)
        GUI.DestroyItem(nameTag.HealthBarBg)
        GUI.DestroyItem(nameTag.ArmorBarBg)
        GUI.DestroyItem(nameTag.Name)
        GUI.DestroyItem(nameTag.BorderMask)
        GUI.DestroyItem(nameTag.Border)
        GUI.DestroyItem(nameTag.Background)
        
    end
    self.nameTags = { }
    
end

local function GetNameTagTeammates(range)

    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        local team = localPlayer:GetTeamNumber()
        local origin = localPlayer:GetOrigin()
        
        // Spectator players should see name tags for players not on the spectator team.
        // Everyone else should only see name tags for players on their own team.
        local filter
        if team == kSpectatorIndex then
        
            filter = function(entity) 
                return entity ~= localPlayer and entity:GetTeamNumber() ~= team 
            end
            
        else
        
            filter = function(entity)
                return entity ~= localPlayer and entity:GetTeamNumber() == team 
            end
            
        end
        
        return Shared.GetEntitiesWithTagInRange("class:Player", origin, range, filter)
        
    end
    
    return { }
    
end

local function FreeAllNameTags(self)

    for _, nameTag in ipairs(self.nameTags) do
        nameTag.Background:SetIsVisible(false)
    end
    
end

local function GetPixelCoordsForFraction(fraction)

    local width = kUnitStatusBarTexCoords[3] - kUnitStatusBarTexCoords[1]
    local x1 = kUnitStatusBarTexCoords[1]
    local x2 = x1 + width * fraction
    local y1 = kUnitStatusBarTexCoords[2]
    local y2 = kUnitStatusBarTexCoords[4]
    
    return x1, y1, x2, y2
    
end

local function InitNameTagItems(nameTagItems, teamType)

    nameTagItems.Background:SetAnchor(GUIItem.Top, GUIItem.Left)
    nameTagItems.Background:SetColor(Color(0, 0, 0, 0))
    nameTagItems.Background:SetIsVisible(true)
    
    nameTagItems.Badge:SetAnchor(GUIItem.Middle, GUIItem.Center)
    nameTagItems.Badge:SetPosition(kBadgeIconOffset * GUIScale(1))
    nameTagItems.Badge:SetSize(Vector(kBadgeWidth, kBadgeHeight, 0) * GUIScale(1))
    nameTagItems.Badge:SetIsVisible(false)
    
    nameTagItems.Name:SetLayer(kGUILayerPlayerNameTags)
    nameTagItems.Name:SetFontName(kNameTagFontNames[teamType])
    nameTagItems.Name:SetFontSize(kNameTagFontSize)
    nameTagItems.Name:SetScale(kFontScale)
    nameTagItems.Name:SetColor(kNameTagFontColors[teamType])
    nameTagItems.Name:SetAnchor(GUIItem.Middle, GUIItem.Center)
    nameTagItems.Name:SetTextAlignmentX(GUIItem.Align_Center)
    nameTagItems.Name:SetTextAlignmentY(GUIItem.Align_Center)
    nameTagItems.Name:SetPosition(kNameOffset)
    
    local texture = kTextures[teamType]
    
    nameTagItems.Border:SetAnchor(GUIItem.Middle, GUIItem.Center)
    nameTagItems.Border:SetSize(kBorderSize)
    nameTagItems.Border:SetPosition(-kBorderSize / 2)
    nameTagItems.Border:SetTexture(texture)
    nameTagItems.Border:SetTexturePixelCoordinates(unpack(kBorderCoords))
    nameTagItems.Border:SetIsStencil(true)
    
    nameTagItems.BorderMask:SetTexture(texture)
    nameTagItems.BorderMask:SetAnchor(GUIItem.Middle, GUIItem.Center)
    nameTagItems.BorderMask:SetBlendTechnique(GUIItem.Add)
    nameTagItems.BorderMask:SetTexturePixelCoordinates(unpack(kBorderMaskPixelCoords))
    nameTagItems.BorderMask:SetSize(Vector(kBorderMaskCircleRadius * 2, kBorderMaskCircleRadius * 2, 0))
    nameTagItems.BorderMask:SetPosition(Vector(-kBorderMaskCircleRadius, -kBorderMaskCircleRadius, 0))
    nameTagItems.BorderMask:SetStencilFunc(GUIItem.NotEqual)
    
    nameTagItems.HealthBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    nameTagItems.HealthBarBg:SetSize(Vector(kHealthBarWidth, kHealthBarHeight, 0))
    nameTagItems.HealthBarBg:SetPosition(Vector(-kHealthBarWidth / 2, -kHealthBarHeight - kArmorBarHeight - 4, 0))
    nameTagItems.HealthBarBg:SetTexture(texture)
    nameTagItems.HealthBarBg:SetTexturePixelCoordinates(unpack(kUnitStatusBarTexCoords))
    
    nameTagItems.HealthBar:SetColor(kHealthBarColors[teamType])
    nameTagItems.HealthBar:SetSize(Vector(kHealthBarWidth, kHealthBarHeight, 0))
    nameTagItems.HealthBar:SetTexture(texture)
    nameTagItems.HealthBar:SetTexturePixelCoordinates(unpack(kUnitStatusBarTexCoords))
    nameTagItems.HealthBar:SetBlendTechnique(GUIItem.Add)
    
    nameTagItems.ArmorBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    nameTagItems.ArmorBarBg:SetSize(Vector(kArmorBarWidth, kArmorBarHeight, 0))
    nameTagItems.ArmorBarBg:SetPosition(Vector(-kArmorBarWidth / 2, -kArmorBarHeight - 4, 0))
    nameTagItems.ArmorBarBg:SetTexture(texture)
    nameTagItems.ArmorBarBg:SetTexturePixelCoordinates(unpack(kUnitStatusBarTexCoords))
    
    nameTagItems.ArmorBar:SetColor(kArmorBarColors[teamType])
    nameTagItems.ArmorBar:SetSize(Vector(kArmorBarWidth, kArmorBarHeight, 0))
    nameTagItems.ArmorBar:SetTexture(texture)
    nameTagItems.ArmorBar:SetTexturePixelCoordinates(unpack(kUnitStatusBarTexCoords))
    nameTagItems.ArmorBar:SetBlendTechnique(GUIItem.Add)
    
end

local function GetFreeNameTag(self, teamType)

    for _, nameTag in ipairs(self.nameTags) do
    
        if not nameTag.Background:GetIsVisible() then
        
            InitNameTagItems(nameTag, teamType)
            nameTag.Background:SetIsVisible(true)
            return nameTag
            
        end
        
    end
    
    // The background is going to contain everything and make
    // positioning easier.
    local background = GUIManager:CreateGraphicItem()
    
    local badgeIcon = GUIManager:CreateGraphicItem()
    
    local nameTag = GUIManager:CreateTextItem()
    
    local border = GetGUIManager():CreateGraphicItem()
    
    local borderMask = GetGUIManager():CreateGraphicItem()
    
    border:AddChild(borderMask)
    
    local healthBarBg = GUIManager:CreateGraphicItem()
    
    local healthBar = GUIManager:CreateGraphicItem()
    
    local armorBarBg = GUIManager:CreateGraphicItem()
    
    local armorBar = GUIManager:CreateGraphicItem()
    
    border:AddChild(healthBarBg)
    border:AddChild(armorBarBg)
    
    healthBarBg:AddChild(healthBar)
    armorBarBg:AddChild(armorBar)
    
    background:AddChild(border)
    background:AddChild(badgeIcon)
    background:AddChild(nameTag)
    
    local newNameTag = { Background = background, Badge = badgeIcon, Name = nameTag, HealthBar = healthBar, HealthBarBg = healthBarBg, ArmorBar = armorBar, ArmorBarBg = armorBarBg, BorderMask = borderMask, Border = border }
    table.insert(self.nameTags, newNameTag)
    
    InitNameTagItems(newNameTag, teamType)
    
    return newNameTag
    
end

local function SetupNameTagForCrosshairTarget(nameTag, teammate, distance, useColor)

    local healthBarBgColor = useColor
    nameTag.HealthBarBg:SetColor(Color(healthBarBgColor.r * 0.5, healthBarBgColor.g * 0.5, healthBarBgColor.b * 0.5, healthBarBgColor.a * distance))
    local healthBarColor = useColor
    nameTag.HealthBar:SetColor(Color(healthBarColor.r, healthBarColor.g, healthBarColor.b, distance))
    
    local armorBarBgColor = nameTag.ArmorBarBg:GetColor()
    nameTag.ArmorBarBg:SetColor(Color(armorBarBgColor.r, armorBarBgColor.g, armorBarBgColor.b, armorBarBgColor.a * distance))
    local armorBarColor = nameTag.ArmorBar:GetColor()
    nameTag.ArmorBar:SetColor(Color(armorBarColor.r, armorBarColor.g, armorBarColor.b, distance))
    
    local healthFraction = teammate:GetHealth() / teammate:GetMaxHealth()
    local armorFraction = teammate:GetArmor() / teammate:GetMaxArmor()
    
    nameTag.HealthBar:SetTexturePixelCoordinates(GetPixelCoordsForFraction(healthFraction))
    nameTag.HealthBar:SetSize(Vector(kHealthBarWidth * healthFraction, kHealthBarHeight, 0))
    
    nameTag.ArmorBar:SetTexturePixelCoordinates(GetPixelCoordsForFraction(armorFraction))
    nameTag.ArmorBar:SetSize(Vector(kArmorBarWidth * armorFraction, kArmorBarHeight, 0))
    
    if HasMixin(teammate, "Badge") then
    
        local badgeIcon = teammate:GetBadgeIcon()
        if badgeIcon then
        
            nameTag.Badge:SetTexture(badgeIcon)
            nameTag.Badge:SetIsVisible(true)
            local nameWidth = nameTag.Name:GetTextWidth(teammate:GetName())
            local nameHeight = nameTag.Name:GetTextHeight(teammate:GetName())
            nameTag.Badge:SetPosition((kBadgeIconOffset + Vector(-nameWidth - kBadgeWidth, -nameHeight / 2, 0)) * GUIScale(1))
            nameTag.Badge:SetColor(Color(1, 1, 1, distance))
            
        end
        
    end
    
end

local kCommOffset = Vector(0, GUIScale(-64), 0)

function GUIPlayerNameTags:Update(deltaTime)

    FreeAllNameTags(self)
    
    local localPlayer = Client.GetLocalPlayer()
    
    if not localPlayer then
        return
    end
    
    local teammates = GetNameTagTeammates(ConditionalValue(PlayerUI_IsACommander(), kCommNameTagRange, kNameTagRange))
    local crosshairTarget = localPlayer:GetCrossHairTarget()

    for _, teammate in ipairs(teammates) do
    
        if teammate ~= localPlayer and teammate:GetIsAlive() then
        
            local teammateUnderCrosshair = teammate == crosshairTarget

            // Check if the teammate is in front of the local player
            // Compare with the player camera coordinates
            local cameraCoords = localPlayer:GetCameraViewCoords()
            local playerForward = cameraCoords.zAxis
            local playerToTeammate = GetNormalizedVector(teammate:GetOrigin() - cameraCoords.origin)
            local dotProduct = Math.DotProduct(playerForward, playerToTeammate)
            local min, max = teammate:GetModelExtents()
            
            if (dotProduct > 0 and min and max) or PlayerUI_IsACommander() then
            
                local nameTag = GetFreeNameTag(self, teammate:GetTeamType())
                local useColor = kHealthBarColors[teammate:GetTeamType()]

                // Scale everything based on distance.
                local distance = teammate:GetDistanceSquared(localPlayer)
                distance = distance / (kNameTagRange * kNameTagRange)
                distance = 1 - distance
                
                // show always for commanders
                if PlayerUI_IsACommander() then
                
                    distance = 1
                    
                    if teammate.poisoned then  
                        useColor = kPoisonedColor
                    elseif GetIsParasited(teammate) then
                        useColor = kParasiteColor
                    end
                    
                end
                
                // Setup background.
                local backgroundSize = Vector(nameTag.Name:GetTextWidth(teammate:GetName()), nameTag.Name:GetTextHeight(teammate:GetName()), 0)
                nameTag.Background:SetSize(backgroundSize)
                local nameTagWorldPosition = teammate:GetOrigin() + Vector(0, max.y + kNameTagHeightOffset, 0)
                local nameTagInScreenspace = Client.WorldToScreen(nameTagWorldPosition)
                
                if PlayerUI_IsACommander() then
                    nameTagInScreenspace = nameTagInScreenspace + kCommOffset
                end

                nameTag.Background:SetPosition(nameTagInScreenspace - (backgroundSize / 2))
                
                // Scale the border width by to match the width of the player name (plus a little buffer space).
                local newBorderSize = Vector(math.max(kBorderSize.x, backgroundSize.x + kBorderNameWidthBuffer), kBorderSize.y, 0)
                nameTag.Border:SetSize(newBorderSize)
                nameTag.Border:SetPosition(-newBorderSize / 2)
                // Also scale the border mask based on the name width.
                local borderMaskScale = newBorderSize.x / kBorderSize.x
                nameTag.BorderMask:SetScale(Vector(borderMaskScale, borderMaskScale, 0))
                
                nameTag.BorderMask:SetColor(Color(useColor.r, useColor.g, useColor.b, distance))
                nameTag.Name:SetColor(Color(useColor.r, useColor.g, useColor.b, distance))
                
                nameTag.Name:SetText(teammate:GetName())
                
                local baseRotationPercentage = (Shared.GetTime() % kRotationDuration) / kRotationDuration
                nameTag.BorderMask:SetRotation(Vector(0, 0, -2 * math.pi * baseRotationPercentage))
                
                nameTag.HealthBarBg:SetIsVisible(teammateUnderCrosshair or PlayerUI_IsACommander())
                nameTag.ArmorBarBg:SetIsVisible(teammateUnderCrosshair or PlayerUI_IsACommander())

                if teammateUnderCrosshair or PlayerUI_IsACommander() then
                    SetupNameTagForCrosshairTarget(nameTag, teammate, distance, useColor)
                end
                
            end
            
        end
        
    end
    
end