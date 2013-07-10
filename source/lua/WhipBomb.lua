//=============================================================================
//
// lua\WhipBomb.lua
//
// Created by Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// WhipBomb projectile
//
//=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'WhipBomb' (Projectile)

local networkVars = { }

WhipBomb.kMapName            = "whipbomb"
WhipBomb.kModelName          = PrecacheAsset("models/alien/whip/ball.model")

// The max amount of time a WhipBomb can last for
WhipBomb.kLifetime = 3

WhipBomb.kSplashRadius = kWhipBombardRadius

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

local kWhipBombTrailCinematic = PrecacheAsset("cinematics/alien/whip/dripping_slime.cinematic")

function WhipBomb:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    // Remember when we're created so we can fall off damage
    self.createTime = Shared.GetTime()
    self.radius = 0.2
    
end

function WhipBomb:OnInitialized()

    Projectile.OnInitialized(self)
    
    self:SetModel(WhipBomb.kModelName)
    
    if Client then
    
        self.lastPosition = self:GetOrigin()
    
        self.trailCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.trailCinematic:SetCinematic(kWhipBombTrailCinematic)
        self.trailCinematic:SetCoords(self:GetCoords())
        self.trailCinematic:SetIsVisible(true)
        self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end
    
end

function WhipBomb:OnDestroy()

    Projectile.OnDestroy(self)
    
    if Client then
    
        if self.trailCinematic then
        
            Client.DestroyCinematic(self.trailCinematic)
            self.trailCinematic = nil
        
        end

    end

end

function WhipBomb:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

function WhipBomb:GetDamageType()
    return kWhipBombardDamageType
end

if (Server) then

    function WhipBomb:SetLifetime(lifetime)
        self:AddTimedCallback(WhipBomb.TimeUp, math.min(lifetime, WhipBomb.kLifetime))
    end

    function WhipBomb:ProcessHit(targetHit)
    
        if not self:GetIsDestroyed() then
            self:Detonate()
        end
        
    end
    
    function WhipBomb:Detonate()
    
        assert(not self:GetIsDestroyed())
        
        // Do splash damage to structures and ARCs, ignore friendly players here. the owner (alien commander) is not supposed to be damaged by their own whip
        // this is an exception, since the default rule would be that the owner can be damaged
        local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), WhipBomb.kSplashRadius)

        // Do damage to every target in range
        RadiusDamage(hitEntities, self:GetOrigin(), WhipBomb.kSplashRadius, kWhipBombardDamage, self)
        
        self:TriggerEffects("whipbomb_hit")

        // notify our shooter were we detonated to allow adjustments
        if self.shooter then
            self.shooter:OnBombDetonation(self)
        end
        
        DestroyEntity(self)
        
    end
    
    function WhipBomb:TimeUp(currentRate)
    
        if not self:GetIsDestroyed() then
            self:Detonate()
        end
        
        return false
        
    end
    
    function WhipBomb:CreatePhysics()
    
        if (self.physicsBody == nil) then
            Projectile.CreatePhysics(self)
            self.physicsBody:SetGroupFilterMask(PhysicsMask.OnlyWhip)
        end
    
    end  
    
end

function WhipBomb:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Server then
        self:SetOrientationFromVelocity()
        
    elseif Client then

        if self.trailCinematic then
        
            local origin = self:GetOrigin()
            local coords = Coords.GetLookIn( origin, self.lastPosition - origin )
            self.lastPosition = origin
            
            self.trailCinematic:SetCoords(coords)
        
        end
        
    end
    
end

function WhipBomb:GetShowHitIndicator()
    return false
end

Shared.LinkClassToMap("WhipBomb", WhipBomb.kMapName, networkVars)