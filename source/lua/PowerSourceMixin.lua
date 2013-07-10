// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PowerSourceMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PowerUtility.lua")

PowerSourceMixin = CreateMixin( PowerSourceMixin )
PowerSourceMixin.type = "PowerSource"

// This is needed so alien structures can be cloaked, but not marine structures
PowerSourceMixin.expectedCallbacks =
{
    GetCanPower = "Return true/false if a passed consumer can get powered."
}

PowerSourceMixin.networkVars =
{
    powering = "boolean"
}

function PowerSourceMixin:__initmixin()

    self.powering = false

    if Server then
        self.powerConsumerIds = {}
    end
end

if Server then

    local function OnPowerLoss(powerSource)

        powerSource.powering = false

        local powerConsumerIds = powerSource:GetPowerConsumers()
        
        for _, powerConsumerId in ipairs(powerConsumerIds) do

            local powerConsumer = Shared.GetEntity(powerConsumerId)
            if powerConsumer then 
                local newSource = FindNewPowerSource(powerConsumer)
                
                if not newSource then
                    powerConsumer:SetPowerOff()
                else
                    newSource:AddConsumer(powerConsumer)
                end
            end
     
        end

    end
    
    local function OnPowerGain(powerSource)
    
        powerSource.powering = true
        
        // Reset consumers. This is needed because a new consumer may
        // have been created while the power was out. They would be unpowered
        // without this.
        powerSource.powerConsumerIds = { }
        FindNewPowerConsumers(powerSource)
        
        local powerConsumerIds = powerSource:GetPowerConsumers()
        
        for _, powerConsumerId in ipairs(powerConsumerIds) do
        
            local powerConsumer = Shared.GetEntity(powerConsumerId)
            powerConsumer:SetPowerOn()
            
        end
        
    end
    
    local function ResetPowerSource(self)
    
        OnPowerLoss(self)
        self.powerConsumerIds = {}
        FindNewPowerConsumers(self)
        OnPowerGain(self)
    
    end
    
    function PowerSourceMixin:OnReset()  
        ResetPowerSource(self)    
    end
    
    function PowerSourceMixin:AddConsumer(consumer)
    
        assert(consumer)
        table.insertunique(self.powerConsumerIds, consumer:GetId())
     
    end
    
    function PowerSourceMixin:GetPowerConsumers()
        return self.powerConsumerIds
    end

    function PowerSourceMixin:OnEntityChange(oldId, newId)

        if table.contains(self.powerConsumerIds, oldId) then

            table.removevalue(self.powerConsumerIds, oldId)
            
            if newId and newId ~= Entity.invalidId then
            
                local consumer = Shared.GetEntity(newId)
                if consumer and HasMixin(consumer, "PowerConsumer") and self.powering then
                    self:AddConsumer(consumer)
                end
            
            end
            
            if self.OnPowerConsumerChanged then
                self:OnPowerConsumerChanged()
            end

        end

    end

    function PowerSourceMixin:OnKill()
        OnPowerLoss(self)
    end

    function PowerSourceMixin:OnDestroy()
        OnPowerLoss(self)
    end

    function PowerSourceMixin:OnConstructionComplete()
        ResetPowerSource(self)
    end
    
    // used for manually triggering power change
    function PowerSourceMixin:SetPoweringState(powering)
    
        if powering then
            OnPowerGain(self)
        else
            OnPowerLoss(self)
        end
        
    end

end

function PowerSourceMixin:GetIsPowering()
    return self.powering
end    

function PowerSourceMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("PowerSourceMixin:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("powering", self:GetIsPowering())
    
end