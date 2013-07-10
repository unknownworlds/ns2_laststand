// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Mixins/ClientModelMixin.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// and Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Mixins/BaseModelMixin.lua")

ClientModelMixin = CreateMixin( ClientModelMixin )
ClientModelMixin.type = "Model"

ClientModelMixin.expectedMixins =
{
    BaseModel = "Base model mixin must be present"
}

ClientModelMixin.optionalCallbacks =
{
    GetUpdateServerModel = "Return true to update the model on the server."
}

ClientModelMixin.networkVars = 
{
}

function ClientModelMixin:__initmixin()

    self.limitedModel = true
    self.fullyUpdated = Client or Predict
    self.forceNextUpdate = true
    
    if Server then
        self.forceModelUpdateUntilTime = 0
    end

end

if Server then

    function ClientModelMixin:SetCoords()
        self.forceModelUpdateUntilTime = Shared.GetTime() + 1
    end

    function ClientModelMixin:SetAngles()
        self.forceModelUpdateUntilTime = Shared.GetTime() + 1
    end
    
    function ClientModelMixin:SetOrigin()
        self.forceModelUpdateUntilTime = Shared.GetTime() + 1
    end
    
    function ClientModelMixin:SetAttachPoint()
        self.forceModelUpdateUntilTime = Shared.GetTime() + 1
    end
    
    function ClientModelMixin:OnConstructionComplete()
        self.forceModelUpdateUntilTime = Shared.GetTime() + 1
    end

    function ClientModelMixin:ForceUpdateUntil(time)
        self.forceModelUpdateUntilTime = time
    end
    
    function ClientModelMixin:OnConstruct(builder, fraction)
    
        if math.floor(fraction * 10) ~= self.lastFractionTenth then
            self.lastFractionTenth = math.floor(fraction * 10)
            self.forceNextUpdate = true
        end
        
    end
    
    local function CheckForceUpdate(self)
    
        if self.GetUpdateServerModel then
            self.fullyUpdated = self:GetUpdateServerModel()
        end

        self.fullyUpdated = self.forceModelUpdateUntilTime > Shared.GetTime()
        
    end
    
    function ClientModelMixin:OnUpdate()
        CheckForceUpdate(self)
    end
    
    function ClientModelMixin:OnProcessMove()
        CheckForceUpdate(self)
    end

end
