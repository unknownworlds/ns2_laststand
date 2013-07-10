// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CragUmbra.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Protects friendly units from bullets.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'CragUmbra' (CommanderAbility)

CragUmbra.kMapName = "cragumbra"

CragUmbra.kCragUmbraEffect = PrecacheAsset("cinematics/alien/Crag/umbra.cinematic")

CragUmbra.kType = CommanderAbility.kType.Repeat

// duration of cinematic, increase cinematic duration and kCragUmbraDuration to 12 to match the old value from Crag.lua
CragUmbra.kCragUmbraDuration = kUmbraDuration
CragUmbra.kRadius = 4.0
CragUmbra.kMaxRange = 17
local kUpdateTime = 0.15
CragUmbra.kTravelSpeed = 30 // meters per second

local networkVars =
{
    destination = "vector"
}

function CragUmbra:GetRepeatCinematic()
    return CragUmbra.kCragUmbraEffect
end

function CragUmbra:GetType()
    return CragUmbra.kType
end
    
function CragUmbra:GetLifeSpan()
    return CragUmbra.kCragUmbraDuration
end

function CragUmbra:OnInitialized()

    CommanderAbility.OnInitialized(self)
    
    /*
    if Client then
        DebugCapsule(self:GetOrigin(), self:GetOrigin(), CragUmbra.kRadius, 0, CragUmbra.kCragUmbraDuration)
    end
    */
    
end

function CragUmbra:SetTravelDestination(position)
    self.destination = position
end

// called client side
function CragUmbra:GetRepeatingEffectCoords()

    if not self.travelCoords then
    
        local travelDirection = self.destination - self:GetOrigin()
        if travelDirection:GetLength() > 0 then
            
            self.travelCoords = Coords.GetIdentity()
            self.travelCoords.origin = self:GetOrigin()
            
            self.travelCoords.zAxis = GetNormalizedVector(travelDirection)
            self.travelCoords.xAxis = self.travelCoords.yAxis:CrossProduct(self.travelCoords.zAxis)
            self.travelCoords.yAxis = self.travelCoords.zAxis:CrossProduct(self.travelCoords.xAxis)
            
            return self.travelCoords
            
        end
    
    else
    
        self.travelCoords.origin = self:GetOrigin()
        return self.travelCoords
    
    end

end

function CragUmbra:GetUpdateTime()
    return kUpdateTime
end

if Server then

    function CragUmbra:Perform()
    
        for _, target in ipairs(GetEntitiesWithMixinForTeamWithinRange("Umbra", self:GetTeamNumber(), self:GetOrigin(), CragUmbra.kRadius)) do
            target:SetHasUmbra(true,kUmbraRetainTime)
        end
        
    end
    
    function CragUmbra:OnUpdate(deltaTime)
    
        CommanderAbility.OnUpdate(self, deltaTime)
        
        if self.destination then
        
            local travelVector = self.destination - self:GetOrigin()
            if travelVector:GetLength() > 0.3 then
                local distanceFraction = (self.destination - self:GetOrigin()):GetLength() / CragUmbra.kMaxRange
                self:SetOrigin( self:GetOrigin() + GetNormalizedVector(travelVector) * deltaTime * CragUmbra.kTravelSpeed * distanceFraction )
            end
        
        end
    
    end

end

Shared.LinkClassToMap("CragUmbra", CragUmbra.kMapName, networkVars)