// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\GUIExoHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSheet1 = PrecacheAsset("ui/exosuit_HUD1.dds")
local kSheet2 = PrecacheAsset("ui/exosuit_HUD2.dds")
local kSheet3 = PrecacheAsset("ui/exosuit_HUD3.dds")
local kSheet4 = PrecacheAsset("ui/exosuit_HUD4.dds")

local kTargetingReticuleCoords = { 185, 0, 354, 184 }

local kStaticRingCoords = { 0, 490, 800, 1000 }

local kInfoBarRightCoords = { 354, 184, 800, 368 }
local kInfoBarLeftCoords = { 354, 0, 800, 184 }

local kInnerRingCoords = { 0, 316, 330, 646 }

local kOuterRingCoords = { 0, 0, 800, 490 }

local kCrosshairCoords = { 495, 403, 639, 547 }

local kTrackEntityDistance = 30

local function CoordsToSize(coords)
    return Vector(coords[3] - coords[1], coords[4] - coords[2], 0)
end

class 'GUIExoHUD' (GUIScript)

function GUIExoHUD:Initialize()

    GUIScript.Initialize(self)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetPosition(Vector(0, 0, 0))
    self.background:SetIsVisible(true)
    self.background:SetLayer(kGUILayerPlayerHUDBackground)
    self.background:SetColor(Color(1, 1, 1, 0))
    
    self.staticRing = GUIManager:CreateGraphicItem()
    self.staticRing:SetTexture(kSheet4)
    self.staticRing:SetTexturePixelCoordinates(unpack(kStaticRingCoords))
    local size = CoordsToSize(kStaticRingCoords)
    self.staticRing:SetSize(size)
    self.staticRing:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.staticRing:SetPosition(Vector(-size.x / 2, -size.y / 2, 0))
    self.staticRing:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(self.staticRing)
    
    local leftInfoBar = GUIManager:CreateGraphicItem()
    leftInfoBar:SetTexture(kSheet1)
    leftInfoBar:SetTexturePixelCoordinates(unpack(kInfoBarLeftCoords))
    size = CoordsToSize(kInfoBarLeftCoords)
    leftInfoBar:SetSize(size)
    leftInfoBar:SetAnchor(GUIItem.Middle, GUIItem.Top)
    leftInfoBar:SetPosition(Vector(-size.x, 0, 0))
    leftInfoBar:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(leftInfoBar)
    
    local rightInfoBar = GUIManager:CreateGraphicItem()
    rightInfoBar:SetTexture(kSheet1)
    rightInfoBar:SetTexturePixelCoordinates(unpack(kInfoBarRightCoords))
    size = CoordsToSize(kInfoBarRightCoords)
    rightInfoBar:SetSize(size)
    rightInfoBar:SetAnchor(GUIItem.Middle, GUIItem.Top)
    rightInfoBar:SetPosition(Vector(0, 0, 0))
    rightInfoBar:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(rightInfoBar)
    
    self.innerRing = GUIManager:CreateGraphicItem()
    self.innerRing:SetTexture(kSheet1)
    self.innerRing:SetTexturePixelCoordinates(unpack(kInnerRingCoords))
    size = CoordsToSize(kInnerRingCoords)
    self.innerRing:SetSize(size)
    self.innerRing:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.innerRing:SetPosition(-(size / 2))
    self.innerRing:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(self.innerRing)
    
    self.outerRing = GUIManager:CreateGraphicItem()
    self.outerRing:SetTexture(kSheet4)
    self.outerRing:SetTexturePixelCoordinates(unpack(kOuterRingCoords))
    size = CoordsToSize(kOuterRingCoords)
    self.outerRing:SetSize(size)
    self.outerRing:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.outerRing:SetPosition(-(size / 2))
    self.outerRing:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(self.outerRing)
    
    self.crosshair = GUIManager:CreateGraphicItem()
    self.crosshair:SetTexture(kSheet1)
    self.crosshair:SetTexturePixelCoordinates(unpack(kCrosshairCoords))
    size = CoordsToSize(kCrosshairCoords)
    self.crosshair:SetSize(size)
    self.crosshair:SetLayer(kGUILayerPlayerHUDForeground1)
    self.crosshair:SetIsVisible(false)
    self.background:AddChild(self.crosshair)
    
    self.targets = { }
    
end

function GUIExoHUD:Uninitialize()

    GUIScript.Initialize(self)
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIExoHUD:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible)
end

local function GetFreeTargetItem(self)

    for r = 1, #self.targets do
    
        local target = self.targets[r]
        if not target:GetIsVisible() then
        
            target:SetIsVisible(true)
            return target
            
        end
        
    end
    
    local target = GUIManager:CreateGraphicItem()
    target:SetTexture(kSheet1)
    target:SetTexturePixelCoordinates(unpack(kTargetingReticuleCoords))
    local size = CoordsToSize(kTargetingReticuleCoords)
    target:SetSize(size)
    target:SetLayer(kGUILayerPlayerHUDForeground1)
    self.background:AddChild(target)
    
    table.insert(self.targets, target)
    
    return target
    
