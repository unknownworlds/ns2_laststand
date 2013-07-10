// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MinimapConnectionMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used for rendering connections on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MapConnector.lua")

MinimapConnectionMixin = CreateMixin( MinimapConnectionMixin )
MinimapConnectionMixin.type = "MinimapConnection"

MinimapConnectionMixin.expectedMixins =
{
    Team = "For team number."
}

MinimapConnectionMixin.expectedCallbacks =
{
    GetConnectionStartPoint = "For map connector.",
    GetConnectionEndPoint = "For map connector."
}

function MinimapConnectionMixin:__initmixin()
end

if Server then

    function MinimapConnectionMixin:OnUpdate(deltaTime)

        local endPoint = self:GetConnectionEndPoint()
        local startPoint = self:GetConnectionStartPoint()
        
        if (not endPoint or not startPoint) and self.connectorId then
        
            local connector = Shared.GetEntity(self.connectorId)
            if connector then
                DestroyEntity(connector)
            end
            
            self.connectorId = nil
        
        elseif endPoint and startPoint and not self.connectorId then
            self.connectorId = CreateEntity(MapConnector.kMapName, startPoint, self:GetTeamNumber()):GetId()
        end
        
        if endPoint and startPoint and self.connectorId then
        
            local connector = Shared.GetEntity(self.connectorId)
            assert(connector)
            connector:SetOrigin(startPoint)
            connector:SetEndPoint(endPoint)
        
        end
    
    end
    
    function MinimapConnectionMixin:OnDestroy()
    
        if self.connectorId then
        
            local connector = Shared.GetEntity(self.connectorId)
            if connector then
                DestroyEntity(connector)
            end
            
            self.connectorId = nil
        
        end
    
    end

end