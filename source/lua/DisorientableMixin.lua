// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//    
// lua\DisorientableMixin.lua
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Andreas Urwalek (andi@unknownworlds.com)
//
//    Client side mixin.  Calculates disoriented amount and provides result with
//    GetDisorientedAmount()
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/CommAbilities/Alien/ShadeInk.lua")

DisorientableMixin = CreateMixin(DisorientableMixin)
DisorientableMixin.type = "Disorientable"

DisorientableMixin.expectedCallbacks = { }

// Don't update too often.
local kUpdateInterval = 0.5
local kDisorientIntensity = 4

DisorientableMixin.expectedMixins =
{
    Team = "For defining enemy shades."
}

local function UpdateDisorient(self)

    local fromPoint = self:GetOrigin()
    local nearbyEnemyShades = GetEntitiesForTeamWithinRange("ShadeInk", GetEnemyTeamNumber(self:GetTeamNumber()), fromPoint, ShadeInk.kShadeInkDisorientRadius)
    Shared.SortEntitiesByDistance(fromPoint, nearbyEnemyShades)
    
    local adjustedDisorient = false
    
    for s = 1, #nearbyEnemyShades do
    
        local shade = nearbyEnemyShades[s]
        local distanceToShade = (shade:GetOrigin() - fromPoint):GetLength()
        self.disorientedAmount = kDisorientIntensity - Clamp((distanceToShade / ShadeInk.kShadeInkDisorientRadius) * kDisorientIntensity, 0, kDisorientIntensity)
        adjustedDisorient = true
        break
        
    end
    
    if not adjustedDisorient then
        self.disorientedAmount = 0
    end
    
    return true
    
end

function DisorientableMixin:__initmixin()

    self.disorientedAmount = 0
    
    self:AddTimedCallback(UpdateDisorient, kUpdateInterval)
    
end

function DisorientableMixin:GetDisorientedAmount()
    return self.disorientedAmount
end