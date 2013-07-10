// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MapConnector.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used for displaying connections on the minimap. origin is startpoint.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Entity.lua")
Script.Load("lua/TeamMixin.lua")

class 'MapConnector' (Entity)

MapConnector.kMapName = "mapconnector"

local networkVars =
{
    endPoint = "vector"
}

AddMixinNetworkVars(TeamMixin, networkVars)

function MapConnector:OnCreate()
    
    Entity.OnCreate(self)
    
    InitMixin(self, TeamMixin)

    self:SetUpdates(false)
    
end

function MapConnector:SetEndPoint(endPoint)
    self.endPoint = endPoint
end

function MapConnector:GetEndPoint()
    return self.endPoint
end

function MapConnector:OnTeamChange()
    self:UpdateRelevancy()
end

function MapConnector:UpdateRelevancy()

	self:SetRelevancyDistance(Math.infinity)
	
	local mask = 0
	
	if self:GetTeamNumber() == kTeam1Index then
		mask = kRelevantToTeam1
	elseif self:GetTeamNumber() == kTeam2Index then
		mask = kRelevantToTeam2
	end
		
	self:SetExcludeRelevancyMask(mask)

end

Shared.LinkClassToMap("MapConnector", MapConnector.kMapName, networkVars)