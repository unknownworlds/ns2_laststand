// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua/TimedEmitter.lua
//
// This entity will emit a specified signal at once after a specified time or
// at a specified rate
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalEmitterMixin.lua")

class 'TimedEmitter' (Entity)

TimedEmitter.kMapName = "timed_emitter"

function TimedEmitter:OnCreate()
    
    Entity.OnCreate(self)
    
    // Should only exist on the Server.
    assert(Server)
    
    InitMixin(self, SignalEmitterMixin)
    
    self:SetPropagate(Entity.Propagate_Never)
    self:SetUpdates(true)
    
    self.emitTime = 0
    self.emitOnce = true
    self.emitChannel = 0
    self.emitMessage = ""
    
    self.timePassed = 0
    self.emitCount = 0
    
end

function TimedEmitter:SetEmitTime(setTime)

    assert(type(setTime) == "number")
    assert(setTime >= 0)
    
    self.emitTime = setTime
    
end

function TimedEmitter:SetEmitOnce(setOnce)

    assert(type(setOnce) == "boolean")
    
    self.emitOnce = setOnce
    
end

function TimedEmitter:SetEmitChannel(setChannel)

    assert(type(setChannel) == "number")
    assert(setChannel >= 0)
    
    self.emitChannel = setChannel
    
end

function TimedEmitter:SetEmitMessage(setMessage)

    assert(type(setMessage) == "string")
    
    self.emitMessage = setMessage
    
end

function TimedEmitter:OnUpdate(dt)

    if self.emitOnce and self.emitCount > 0 then
        return
    end
    
    self.timePassed = self.timePassed + dt
    
    while self.timePassed >= self.emitTime do
    
        self.timePassed = self.timePassed - self.emitTime
        
        self:EmitSignal(self.emitChannel, self.emitMessage)
        self.emitCount = self.emitCount + 1
        
        if self.emitOnce then
            break
        end
        
    end
    
end

Shared.LinkClassToMap("TimedEmitter", TimedEmitter.kMapName, { })