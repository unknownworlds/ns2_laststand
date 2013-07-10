// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\GrenadeThrower.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Base class for hand grenades. Override GetViewModelName and GetGrenadeMapName in implementation.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GrenadeThrower' (Weapon)

GrenadeThrower.kMapName = "grenadethrower"

kMaxHandGrenades = 2

local kGrenadeVelocity = 15

local networkVars =
{
    numGrenades = "integer (0 to ".. kMaxHandGrenades ..")",
}

local function ThrowGrenade(self, player)

    if Server then
    
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
        startPoint = startPointTrace.endPoint
        
        local startVelocity = viewCoords.zAxis * kGrenadeVelocity
        
        local grenade = CreateEntity(self:GetGrenadeMapName(), startPoint, player:GetTeamNumber())
        grenade:Setup(player, startVelocity, true, nil, player)
        
    end

end

function GrenadeThrower:OnTag(tagName)

    if tagName == "throw" then
    
        local player = self:GetParent()
        if player then
            ThrowGrenade(self, player)
        end
        
    end

end

function GrenadeThrower:GetHUDSlot()
    return 5
end

function GrenadeThrower:GetViewModelName()
    assert(false)
end

function GrenadeThrower:GetGrenadeMapName()
    assert(false)
end

Shared.LinkClassToMap("GrenadeThrower", GrenadeThrower.kMapName, networkVars)