// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/ButtonEmitter.lua
//
// The button will emit a specified signal when it is used.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalEmitterMixin.lua")
Script.Load("lua/UsableMixin.lua")

class 'ButtonEmitter' (Entity)

ButtonEmitter.kMapName = "button_emitter"

local networkVars =
{
    coolDownTime = "time",
    timeLastUsed = "time"
}

function ButtonEmitter:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, SignalEmitterMixin)
    InitMixin(self, UsableMixin)
    
    self:SetUpdates(false)
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kMaxRelevancyDistance)
    
    self.emitChannel = 0
    self.emitMessage = ""
    self.coolDownTime = 0
    self.timeLastUsed = 0
    
end

function ButtonEmitter:SetEmitChannel(setChannel)

    assert(type(setChannel) == "number")
    assert(setChannel >= 0)
    
    self.emitChannel = setChannel
    
end

function ButtonEmitter:SetEmitMessage(setMessage)

    assert(type(setMessage) == "string")
    
    self.emitMessage = setMessage
    
end

function ButtonEmitter:GetUsablePoints()
    return { self:GetOrigin() }
end

function ButtonEmitter:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = ((Shared.GetTime() - self.timeLastUsed) >= self.coolDownTime)
end

if Server then

    function ButtonEmitter:OnUse(player, elapsedTime, useSuccessTable)
    
        self:EmitSignal(self.emitChannel, self.emitMessage)
        self.timeLastUsed = Shared.GetTime()
        
    end
    
end

Shared.LinkClassToMap("ButtonEmitter", ButtonEmitter.kMapName, networkVars)