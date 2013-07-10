// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\SignalListenerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

SignalListenerMixin = { }
SignalListenerMixin.type = "SignalListener"

local kAllMessages = 1

function SignalListenerMixin:__initmixin()

    self.listenChannel = 0
    self.signalFunctions = { }
    
end

function SignalListenerMixin:RegisterSignalListener(registerFunction, onMessage)

    assert(type(registerFunction) == "function")
    local messageType = type(onMessage)
    assert(messageType == "string" or messageType == "nil")
    
    // If nil is passed in for the message, use 1 to signify "all messages"
    onMessage = onMessage or kAllMessages
    
    self.signalFunctions[onMessage] = self.signalFunctions[onMessage] or { }
    table.insert(self.signalFunctions[onMessage], registerFunction)
    
end

function SignalListenerMixin:SetListenChannel(setChannel)

    assert(type(setChannel) == "number")
    assert(setChannel >= 0)
    
    self.listenChannel = setChannel
    
end

function SignalListenerMixin:GetListenChannel()
    return self.listenChannel
end

function SignalListenerMixin:OnSignal(message)

    // Notify the functions that have registered this specific message.
    local registeredFunctions = self.signalFunctions[message]
    if registeredFunctions then
    
        for _, registeredFunction in ipairs(registeredFunctions) do
            registeredFunction(self, message)
        end
        
    end
    
    // Notify the functions that want to hear about all messages.
    local allMessagesListeners = self.signalFunctions[kAllMessages]
    if allMessagesListeners then
    
        for _, registeredFunction in ipairs(allMessagesListeners) do
            registeredFunction(self, message)
        end
        
    end
    
end