end

local function Gaussian(mean, stddev, x) 

    local variance2 = stddev * stddev * 2.0
    local term = x - mean
    return math.exp(-(term * term) / variance2) / math.sqrt(math.pi * variance2)
    
end

local function UpdateTargets(self)

    for r = 1, #self.targets do
        self.targets[r]:SetIsVisible(false)
    end
    
    if not PlayerUI_GetHasMinigun() then
        return
    end
    
    local trackEntities = GetEntitiesWithinRange("Alien", PlayerUI_GetOrigin(), kTrackEntityDistance)
    local closestToCrosshair = nil
    local closestDistToCrosshair = math.huge
    local closestToCrosshairScale = nil
    local closestToCrosshairOpacity = nil
    for t = 1, #trackEntities do
    
        local trackEntity = trackEntities[t]
        local player = Client.GetLocalPlayer()
        local inFront = player:GetViewCoords().zAxis:DotProduct(GetNormalizedVector(trackEntity:GetModelOrigin() - player:GetEyePos())) > 0
        // Only really looks good on Skulks currently.
        if inFront and trackEntity:GetIsAlive() and trackEntity:isa("Skulk") and not trackEntity:GetIsCloaked() then
        
            local trace = Shared.TraceRay(player:GetEyePos(), trackEntity:GetModelOrigin(), CollisionRep.Move, PhysicsMask.All, EntityFilterOne(player))
            if trace.entity == trackEntity then
            
                local targetItem = GetFreeTargetItem(self)
                
                local min, max = trackEntity:GetModelExtents()
                local distance = trackEntity:GetDistance(PlayerUI_GetOrigin())
                local scalar = max:GetLength() / distance * 8
                local size = CoordsToSize(kTargetingReticuleCoords)
                local scaledSize = size * scalar
                targetItem:SetSize(scaledSize)
                
                local targetScreenPos = Client.WorldToScreen(trackEntity:GetModelOrigin())
                targetItem:SetPosition(targetScreenPos - scaledSize / 2)
                
                local opacity = math.min(1, Gaussian(0.5, 0.1, distance / kTrackEntityDistance))
                
                // Factor distance to the crosshair into opacity.
                local distToCrosshair = (targetScreenPos - Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() / 2, 0)):GetLength()
                opacity = opacity * (1 - (distToCrosshair / 300))
                
                targetItem:SetColor(Color(1, 1, 1, opacity))
                
                if distToCrosshair < closestDistToCrosshair then
                
                    closestDistToCrosshair = distToCrosshair
                    closestToCrosshair = targetScreenPos
                    closestToCrosshairScale = scalar
                    closestToCrosshairOpacity = opacity
                    
                end
                
            end
            
        end
        
    end
    
    if closestToCrosshair ~= nil and closestDistToCrosshair < 50 then
    
        self.crosshair:SetIsVisible(true)
        local size = CoordsToSize(kCrosshairCoords) * (0.75 + (0.25 * ((math.sin(Shared.GetTime() * 7) + 1) / 2)))
        local scaledSize = size * closestToCrosshairScale
        self.crosshair:SetSize(scaledSize)
        self.crosshair:SetPosition(closestToCrosshair - scaledSize / 2)
        self.crosshair:SetColor(Color(1, 1, 1, closestToCrosshairOpacity))
        
    else
        self.crosshair:SetIsVisible(false)
    end
    
end

local kAnimDuration = 1

function GUIExoHUD:Update(deltaTime)

    PROFILE("GUIExoHUD:Update")
    
    self.ringRotation = self.ringRotation or 0
    self.lastPlayerYaw = self.lastPlayerYaw or PlayerUI_GetYaw()
    
    local currentYaw = PlayerUI_GetYaw()
    self.ringRotation = self.ringRotation + (GetAnglesDifference(self.lastPlayerYaw, currentYaw) * 0.25)
    self.lastPlayerYaw = currentYaw
    
    self.innerRing:SetRotation(Vector(0, 0, -self.ringRotation))
    self.outerRing:SetRotation(Vector(0, 0, self.ringRotation))
    
    local timeLastDamage = PlayerUI_GetTimeDamageTaken()
    local animFraction = Clamp( (Shared.GetTime() - timeLastDamage) / kAnimDuration, 0, 1)
    
    local color = Color(1, animFraction, animFraction, 1)
   
    self.staticRing:SetColor(color)    
    self.innerRing:SetColor(color)
    self.outerRing:SetColor(color)
    
    UpdateTargets(self)
    
end

function GUIExoHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.background:SetSize(Vector(newX, newY, 0))
    
end