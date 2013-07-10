// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/MapBlip.lua
//
// MapBlips are displayed on player minimaps based on relevancy.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'MapBlip' (Entity)

MapBlip.kMapName = "MapBlip"

local networkVars =
{
    // replace m_origin with a less precise version lacking y
    m_origin = "interpolated position (by 0.2 [2 3 5], by 1000 [0 0 0], by 0.2 [2 3 5])",
    // replace m_angles with a less precise version lacking roll and pitch (range is 0-2pi, -> 0.1 = 6 bits)
    m_angles = "interpolated angles (by 10 [0], by 0.1 [3], by 10 [0])",
    mapBlipType = "enum kMinimapBlipType",
    mapBlipTeam = "integer (" .. ToString(kTeamInvalid) .. " to " .. ToString(kSpectatorIndex) .. ")",
    ownerEntityId = "entityid",
    isInCombat = "boolean"
}

function MapBlip:OnCreate()

    Entity.OnCreate(self)
    
    // Prevent let the engine from calling OnSynchronize or OnUpdate for improved performance
    // since we create a lot of map blips.
    self:SetUpdates(false)
    
    self:SetOrigin(Vector(0,0,0))
    self:SetAngles(Angles(0,0,0))
    self.mapBlipType = kMinimapBlipType.TechPoint
    self.mapBlipTeam = kTeamReadyRoom
    self.ownerEntityId = Entity.invalidId
    self.isInCombat = false
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function MapBlip:UpdateRelevancy()

    self:SetRelevancyDistance(Math.infinity)
    
    local mask = 0
    
    if self.mapBlipType == kMinimapBlipType.Infestation or self.mapBlipType == kMinimapBlipType.InfestationDying then
        mask = bit.bor(mask, kRelevantToTeam2)
    else    
    
        if self.mapBlipTeam == kTeam1Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
            mask = bit.bor(mask, kRelevantToTeam1)
        end
        if self.mapBlipTeam == kTeam2Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
            mask = bit.bor(mask, kRelevantToTeam2)
        end
    
    end
    
    self:SetExcludeRelevancyMask( mask )

end

function MapBlip:SetOwner(ownerId, blipType, blipTeam)

    self.ownerEntityId = ownerId
    self.mapBlipType = blipType
    self.mapBlipTeam = blipTeam
    
    self:Update()

end

function MapBlip:GetOwnerEntityId()

    return self.ownerEntityId

end

function MapBlip:GetType()

    return self.mapBlipType

end

function MapBlip:GetTeamNumber()

    return self.mapBlipTeam

end

function MapBlip:GetRotation()

    return self:GetAngles().yaw

end

function MapBlip:GetIsSighted()

    local owner = Shared.GetEntity(self.ownerEntityId)
    
    if owner then
    
        if owner.GetTeamNumber and owner:GetTeamNumber() == kTeamReadyRoom and owner:GetAttached() then
            owner = owner:GetAttached()
        end
        
        return HasMixin(owner, "LOS") and owner:GetIsSighted() or false
        
    end
    
    return false
    
end

function MapBlip:GetIsInCombat()
    return self.isInCombat
end

// Called (server side) when a mapblips owner has changed its map-blip dependent state
function MapBlip:Update()

    PROFILE("MapBlip:Update")

    if self.ownerEntityId and Shared.GetEntity(self.ownerEntityId) then
    
        local owner = Shared.GetEntity(self.ownerEntityId)
        
        local fowardNormal = owner:GetCoords().zAxis
        local yaw = math.atan2(fowardNormal.x, fowardNormal.z)
        
        self:SetAngles(Angles(0, yaw, 0))
        
        local origin = nil        
        if owner.GetPositionForMinimap then
            origin = owner:GetPositionForMinimap()
        else
            origin = owner:GetOrigin()
        end
        
        if origin then
        
            // always use zero y-origin (for now, if you want to use it for long-range hivesight, add it back
            self:SetOrigin(Vector(origin.x, 0, origin.z))      
            
            self:UpdateRelevancy()
            
            local owner = Shared.GetEntity(self.ownerEntityId)
            
            if HasMixin(owner, "MapBlip") then
            
                local success, blipType, blipTeam, isInCombat = owner:GetMapBlipInfo()

                self.mapBlipType = blipType
                self.mapBlipTeam = blipTeam
                self.isInCombat = isInCombat    
                
            end 

        end
        
    end
    
end

function MapBlip:GetIsValid()

    local entity = Shared.GetEntity(self:GetOwnerEntityId())
    if entity == nil then
        return false
    end
    
    if entity.GetIsBlipValid then
        return entity:GetIsBlipValid()
    end
    
    return true
    
end

Shared.LinkClassToMap("MapBlip", MapBlip.kMapName, networkVars)