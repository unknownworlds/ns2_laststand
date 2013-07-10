// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ClogFallMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ClogFallMixin keeps track of attached structures and let them drop to the ground once self is destroyed/killed
// Use server side only
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

ClogFallMixin = CreateMixin( ClogFallMixin )
ClogFallMixin.type = "ClogFall"

local kClogFallSpeed = 5

ClogFallMixin.optionalCallbacks =
{
    OnClogFall = "Called when clog fall starts.",
    OnClogFallDone = "Called when we reached the ground, param 'isAttached'."
}

ClogFallMixin.networkVars =
{
}

function ClogFallMixin:__initmixin()

    assert(Server)
    self.isClogFalling = false
    self.fallDestinationY = self:GetOrigin().y
    self.attachedClogIds = {}
    self.clogParentId = Entity.invalidId
    self.surfaceNormal = Vector(0, 1, 0)
    
end

function ClogFallMixin:OnDestroy()

    for _, attachedId in ipairs(self.attachedClogIds) do
    
        local entity = Shared.GetEntity(attachedId)
        if entity and HasMixin(entity, "ClogFall") then
            entity:TriggerClogFall()
        end
    
    end

end

function ClogFallMixin:GetIsFalling()
    return self.isClogFalling
end

function ClogFallMixin:OnEntityChange(oldId, newId)

    if oldId == self.clogParentId then
        self.clogParentId = Entity.invalidId
    elseif oldId == self.destinationEntityId then
        self.destinationEntityId = nil 
    else

        // TODO: check childs
        
    end
end

function ClogFallMixin:ConnectToClog(structure)

    table.insert(self.attachedClogIds, structure:GetId())
    structure.clogParentId = self:GetId()

end

function ClogFallMixin:RemoveAttachedClog(structure)
    table.removevalue(self.attachedClogIds, structure:GetId())
end

function ClogFallMixin:TriggerClogFall()

    PROFILE("ClogFallMixin:TriggerClogFall")

    // clear attached
    if self.clogParentId and self.clogParentId ~= Entity.invalidId then
    
        local parentClog = Shared.GetEntity(self.clogParentId)
        if parentClog and HasMixin(parentClog, "ClogFall") then
            parentClog:RemoveAttachedClog(self)
        end
        
        self.clogParentId = Entity.invalidId
        
    end
    
    // trace to ground for destination pos
    local origin = self:GetOrigin()
    local trace = Shared.TraceRay(Vector(origin.x, origin.y + 0.4, origin.z), Vector(origin.x, origin.y - 100, origin.z), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    if trace.fraction ~= 1 then
    
        self.fallDestinationY = trace.endPoint.y
        self.destinationEntityId = trace.entity ~= nil and trace.entity:GetId()
        self.isClogFalling = true
        self.surfaceNormal = trace.normal
        
        // TriggerClogFall for childs which are below us, they will unattach then (otherwise fall through the world)
        for _, attachedId in ipairs(self.attachedClogIds) do
        
            local entity = Shared.GetEntity(attachedId)
            if entity and HasMixin(entity, "ClogFall") then
            
                local verticalDistance = entity:GetOrigin().y - self:GetOrigin().y
                if verticalDistance < 0.4 then
                    entity:TriggerClogFall()
                end
                
            end
            
        end
        
        if self.OnClogFall then
            self:OnClogFall(self.surfaceNormal)
        end
        
    else
        Print("ClogFallMixin:TriggerClogFall: could not find ground")
    end
    
end

// applies deltaVec recursive to any attached objects
function ClogFallMixin:AddClogFall(deltaMove)

    local origin = self:GetOrigin()
    origin.y = origin.y + deltaMove
    self:SetOrigin(origin)
    
    for _, attachedId in ipairs(self.attachedClogIds) do
    
        local entity = Shared.GetEntity(attachedId)
        if entity and HasMixin(entity, "ClogFall") then
            entity:AddClogFall(deltaMove)
        end
        
    end
    
    if deltaMove == 0 then
    
        self.isClogFalling = false
        
        self:TriggerEffects("structure_land", {effecthostcoords = Coords.GetTranslation(self:GetOrigin())})
        
        if not self.clogParentId or self.clogParentId == Entity.invalidId then
        
            // attach us to the clog we landed
            local attachToClog = self.destinationEntityId and Shared.GetEntity(self.destinationEntityId)
            if attachToClog and attachToClog:isa("Clog") then
            
                attachToClog:ConnectToClog(self)
                self.destinationEntityId = nil
                
            end
        
        end
        
        if self.OnClogFallDone then
            self:OnClogFallDone(self.clogParentId and self.clogParentId ~= Entity.invalidId, self.surfaceNormal)
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    if self.isClogFalling then
    
        local deltaMove = deltaTime * kClogFallSpeed
        deltaMove = math.max(self.fallDestinationY, self:GetOrigin().y - deltaMove )
        deltaMove = deltaMove - self:GetOrigin().y
        
        self:AddClogFall(deltaMove)
        
    end
    
end

function ClogFallMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(ClogFallMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function ClogFallMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(ClogFallMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })