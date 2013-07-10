// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\SignalEmitterMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

SignalEmitterMixin = CreateMixin( SignalEmitterMixin )
SignalEmitterMixin.type = "SignalEmitter"

function SignalEmitterMixin:__initmixin()

    self.signalRange = 1
    
end

function SignalEmitterMixin:SetSignalRange(setRange)

    assert(type(setRange) == "number")
    assert(setRange >= 0)
    self.signalRange = setRange
    
end

function SignalEmitterMixin:GetSignalRange()
    return self.signalRange
end

function SignalEmitterMixin:EmitSignal(channel, message)

    local nearbyListeners = Shared.GetEntitiesWithTagInRange("SignalListener", self:GetOrigin(), self.signalRange)
    for _, listener in ipairs(nearbyListeners) do
    
        if listener:GetListenChannel() == channel then
            listener:OnSignal(message)
        end
        
    end
    
end