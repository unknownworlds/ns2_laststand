// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/ObjectiveInfo.lua
//
//      Created by: Andreas Urwalek (andi@unknownworlds.com)
//
//      Holds information about objective status (hive/CC) for UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")

class 'ObjectiveInfo' (Entity)

ObjectiveInfo.kMapName = "objectiveinfo"

local networkVars =
{
    healthScalar = "float (0 to 1 by 0.01)",
    techId = "enum kTechId",
    inCombat = "boolean",
    locationId  = "resource",
}

AddMixinNetworkVars(TeamMixin, networkVars)

function ObjectiveInfo:OnCreate()

    Entity.OnCreate(self)
    
    self:SetUpdates(true)

    self.techId = kTechId.None
    self.healthScalar = 1.0
    self.ownerEntityId = Entity.invalidId
    self.inCombat = false
    self.locationId = 0
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
    InitMixin(self, TeamMixin)
    
end

function ObjectiveInfo:UpdateRelevancy()
    self:SetRelevancyDistance(Math.infinity)
end

function ObjectiveInfo:SetOwner(ownerId)
    self.ownerEntityId = ownerId
end

function ObjectiveInfo:GetOwner()
    return Shared.GetEntity(self.ownerEntityId)
end

function ObjectiveInfo:GetIsInCombat()
    return self.inCombat
end

function ObjectiveInfo:GetHealthScalar()
    return self.healthScalar
end

function ObjectiveInfo:GetTechId()
    return self.techId
end

function ObjectiveInfo:GetLocationName()

    local locationName = ""
    
    if self.locationId ~= 0 then
        locationName = Shared.GetString(self.locationId)
    end
    
    return locationName
    
end

if Server then

    function ObjectiveInfo:OnUpdate(deltaTime)
    
        PROFILE("ObjectiveInfo:Update")
        
        Entity.OnUpdate(self, deltaTime)
        
        local owner = self:GetOwner()
        assert(owner)
        
        self.inCombat = owner:GetIsAlive() and owner:GetIsInCombat()
        self.techId = owner:GetTechId()
        self.healthScalar = owner:GetHealthScalar()
        self.locationId = owner:GetLocationId()
        
    end
    
end

Shared.LinkClassToMap( "ObjectiveInfo", ObjectiveInfo.kMapName, networkVars)