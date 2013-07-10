// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/OwnerMixin.lua")

class 'Projectile' (ScriptActor)

Projectile.kMapName = "projectile"

local networkVars = { }

if Server then
    Script.Load("lua/Weapons/Projectile_Server.lua")
else
    Script.Load("lua/Weapons/Projectile_Client.lua")
end

function Projectile:OnCreate()

    ScriptActor.OnCreate(self)
    
    self.radius = 0.1
    self.mass = 1.0
    self.linearDamping = 0
    self.restitution = 0.5
    
    if Client then
        self.oldModelIndex = 0
    end
    
end

function Projectile:OnInitialized()
    if Client then
        // save the initial origin so we know when to show the model
        self.initOrigin = self:GetOrigin()
    end
end

/**
 * Must be called when setting up the projectile.
 * The velocity must not be set directly.
 */
function Projectile:Setup(player, velocity, gravityEnabled, extents, triggeringEnt)

    assert(Server)

    if player then
        self:SetOwner(player)
    end
    
    if triggeringEnt and HasMixin(triggeringEnt, "Relevancy") then
        self:SetExcludeRelevancyMask(triggeringEnt:GetExcludeRelevancyMask())
    end
    
    local setup = {}
    setup.velocity = velocity
    setup.gravityEnabled = gravityEnabled
    setup.createTime = Shared.GetTime()
    setup.extents = extents or Vector(0.05,0.05,0.05)
   
    self:AdjustInitial(setup)
    self.creationTime = setup.createTime

    if self.GetProjectileModel then
        self:SetModel(self:GetProjectileModel())
    end

end

function Projectile:OnDestroy()

    ScriptActor.OnDestroy(self)

    if Server then
    
        if self.physicsBody then
            Shared.DestroyCollisionObject(self.physicsBody)
            self.physicsBody = nil
        end
        
    elseif Client then
    
        // Destroy the render model.
        if self.renderModel then
            Client.DestroyRenderModel(self.renderModel)
            self.renderModel = nil
        end
        
    end

end

function Projectile:GetVelocity()
    if self.physicsBody then
        return self.physicsBody:GetLinearVelocity()
    end
    return Vector(0, 0, 0)
end

/**
 * Projectile manages it's own physics body and doesn't require
 * a physics model from Actor.
 */
function Projectile:GetPhysicsModelAllowedOverride()
    return false
end

function Projectile:SetGroupFilterMask(groupFilterMask)

    self.groupFilterMask = groupFilterMask
    if self.physicsBody then
        return self.physicsBody:SetGroupFilterMask(groupFilterMask)
    end
    
end

// Dropped weapons depend on this also
Shared.LinkClassToMap("Projectile", Projectile.kMapName, networkVars)
