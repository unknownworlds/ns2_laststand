// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\ClusterGrenade.lua 
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")

class 'ClusterGrenade' (Projectile)

ClusterGrenade.kMapName = "clustergrenade"
ClusterGrenade.kModelName = PrecacheAsset("models/marine/grenades/gr_cluster.model")

local networkVars = { }

local kLifeTime = 2

kClusterGrenadeDamageRadius = 10
kClusterGrenadeDamage = 40

kClusterFragmentDamageRadius = 8
kClusterFragmentDamage = 25

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

local kClusterGrenadeFragmentPoints =
{
    Vector(0.1, 0.12, 0.1),
    Vector(-0.1, 0.12, -0.1),
    Vector(0.1, 0.12, -0.1),
    Vector(-0.1, 0.12, 0.1),
}

local function CreateFragments(self)

    local origin = self:GetOrigin()
    local player = self:GetOwner()
        
    for i = 1, #kClusterGrenadeFragmentPoints do
    
        local creationPoint = origin + kClusterGrenadeFragmentPoints[i]
        local fragment = CreateEntity(ClusterFragment.kMapName, creationPoint, self:GetTeamNumber())
        
        local startVelocity = GetNormalizedVector(creationPoint - origin) * (8 + math.random() * 3)   
        fragment:Setup(player, startVelocity, true, nil, self)
    
    end

end

function ClusterGrenade:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
    
        self:AddTimedCallback(ClusterGrenade.Detonate, kLifeTime)
        
    end
    
end

function ClusterGrenade:GetProjectileModel()
    return ClusterGrenade.kModelName
end

function ClusterGrenade:ProcessHit(targetHit, surface)

    if targetHit and (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit and
       (not targetHit:isa("Whip") or targetHit:GetIsOnFire()) then
        self:Detonate(targetHit, surface)
    elseif self:GetVelocity():GetLength() > 2 then
        self:TriggerEffects("grenade_bounce")
    end
    
end

function ClusterGrenade:Detonate(targetHit)

    CreateFragments(self)

    local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kClusterGrenadeDamageRadius)
    table.removevalue(hitEntities, self)

    if targetHit then
        table.removevalue(hitEntities, targetHit)
        self:DoDamage(kClusterGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
    end
    
    local owner = self:GetOwner()
    if owner then
        table.insertunique(hitEntities, owner)
    end
    
    RadiusDamage(hitEntities, self:GetOrigin(), kClusterGrenadeDamageRadius, kClusterGrenadeDamage, self)
    
    local surface = GetSurfaceFromEntity(targetHit)
    
    if GetIsVortexed(self) then
        surface = "ethereal"
    end

    local params = { surface = surface }
    if not targetHit then
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
    end
    
    self:TriggerEffects("grenade_explode", params)
    CreateExplosionDecals(self)
    DestroyEntity(self)

end

Shared.LinkClassToMap("ClusterGrenade", ClusterGrenade.kMapName, networkVars)


class 'ClusterFragment' (Projectile)

ClusterFragment.kMapName = "clusterfragment"
ClusterFragment.kModelName = PrecacheAsset("models/effects/frag_metal.model")

function ClusterFragment:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(ClusterFragment.Detonate, math.random() * 1 + 0.5)
    elseif Client then
        self:AddTimedCallback(ClusterFragment.CreateResidue, 0.06)
    end
    
end

function ClusterFragment:GetProjectileModel()
    return ClusterFragment.kModelName
end

function ClusterFragment:Detonate(targetHit)

    local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kClusterFragmentDamageRadius)
    table.removevalue(hitEntities, self)

    if targetHit then
        table.removevalue(hitEntities, targetHit)
        self:DoDamage(kClusterFragmentDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
    end
    
    local owner = self:GetOwner()
    if owner then
        table.insertunique(hitEntities, owner)
    end
    
    RadiusDamage(hitEntities, self:GetOrigin(), kClusterFragmentDamageRadius, kClusterFragmentDamage, self)
    
    local surface = GetSurfaceFromEntity(targetHit)
    
    if GetIsVortexed(self) then
        surface = "ethereal"
    end

    local params = { surface = surface }
    if not targetHit then
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
    end
    
    self:TriggerEffects("grenade_explode", params)
    CreateExplosionDecals(self)
    DestroyEntity(self)

end

function ClusterFragment:CreateResidue()

    self:TriggerEffects("clusterfragment_residue")
    return true

end

Shared.LinkClassToMap("ClusterFragment", ClusterFragment.kMapName, networkVars)