// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/PhysicsGroups.lua")

/**
 * Sets the linear velocity of the projectile in world space.
 */
function Projectile:SetVelocity(velocity)

    self.desiredVelocity = velocity
    self.physicsBody:SetLinearVelocity(velocity)
    self.lastVelocity = velocity
    
end

/**
 * Creates the physics representation for the projectile (if necessary).
 */
 
function Projectile:GetPhysicsGroup()
    return PhysicsGroup.ProjectileGroup
end
 
function Projectile:CreatePhysics()

    if self.physicsBody == nil then
    
        self.physicsBody = Shared.CreatePhysicsSphereBody(true, self.radius, self.mass, self:GetCoords())
        self.physicsBody:SetGravityEnabled(true)
        self.physicsBody:SetGroup(self:GetPhysicsGroup())
        self.physicsBody:SetEntity(self)
        // Projectiles need to have continuous collision detection so they
        // don't tunnel through walls and other objects.
        self.physicsBody:SetCCDEnabled(true)
        self.physicsBody:SetPhysicsType(CollisionObject.Dynamic)
        self.physicsBody:SetLinearDamping(self.linearDamping)
        self.physicsBody:SetRestitution(self.restitution)
        
        if self.groupFilterMask then
            self.physicsBody:SetGroupFilterMask(self.groupFilterMask)
        end
        
    end
    
end

function Projectile:SetGravityEnabled(state)

    if self.physicsBody then
        self.physicsBody:SetGravityEnabled(state)
    else
        Print("%s:SetGravityEnabled(%s) - Physics body is nil.", self:GetClassName(), tostring(state))
    end
    
end        

/**
 * Called when the projectile collides with something. Can be overridden by
 * derived classes.
 */
function Projectile:ProcessHit(entityHit)
end

/**
 * Adjust the initial position of the projectile according to the setup
 */
function Projectile:AdjustInitial(setup)

    // We adjust the position of the projectile to compensate for the time
    // between createTime and now. 
    
    local dt = math.max(0, Shared.GetTime() - setup.createTime)
    // adjust for velocity since creation
    local startPoint = self:GetOrigin()
    local velocity = setup.velocity
    local endPoint = startPoint + velocity * dt 
    local diff = endPoint - startPoint
    if setup.gravityEnabled then
        // adjust for gravity: position
        local y = dt * setup.velocity.y - 9.81 * dt * dt / 2
        local x = dt * setup.velocity.x
        local z = dt * setup.velocity.z
        // adjust for gravity: velocity
        velocity.y = velocity.y - dt * 9.81
        diff = Vector(x,y,z)
        endPoint = startPoint + diff
    end
    
    // trace from origin to endpoint to avoid teleporting through stuff
    local trace = Shared.TraceBox(setup.extents, startPoint, endPoint,  CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self:GetOwner()))
   
    endPoint = trace.endPoint
    
    // finally, update us to the correct position       
    self:SetOrigin(endPoint)
    self:CreatePhysics()
    self:SetVelocity(velocity)
    self:SetGravityEnabled(setup.gravityEnabled)

end

function Projectile:GetSimulatePhysics()
    return true
end

function Projectile:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if not self:GetSimulatePhysics() then
        if self.physicsBody then
            Shared.DestroyCollisionObject(self.physicsBody)
            self.physicsBody = nil
        end
        return            
    end
  
    // don't quite know why this is here...
    // self:CreatePhysics() 
    
    // If the projectile has moved outside of the world, destroy it
    local coords = self.physicsBody:GetCoords()

    // Update the position/orientation of the entity based on the current
    // position/orientation of the physics object.
    self:SetCoords(coords)

    // If we move the projectile outside the valid bounds of the world, it will get
    // destroyed so we need to check for that to avoid errors.
    if self:GetIsDestroyed() then
        return
    end
    
    // DL: Workaround for bouncing projectiles. Detect a change in velocity and find the impacted object
    // by tracing a ray from the last frame's origin.
    local velocity = self.physicsBody:GetLinearVelocity()
    local origin = self:GetOrigin()

    if self.lastVelocity ~= nil then

        local delta = velocity - self.lastVelocity
        // if we have hit something that slowed us down in xz direction, or if we are standing still, we explode
        if delta:GetLengthSquaredXZ() > 0.0001 or velocity:GetLength() < 0.0001 then                    

            local endPoint = self.lastOrigin + self.lastVelocity * (deltaTime + self.radius * 3)
            local trace = Shared.TraceCapsule(self.lastOrigin, endPoint, self.radius, 0, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self))

            self:SetOrigin(trace.endPoint)
            if trace.fraction == 0 or trace.fraction == 1 then
                trace.normal = Vector(0, 1, 0)
            end
            self:ProcessHit(trace.entity, trace.surface, trace.normal)

        end

    end
    
    self.lastVelocity = velocity
    self.lastOrigin = origin
    
end

function Projectile:SetOrientationFromVelocity()

    // Set orientation according to velocity
    local velocity = self:GetVelocity()
    if velocity:GetLengthSquared() > 0.01 and self.physicsBody then
        self:SetCoords( Coords.GetLookIn( self:GetOrigin(), velocity ) )
    end
    
end

function Projectile:SetOwner(player)

    // Make sure the owner cannot collide with the projectile
    if player ~= nil and self.physicsBody and player:GetController() then
        Shared.SetPhysicsObjectCollisionsEnabled(self.physicsBody, player:GetController(), false)
    end
    
end

// Creates projectile on our team 1 meter in front of player
function CreateViewProjectile(mapName, player)   

    local viewCoords = player:GetViewAngles():GetCoords()
    local startPoint = player:GetEyePos() + viewCoords.zAxis
    
    local projectile = CreateEntity(mapName, startPoint, player:GetTeamNumber())
    SetAnglesFromVector(projectile, viewCoords.zAxis)
    
    // Set owner to player so we don't collide with ourselves and so we
    // can attribute a kill to us
    projectile:SetOwner(player)
    
    return projectile
    
end

// Register for callbacks when projectiles collide with the world
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, 0)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.DefaultGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.BigStructuresGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.SmallStructuresGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.PlayerControllersGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.CommanderPropsGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.AttachClassGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.CommanderUnitGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.CollisionGeometryGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.ProjectileGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.ProjectileGroup, PhysicsGroup.WhipGroup)