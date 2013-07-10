// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\SnowBallThrower.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/Weapons/SnowBall.lua")

class 'SnowBallThrower' (Weapon)

SnowBallThrower.kMapName = "snowballthrower"

local kPlayerVelocityFraction = 1
local kBombVelocity = 15
local kShootLimit = 1

local networkVars =
{
    firingPrimary = "boolean",
    lastTimeShot = "time"
}

function SnowBallThrower:OnCreate()

    Weapon.OnCreate(self)
    
    self.firingPrimary = false
    self.lastTimeShot = 0
    
end

function SnowBallThrower:GetHUDSlot()
    return 1
end

local function FireBombProjectile(player)

    if Server then
    
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
        startPoint = startPointTrace.endPoint
        
        local startVelocity = viewCoords.zAxis * kBombVelocity
        
        local snowBall = CreateEntity(SnowBall.kMapName, startPoint, player:GetTeamNumber())
        snowBall:Setup(player, startVelocity, true, nil, player)
        
    end
    
end

function SnowBallThrower:OnPrimaryAttack(player)

    Weapon.OnPrimaryAttack(self, player)
    
    if Shared.GetTime() - self.lastTimeShot >= kShootLimit then
    
        if not self.firingPrimary then
            FireBombProjectile(player)
        end
        
        self.firingPrimary = true
        self.lastTimeShot = Shared.GetTime()
        
    end
    
end

function SnowBallThrower:OnPrimaryAttackEnd(player)

    Weapon.OnPrimaryAttackEnd(self, player)
    
    self.firingPrimary = false
    
end

Shared.LinkClassToMap("SnowBallThrower", SnowBallThrower.kMapName, networkVars)