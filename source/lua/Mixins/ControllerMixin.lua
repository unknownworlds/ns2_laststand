// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ControllerMixin.lua
//
//    Created by:   Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Vector.lua")

ControllerMixin = CreateMixin( ControllerMixin )
ControllerMixin.type = "Controller"

// The controller uses a 0.1m thick "skin" around it to handle collisions properly
local kSkinOffset = 0.1
        
ControllerMixin.expectedCallbacks =
{
    GetControllerSize = "Should return a height and radius",
    GetMovePhysicsMask = "Should return a mask for the physics groups to collide with"
}

function ControllerMixin:__initmixin()
    self.controller = nil
end

function ControllerMixin:OnDestroy()
    self:DestroyController()
end

function ControllerMixin:CreateController(physicsGroup)

    assert(self.controller == nil)
    
    self.controller = Shared.CreateCollisionObject(self)
    self.controller:SetGroup(physicsGroup)
    self.controller:SetTriggeringEnabled( true )
    
    self.controllerVerticalOffset = 0

    // Make the controller kinematic so physically simulated objects will
    // interact/collide with it.
    self.controller:SetPhysicsType(CollisionObject.Kinematic)
    
    self:UpdateControllerFromEntity()

end

function ControllerMixin:DestroyController()

    if self.controller ~= nil then
    
        Shared.DestroyCollisionObject(self.controller)
        self.controller = nil
        
    end
    
end

function ControllerMixin:SetControllerVerticalOffset(offset)

    assert(type(offset) == "number")
    
    if offset ~= self.controllerVerticalOffset then
    
        local move = Vector(0, offset - self.controllerVerticalOffset, 0)
        local trace = self.controller:Trace(move, CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())
        
        if trace.fraction == 1 then
            self.controllerVerticalOffset = offset
        end
        
    end
    
end

/**
 * Synchronizes the origin and shape of the physics controller with the current
 * state of the entity.
 */
local origin = Vector()
function ControllerMixin:UpdateControllerFromEntity(allowTrigger)

    PROFILE("ControllerMixin:UpdateControllerFromEntity")

    if allowTrigger == nil then
        allowTrigger = true
    end

    if self.controller ~= nil then
    
        local controllerHeight, controllerRadius = self:GetControllerSize()
        
        if controllerHeight ~= self.controllerHeight or controllerRadius ~= self.controllerRadius then
        
            self.controllerHeight = controllerHeight
            self.controllerRadius = controllerRadius
        
            local capsuleHeight = controllerHeight - 2*controllerRadius
        
            if capsuleHeight < 0.001 then
                // Use a sphere controller
                self.controller:SetupSphere( controllerRadius, self.controller:GetCoords(), allowTrigger )
            else
                // A flat bottomed cylinder works well for movement since we don't
                // slide down as we walk up stairs or over other lips. The curved
                // edges of the cylinder allows players to slide off when we hit them,
                self.controller:SetupCapsule( controllerRadius, capsuleHeight, self.controller:GetCoords(), allowTrigger )
                // self.controller:SetupCylinder( controllerRadius, controllerHeight, self.controller:GetCoords(), allowTrigger )
            end                
            
            // Remove all collision reps except movement from the controller.
            for value,name in pairs(CollisionRep) do
                if value ~= CollisionRep.Move and type(name) == "string" then
                    self.controller:RemoveCollisionRep(value)
                end
            end
            
            self.controller:SetTriggeringCollisionRep(CollisionRep.Move)
            self.controller:SetPhysicsCollisionRep(CollisionRep.Move)
 
        end
        
        // The origin of the controller is at its center and the origin of the
        // player is at their feet, so offset it.
        VectorCopy(self:GetOrigin(), origin)
        origin.y = origin.y + self.controllerHeight * 0.5 + kSkinOffset + self.controllerVerticalOffset
        
        self.controller:SetPosition(origin, allowTrigger)
        
    end
    
end


/**
 * Synchronizes the origin of the entity with the current state of the physics
 * controller.
 */
function ControllerMixin:UpdateOriginFromController()

    // The origin of the controller is at its center and the origin of the
    // player is at their feet, so offset it.
    local origin = Vector(self.controller:GetPosition())
    origin.y = origin.y - self.controllerHeight * 0.5 - kSkinOffset - self.controllerVerticalOffset
    
    self:SetOrigin(origin)
    
end

function ControllerMixin:OnUpdatePhysics()
    
    if HasMixin(self, "Live") and not self:GetIsAlive() then
        self:DestroyController()
    end

    self:UpdateControllerFromEntity()
end

/** 
 * Returns true if the entity is colliding with anything that passes its movement
 * mask at its current position.
 */
function ControllerMixin:GetIsColliding()

    PROFILE("ControllerMixin:GetIsColliding")

    if self.controller then
        self:UpdateControllerFromEntity()
        return self.controller:Test(CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())
    end
    
    return false

end

/**
 * Moves by the player by the specified offset, colliding and sliding with the world.
 */
function ControllerMixin:PerformMovement(offset, maxTraces, velocity, isMove)

    PROFILE("ControllerMixin:PerformMovement")
    
    if isMove == nil then
        isMove = true
    end
    
    local hitEntities = nil
    local completedMove = true
    local averageSurfaceNormal = nil
    
    if self.controller then
    
        self:UpdateControllerFromEntity()
        
        local tracesPerformed = 0
        
        while offset:GetLengthSquared() > 0.0 and tracesPerformed < maxTraces do
        
            local trace = self.controller:Move(offset, CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())
            
            if trace.fraction < 1 then

                // Remove the amount of the offset we've already moved.
                offset = offset * (1 - trace.fraction)
                
                // Make the motion perpendicular to the surface we collided with so we slide.
                offset = offset - offset:GetProjection(trace.normal) + trace.normal*0.001
                
                // Redirect velocity if specified
                if velocity ~= nil then
                
                    // Scale it according to how much velocity we lost
                    local newVelocity = velocity - velocity:GetProjection(trace.normal) + trace.normal*0.001
                    
                    // Copy it so it's changed for caller
                    VectorCopy(newVelocity, velocity)
                    
                end
                
                if not averageSurfaceNormal then
                    averageSurfaceNormal = Vector(trace.normal)
                else
                
                    averageSurfaceNormal = averageSurfaceNormal + trace.normal
                    if averageSurfaceNormal:GetLength() > 0 then
                        averageSurfaceNormal:Normalize()
                    end
                
                end
                
                // Defer the processing of the callbacks until after we've finished moving,
                // since the callbacks may modify our self an interfere with our loop
                if trace.entity ~= nil and trace.entity.OnCapsuleTraceHit ~= nil then
                
                    if hitEntities == nil then
                        hitEntities = { trace.entity }
                    else
                        table.insert(hitEntities, trace.entity)
                    end

                end
                
                completedMove = false
                
            else
                offset = Vector(0, 0, 0)
            end
            
            tracesPerformed = tracesPerformed + 1
            
        end
        
        if isMove then
            self:UpdateOriginFromController()
        end
        
    end
    
    // Do the hit callbacks.
    if hitEntities and isMove then
    
        for index, entity in ipairs(hitEntities) do
        
            entity:OnCapsuleTraceHit(self)
            self:OnCapsuleTraceHit(entity)
            
        end
        
    end
    
    return completedMove, hitEntities, averageSurfaceNormal
    
end
