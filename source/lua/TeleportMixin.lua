// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TeleportMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Teleports the entity with a delay to a destination entity. If the destination entity has an
//    active order it will spawn at the order location, unless it does not require to be attached.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

TeleportMixin = CreateMixin( TeleportMixin )
TeleportMixin.type = "TeleportAble"

TeleportMixin.kDefaultDelay = 3
TeleportMixin.kMaxRange = 4.5
TeleportMixin.kMinRange = 1
TeleportMixin.kAttachRange = 15
TeleportMixin.kDefaultSinkin = 1.4

TeleportMixin.optionalCallbacks = {

    OnTeleport = "Called when teleport is triggered.",
    OnTeleportEnd = "Called when teleport is done.",
    GetCanTeleportOverride = "Return true/false to allow/prevent teleporting."
    
}

TeleportMixin.networkVars = {
 
    isTeleporting = "boolean",
    teleportDelay = "float"
    
}

function TeleportMixin:__initmixin()

    self.maxCatalystStacks = TeleportMixin.kDefaultStacks

    if Client then
    
        self.clientIsTeleporting = false
        
    elseif Server then
    
        self.isTeleporting = false
        self.destinationEntityId = Entity.invalidId
        self.timeUntilPort = 0
        self.teleportDelay = 0
        
    end
    
end

function TeleportMixin:GetTeleportSinkIn()

    if self.OverrideGetTeleportSinkin then
        return self:OverrideGetTeleportSinkin()
    end
    
    if HasMixin(self, "Extents") then
        return self:GetExtents().y * 2.5
    end    
    
    return TeleportMixin.kDefaultSinkin
    
end   

function TeleportMixin:GetCanTeleport()

    local canTeleport = true
    if self.GetCanTeleportOverride then
        canTeleport = self:GetCanTeleportOverride()
    end
    
    return canTeleport and not self.isTeleporting
    
end

/**
 * Forbid the update of model coordinates while we teleport(?)
 */
function TeleportMixin:GetForbidModelCoordsUpdate()
    return self.isTeleporting
end

function TeleportMixin:UpdateTeleportClientEffects(deltaTime)

    if self.clientIsTeleporting ~= self.isTeleporting then
    
        self:TriggerEffects("teleport_start", { effecthostcoords = self:GetCoords(), classname = self:GetClassName() })
        self.clientIsTeleporting = self.isTeleporting
        self.clientTimeUntilPort = self.teleportDelay
        
    end
    
    local renderModel = self:GetRenderModel()
    
    if renderModel then
    
        self.clientTimeUntilPort = math.max(0, self.clientTimeUntilPort - deltaTime)

        local sinkCoords = self:GetCoords()
        local teleportFraction = 1 - (self.clientTimeUntilPort / self.teleportDelay)

        sinkCoords.origin = sinkCoords.origin - teleportFraction * self:GetTeleportSinkIn() * sinkCoords.yAxis
        renderModel:SetCoords(sinkCoords)

    end

end

local function GetAttachDestination(self, attachTo, destinationOrigin)

    local attachEntities = GetEntitiesWithinRange(attachTo, destinationOrigin, TeleportMixin.kAttachRange)
    
    if #attachEntities > 0 and not attachEntities[1]:GetAttached() and GetInfestationRequirementsMet(self:GetTechId(), attachEntities[1]:GetOrigin()) then
    
        // free up old attached entity and attach to new
        local attached = self:GetAttached()
        
        attached:ClearAttached()
        self:ClearAttached()
        
        self:SetAttached(attachEntities[1])
        
        local attachCoords = attachEntities[1]:GetCoords()
        attachCoords.origin.y = attachCoords.origin.y + LookupTechData(self:GetTechId(), kTechDataSpawnHeightOffset, 0)
        
        return attachCoords
        
    end

end

local function GetRandomSpawn(self, destinationOrigin)

    local extents = self:GetExtents()
    local randomSpawn = nil
    local requiresInfestation = LookupTechData(self:GetTechId(), kTechDataRequiresInfestation, false)
    
    for i = 1, 25 do
    
        randomSpawn = GetRandomSpawnForCapsule(extents.y, extents.x, destinationOrigin, TeleportMixin.kMinRange, TeleportMixin.kMaxRange)
        if randomSpawn and GetInfestationRequirementsMet(self:GetTechId(), randomSpawn) then
            randomSpawn = GetGroundAtPosition(randomSpawn, nil, PhysicsMask.CommanderBuild) //, self:GetExtents())
            return Coords.GetTranslation(randomSpawn)
        end
        
    end

end

local function PerformTeleport(self)

    local destinationEntity = Shared.GetEntity(self.destinationEntityId)
    
    if destinationEntity then

        local destinationCoords = nil        
        local attachTo = LookupTechData(self:GetTechId(), kStructureAttachClass, nil)
        
        // find a free attach entity
        if attachTo then
            destinationCoords = GetAttachDestination(self, attachTo, self.destinationPos)
        else
            destinationCoords = Coords.GetTranslation(self.destinationPos)
        end
        
        if destinationCoords then
        
            /*
            if HasMixin(self, "Obstacle") then
                Print("remove from mesh")
                self:RemoveFromMesh()
            end
            */
        
            self:SetCoords(destinationCoords)
            
            /*
            if HasMixin(self, "Obstacle") then
                Print("Add to mesh")
                self:AddToMesh()
            end
            */
            
            local location = GetLocationForPoint(self:GetOrigin())
            local locationName = location and location:GetName() or ""
            
            self:SetLocationName(locationName, true)
            
            self:TriggerEffects("teleport_end", { classname = self:GetClassName() })
            
            if self.OnTeleportEnd then
                self:OnTeleportEnd(destinationEntity)
            end

        else
            // teleport has failed, give back resources to shift

            if destinationEntity then
                destinationEntity:GetTeam():AddTeamResources(self.teleportCost)
            end
        
        end
    
    end
    
    self.destinationEntityId = Entity.invalidId
    self.isTeleporting = false
    self.timeUntilPort = 0
    self.teleportDelay = 0

end 

local function SharedUpdate(self, deltaTime)

    if Server then
    
        if self.isTeleporting then 
  
            self.timeUntilPort = math.max(0, self.timeUntilPort - deltaTime)
            if self.timeUntilPort == 0 then
                PerformTeleport(self)
            end
            
        end
    
    elseif Client then
    
        if self.isTeleporting then        
            self:UpdateTeleportClientEffects(deltaTime)
         
        elseif self.clientIsTeleporting then        
            self.clientIsTeleporting = false            
        end 
        
    end


end

function TeleportMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function TeleportMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function TeleportMixin:TriggerTeleport(delay, destinationEntityId, destinationPos, cost)

    if Server then
    
        self.teleportDelay = ConditionalValue(delay, delay, TeleportMixin.kDefaultDelay)
        self.timeUntilPort = ConditionalValue(delay, delay, TeleportMixin.kDefaultDelay)
        self.destinationEntityId = destinationEntityId
        self.destinationPos = destinationPos
        self.isTeleporting = true
        self.teleportCost = cost
        
        //Print("%s:TriggerTeleport ", self:GetClassName())
        
        if self.OnTeleport then
            self:OnTeleport()
        end    
        
    end
    
end

function TeleportMixin:OnUpdateAnimationInput(modelMixin)

    modelMixin:SetAnimationInput("isTeleporting", self.isTeleporting)

end

