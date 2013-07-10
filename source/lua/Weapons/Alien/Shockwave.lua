//=============================================================================
//
// lua\Weapons\Alien\Shockwave.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/DamageMixin.lua")

class 'Shockwave' (Projectile)

Shockwave.kMapName = "Shockwave"

local kStompCinematic = PrecacheAsset("cinematics/alien/onos/shockwave.cinematic")
local kStompHitCinematic = PrecacheAsset("cinematics/alien/onos/shockwave_hit.cinematic")

local networkVars = { }

local kShockwaveLifeTime = 6
local kUpdateRate = 0.06

function Shockwave:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, DamageMixin)
    
    if Server then
    
        self:AddTimedCallback(Shockwave.TimeUp, kShockwaveLifeTime)
        self:AddTimedCallback(Shockwave.UpdateStunnables, kUpdateRate)
        self.previousVelocity = Vector(0,0,0)
        
    end
    
    self:SetGroupFilterMask(PhysicsMask.NoBabblers)
    
end

function Shockwave:TimeUp()

    DestroyEntity(self)
    return false
    
end

function Shockwave:GetSimulatePhysics()
    return true
end

if Client then

    function Shockwave:OnInitialized()
    
        Projectile.OnInitialized(self)
        
        self.stompCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.stompCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.stompCinematic:SetCinematic(kStompCinematic)
        self.stompCinematic:SetCoords(self:GetCoords())
    
    end

end

function Shockwave:OnDestroy()

    if Client then
    
        if self.stompCinematic then
        
            Client.DestroyCinematic(self.stompCinematic)
            self.stompCinematic = nil
            
            local endCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            endCinematic:SetCinematic(kStompHitCinematic)
            endCinematic:SetCoords(self:GetCoords())
                
        end
        
    end
    
    Projectile.OnDestroy(self)

end

function Shockwave:ProcessHit(targetHit, surface, normal)

    if not targetHit then
    
        if (normal:DotProduct(GetNormalizedVector(self.previousVelocity)) * -1) > 0.5 then
            DestroyEntity(self)
        end
        
        if self:GetVelocity():GetLength() < kShockwaveSpeed * 0.2 then
            DestroyEntity(self)
        end
        
    end

end

function Shockwave:UpdateStunnables()

    for index, ent in ipairs(GetEntitiesWithMixinWithinRange("Stun", self:GetOrigin(), 3)) do
        ent:SetStun(kDisruptMarineTime)
    end

    return true

end

function Shockwave:GetPhysicsGroup()
    return PhysicsGroup.SmallStructuresGroup
end


function Shockwave:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Server then
    
        if not self.startPoint then
            self.startPoint = self:GetOrigin()
        end
    
        if (self:GetOrigin() - self.startPoint):GetLength() >= kStompRange then
            DestroyEntity(self)
        end

        self.previousVelocity = self:GetVelocity()
    
    elseif Client then
    
        if self.stompCinematic then    
        
            self.stompCinematic:SetCoords(self:GetCoords())                
            //DebugCapsule(self:GetOrigin(), self:GetOrigin(), 0.3, 0, 1 )
            
        end

    end

end

Shared.LinkClassToMap("Shockwave", Shockwave.kMapName, networkVars)