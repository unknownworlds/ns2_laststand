// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\Mixins\SimplePhysicsMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

SimplePhysicsMixin = { }
SimplePhysicsMixin.type = "BaseMove"

kSimplePhysicsBodyType = enum({'Sphere', 'Cylinder', 'Box'})

SimplePhysicsMixin.optionalCallbacks =
{
    GetPhysicsBodyType = "Return kSimplePhysicsBodyType.",
}

SimplePhysicsMixin.expectedCallbacks =
{
    GetSimplePhysicsBodyType = "Required to define type of body.",
    GetSimplePhysicsBodySize = "Required to define size of body.",
}

SimplePhysicsMixin.networkVars =
{
}

local function DestroyPhysics(self)

    if self.simplePhysicsBody then
    
        Shared.DestroyCollisionObject(self.simplePhysicsBody)    
        self.simplePhysicsBody = nil
        
    end

end

local function UpdatePhysics(self)

    if not self.simplePhysicsBody and self.simplePhysicsEnabled then
    
        local type = self:GetSimplePhysicsBodyType()
        local size = self:GetSimplePhysicsBodySize()
        
        if type == kSimplePhysicsBodyType.Sphere then
            self.simplePhysicsBody = Shared.CreatePhysicsSphereBody(true, size, 0, self:GetCoords())
            
        elseif type == kSimplePhysicsBodyType.Box then
            self.simplePhysicsBody = Shared.CreatePhysicsBoxBody(true, size, 0, self:GetCoords())
        
        end

        self.simplePhysicsBody:SetEntity(self)
        self.simplePhysicsBody:SetPhysicsType(CollisionObject.Dynamic)
        self.simplePhysicsBody:SetTriggeringEnabled(true)
    
    end
    
    if self.simplePhysicsBody then
        self.simplePhysicsBody:SetCoords(self:GetCoords())
    end

end

function SimplePhysicsMixin:__initmixin() 

    self.simplePhysicsEnabled = true
    UpdatePhysics(self)   
    
    self.collisionRep = CollisionRep.Default
    self.physicsGroup = PhysicsGroup.DefaultGroup
    self.physicsGroupFilterMask = PhysicsMask.None
    
    self:SetPhysicsGroup(self.physicsGroup)
    self:SetPhysicsGroupFilterMask(self.physicsGroupFilterMask)
    
end

function SimplePhysicsMixin:SetSimplePhysicsEnabled(enabled)
    
    self.simplePhysicsEnabled = enabled
    
    if not enabled then
        DestroyPhysics(self)
    end
    
end

function SimplePhysicsMixin:OnDestroy()
    
    if self.simplePhysicsBody then
    
        Shared.DestroyCollisionObject(self.simplePhysicsBody)    
        self.simplePhysicsBody = nil
        
    end
    
end

function SimplePhysicsMixin:SetPhysicsGroup(physicsGroup)

    self.physicsGroup = physicsGroup
    if self.simplePhysicsBody then
        self.simplePhysicsBody:SetGroup(physicsGroup)
    end

end

function SimplePhysicsMixin:SetPhysicsGroupFilterMask(physicsGroupFilterMask)

    self.physicsGroupFilterMask = physicsGroupFilterMask
    
    if self.simplePhysicsBody then
        self.simplePhysicsBody:SetGroupFilterMask(physicsGroupFilterMask)
    end
    
end

// use simple bodies
function SimplePhysicsMixin:GetPhysicsModelAllowed()
    return false
end

function SimplePhysicsMixin:OnUpdate(deltaTime)
    UpdatePhysics(self)    
end
