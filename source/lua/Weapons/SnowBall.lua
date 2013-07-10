// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\SnowBall.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")

class 'SnowBall' (Projectile)

SnowBall.kMapName = "SnowBall"
local kModelName = PrecacheAsset("seasonal/holiday2012/models/snowball_01.model")

Shared.PrecacheSurfaceShader("seasonal/holiday2012/materials/effects/snow_splat.surface_shader")

local kLifetime = 60

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function SnowBall:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    
end

function SnowBall:OnInitialized()

    Projectile.OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(SnowBall.TimeUp, kLifetime)
    end
    
end

function SnowBall:GetProjectileModel()
    return kModelName
end

if Server then

    function SnowBall:ProcessHit(targetHit, surface, normal)
    
        if (not self:GetOwner() or targetHit ~= self:GetOwner()) then
        
            self:TriggerEffects("snowball_hit")
            
            DestroyEntity(self)
            
            if not targetHit then
            
                local coords = Coords.GetIdentity()
                coords.origin = self:GetOrigin()
                coords.yAxis = normal
                coords.zAxis = GetNormalizedVector(self.desiredVelocity)
                coords.xAxis = coords.zAxis:CrossProduct(coords.yAxis)
                coords.zAxis = coords.yAxis:CrossProduct(coords.xAxis)
                local angles = Angles()
                angles:BuildFromCoords(coords)
                local message = { origin = coords.origin, yaw = angles.yaw, pitch = angles.pitch, roll = angles.roll }
                local nearbyPlayers = GetEntitiesWithinRange("Player", self:GetOrigin(), 20)
                for p = 1, #nearbyPlayers do
                    Server.SendNetworkMessage(nearbyPlayers[p], "SnowBallHit", message, false)
                end
                
            end
            
        end
        
    end
    
    function SnowBall:TimeUp(currentRate)
    
        DestroyEntity(self)
        return false
        
    end
    
end

local kSnowBallHitMessage =
{
    origin = "vector",
    yaw = "angle",
    pitch = "angle",
    roll = "angle"
}
Shared.RegisterNetworkMessage("SnowBallHit", kSnowBallHitMessage)

if Client then

    local kSplatAnimDuration = 0.1
    local kSplatLifeTime = 8
    local kFadeOutAnimDuration = 3
    
    local hitEffects = { }
    
    local function OnUpdateClient()
    
        for e = #hitEffects, 1, -1 do
        
            local hitEffect = hitEffects[e]
            local intensity = 0.0
            local remainingTime = kSplatLifeTime - (Shared.GetTime() - hitEffect.creationTime) - 0.5
            
            if remainingTime < kFadeOutAnimDuration then
                intensity = 1 - (remainingTime / kFadeOutAnimDuration)
            end
            
            local radius = 0.4 * Clamp((Shared.GetTime() - hitEffect.creationTime) / kSplatAnimDuration, 0, 1)
            hitEffect.decal:SetExtents(Vector(radius, 0.3, radius))
            
            hitEffect.material:SetParameter("intensity", 1 - intensity)
            
            if intensity >= 1 then
            
                Client.DestroyRenderDecal(hitEffect.decal)
                table.remove(hitEffects, e)
                
            end
            
        end
        
    end
    Event.Hook("UpdateClient", OnUpdateClient)
    
    local function OnMessageSnowBallHit(message)
    
        local hitEffect = { }
        hitEffect.decal = Client.CreateRenderDecal()
        hitEffect.material = Client.CreateRenderMaterial()
        hitEffect.material:SetMaterial("seasonal/holiday2012/materials/effects/snow_splat.material")
        hitEffect.decal:SetMaterial(hitEffect.material)
        hitEffect.creationTime = Shared.GetTime()
        
        local coords = Angles(message.pitch, message.yaw, message.roll):GetCoords(message.origin)
        hitEffect.decal:SetCoords(coords)
        
        table.insert(hitEffects, hitEffect)
        
    end
    Client.HookNetworkMessage("SnowBallHit", OnMessageSnowBallHit)
    
end

Shared.LinkClassToMap("SnowBall", SnowBall.kMapName, networkVars)