// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerUtility.lua
//
//    Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

if Server then

    // sort always by distance first (increases the chance that we find a suitable source faster)    

    function FindNewPowerConsumers(powerSource)
    
        // allow passing of nil (to handle map change or unexpected destruction of some ojects)
        if not powerSource then
            return nil
        end
    
        local consumers = GetEntitiesWithMixin("PowerConsumer")
        Shared.SortEntitiesByDistance(powerSource:GetOrigin(), consumers)
        
        local canPower = false
        local stopSearch = false

        for index, consumer in ipairs(consumers) do

            canPower, stopSearch = powerSource:GetCanPower(consumer)
        
            if canPower then
                powerSource:AddConsumer(consumer)
                consumer:SetPowerOn()
                consumer.powerSourceId = powerSource:GetId()
            end
            
            if stopSearch then
                break
            end
            
        end

    end

    function FindNewPowerSource(powerConsumer)
    
        // allow passing of nil (to handle map change or unexpected destruction of some ojects)
        if not powerConsumer then
            return nil
        end
    
        local powerSources = GetEntitiesWithMixin("PowerSource")
        Shared.SortEntitiesByDistance(powerConsumer:GetOrigin(), powerSources)
        local newPowerSource = nil
        
        for index, powerSource in ipairs(powerSources) do
        
            if powerSource:GetIsPowering() then
        
                // stop search since we need only 1 source at any given moment
                if powerSource:GetCanPower(powerConsumer) then
                    newPowerSource = powerSource
                    break
                end

            end  
        
        end

        return newPowerSource

    end
    
end    