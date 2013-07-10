// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OwnerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * OwnerMixin gives an Entity the ability to own other Entities or
 * to be owned by another Entity. One Entity can only be owned by
 * one other Entity. But one Entity can own multiple Entities.
 */
OwnerMixin = CreateMixin( OwnerMixin )
OwnerMixin.type = "Owner"

OwnerMixin.optionalCallbacks =
{
    OnOwnerChanged = "Will be called when the owner has changed with the old owner and the new owner objects."
}

function OwnerMixin:__initmixin()

    // Only intended to be used on the Server.
    assert(Server)
    
    self.ownerId = Entity.invalidId
    // Stores all the entities that are owned by this ScriptActor.
    self.ownedEntities = { }
    
end

/**
 * Sets whether the OwnerMixin is or isn't the owner of the passed in entity.
 * This is needed for proper destruction.
 */
local function SetIsOwner(owner, ofEntity, isOwner)

    if isOwner then
        table.insert(owner.ownedEntities, ofEntity)
    else
        table.removevalue(owner.ownedEntities, ofEntity)
    end
    
end

function OwnerMixin:SetOwner(newOwner)

    assert(self ~= newOwner)
    assert(not self:GetIsDestroyed())
    assert(not newOwner or not newOwner:GetIsDestroyed())
    
    local currentOwner = Shared.GetEntity(self.ownerId)
    if currentOwner then
        SetIsOwner(currentOwner, self, false)
    end
    
    if newOwner == nil then
        self.ownerId = Entity.invalidId
    else
    
        assert(HasMixin(newOwner, "Owner"))
        
        self.ownerId = newOwner:GetId()
        SetIsOwner(newOwner, self, true)
        
    end
    
    // Announce this ownership change to the world.
    if self.OnOwnerChanged then
        self:OnOwnerChanged(currentOwner, newOwner)
    end
    
end

function OwnerMixin:GetOwner()
    return Shared.GetEntity(self.ownerId)
end

/**
 * Called when a entity changes into another entity (players changing classes) or
 * when an entity is destroyed. When an entity is destroyed, newId will be nil.
 */
function OwnerMixin:OnEntityChange(oldId, newId)

    if self.ownerId == oldId then
    
        if newId then
            self:SetOwner(Shared.GetEntity(newId))
        else
            self:SetOwner(nil)
        end
        
    end
    
end

function OwnerMixin:OnDestroy()
    
    // Remove all owned entities.
    // Must copy this list as it will be modified during iteration.
    local ownedEntitiesCopy = { }
    for i, ownedEnt in ipairs(self.ownedEntities) do
        table.insert(ownedEntitiesCopy, ownedEnt)
    end
    table.foreachfunctor(ownedEntitiesCopy, function(entity) entity:SetOwner(nil) end)
    table.clear(self.ownedEntities)
    
    self:SetOwner(nil)
    
end