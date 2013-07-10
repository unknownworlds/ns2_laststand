// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerConsumerMixin.lua
//
//    Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PowerUtility.lua")

PowerConsumerMixin = CreateMixin( PowerConsumerMixin )
PowerConsumerMixin.type = "PowerConsumer"

PowerConsumerMixin.ClientPowerNodeCheckIntervall = 10

// This is needed so alien structures can be cloaked, but not marine structures
PowerConsumerMixin.expectedCallbacks =
{
    GetRequiresPower = "Return true/false if this object requires power"
}

PowerConsumerMixin.optionalCallbacks =
{
    OnPowerOff = "called on power loss",
    OnPowerOn = "called on power gain",
    GetIsPoweredOverride = "override power state"
}

PowerConsumerMixin.networkVars =
{
    powered = "boolean"
}

function PowerConsumerMixin:__initmixin()
    self.powered = false
end

if Server then

    function PowerConsumerMixin:OnLocationChange(locationName)
    
        self.powerSourceId = Entity.invalidId
        if self:GetRequiresPower() then
            SocketPowerForLocation(locationName)
        end
        
    end
    
end

function PowerConsumerMixin:GetIsPowered()

    local isPowered = true
    
    if self.GetIsPoweredOverride then
        isPowered = self:GetIsPoweredOverride()
    end
    
    return self.powered and isPowered
    
end

function PowerConsumerMixin:GetCanBeUsed(player, useSuccessTable)

    if not self:GetIsPowered() then
        useSuccessTable.useSuccess = false
    end
    
end

if Server then

    local function CheckForPowerSource(self)
    
        if self:GetRequiresPower() then
        
            if not self.powerSourceId or self.powerSourceId == Entity.invalidId then
            
                local powerSource = FindNewPowerSource(self)
                if powerSource then
                
                    powerSource:AddConsumer(self)
                    self.powerSourceId = powerSource:GetId()
                    self:SetPowerOn()
                    
                end
                
            end
            
        end
        
    end
    
    local function Deploy(self)
        self:TriggerEffects("deploy")
    end
    
    function PowerConsumerMixin:OnInitialized()
        CheckForPowerSource(self)
    end
    
    function PowerConsumerMixin:SetOrigin()
        CheckForPowerSource(self)
    end
    
    function PowerConsumerMixin:SetCoords()
        CheckForPowerSource(self)
    end
    
    function PowerConsumerMixin:OnConstructionComplete()
    
        CheckForPowerSource(self)
        
        if not self:GetRequiresPower() or self:GetIsPowered() then
            Deploy(self)
        else
            self.updateDeployOnPower = true
        end
        
    end
    
    // no need to trigger power on and power off events
    function PowerConsumerMixin:OnEntityChange(oldId, newId)
    
        if oldId == self.powerSourceId then
        
            if newId and not newId == Entity.invalidId then
            
                local powerSource = Shared.GetEntity(newId)
                
                if powerSource and HasMixin(powerSource, "PowerSource") then
                
                    if powerSource:GetCanPower(self) then
                    
                        powerSource:AddConsumer(self)
                        self.powerSourceId = newId
                        
                    end
                    
                end
                
            else
            
                self.powerSourceId = Entity.invalidId
                CheckForPowerSource(self)
                
            end
            
        end
        
    end
    
    function PowerConsumerMixin:SetPowerOn()
    
        if not self:GetIsPowered() then
        
            self.powered = true
            
            if self.OnPowerOn then
                self:OnPowerOn()
            end
            
            if self.updateDeployOnPower then
            
                Deploy(self)
                self.updateDeployOnPower = false
                
            end
            
        end
        
    end
    
    function PowerConsumerMixin:SetPowerOff()
    
        if self:GetIsPowered() then
        
            self.powered = false
            
            if self.OnPowerOff then
                self:OnPowerOff()
            end
            
        end
        
    end
    
elseif Client then

    // TODO: listen to power state changes and trigger effects
	
end

function PowerConsumerMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("PowerConsumerMixin:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("powered", self:GetIsPowered())
    
end