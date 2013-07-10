// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\PulseGrenade.lua 
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")

class 'PulseGrenade' (Projectile)

PulseGrenade.kMapName = "pulsegrenade"
PulseGrenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

local networkVars = { }

local kLifeTime = 3

kPulseGrenadeDamageRadius = 7
kPulseGrenadeDamage = 120
kPulseGrenadeEnergyDamage = 95

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function PulseGrenade:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
    
        self:AddTimedCallback(PulseGrenade.Detonate, kLifeTime)
        
    end
    
end

function PulseGrenade:GetProjectileModel()
    return PulseGrenade.kModelName
end

function PulseGrenade:ProcessHit(targetHit)

    if targetHit and (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit and
       (not targetHit:isa("Whip") or targetHit:GetIsOnFire()) then
        self:Detonate(targetHit, surface)
    elseif self:GetVelocity():GetLength() > 2 then
        self:TriggerEffects("grenade_bounce")
    end
    
end

local function EnergyDamage(hitEntities, origin, radius, damage)

    for _, entity in ipairs(hitEntities) do
    
        if entity.GetEnergy and entity.SetEnergy then
        
            local targetPoint = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
            local energyToDrain = damage *  (1 - Clamp( (targetPoint - origin):GetLength() / radius, 0, 1))
            entity:SetEnergy(entity:GetEnergy() - energyToDrain)
        
        end
    
    end

end

function PulseGrenade:Detonate(targetHit)

    local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kPulseGrenadeDamageRadius)
    table.removevalue(hitEntities, self)

    if targetHit then
    
        table.removevalue(hitEntities, targetHit)
        self:DoDamage(kPulseGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        
        if targetHit.GetEnergy and targetHit.SetEnergy then
            targetHit:SetEnergy(targetHit:GetEnergy() - kPulseGrenadeEnergyDamage)
        end
        
    end
    
    local owner = self:GetOwner()
    if owner then
        table.insertunique(hitEntities, owner)
    end
    
    RadiusDamage(hitEntities, self:GetOrigin(), kPulseGrenadeDamageRadius, kPulseGrenadeDamage, self)
    EnergyDamage(hitEntities, self:GetOrigin(), kPulseGrenadeDamageRadius, kPulseGrenadeEnergyDamage)

    local surface = GetSurfaceFromEntity(targetHit)
    
    if GetIsVortexed(self) then
        surface = "ethereal"
    end

    local params = { surface = surface }
    if not targetHit then
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
    end
    
    self:TriggerEffects("pulse_grenade_explode", params)    
    CreateExplosionDecals(self)    
    DestroyEntity(self)

end

Shared.LinkClassToMap("PulseGrenade", PulseGrenade.kMapName, networkVars)