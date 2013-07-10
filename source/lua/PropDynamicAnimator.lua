// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/PropDynamicAnimator.lua
//
// This entity will listen for a mapper specified message and then look for nearby
// PropDynamic entities and change the mapper specified animation input.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'PropDynamicAnimator' (Entity)

PropDynamicAnimator.kMapName = "prop_dynamic_animator"

local kDefaultRange = 10

function PropDynamicAnimator:OnCreate()

    Entity.OnCreate(self)
    
    // Should only exist on the Server.
    assert(Server)
    
    InitMixin(self, SignalListenerMixin)
    
    self:SetPropagate(Entity.Propagate_Never)
    self:SetUpdates(false)
    
    self.listenChannel = 0
    self.listenMessage = ""
    self.inputName = ""
    self.inputValue = ""
    self.range = kDefaultRange
    
end

local function OnAnimateMessage(self)

    local nearbyProps = GetEntitiesWithinRange("PropDynamic", self:GetOrigin(), self.range)
    for p = 1, #nearbyProps do
    
        local value = self.inputValue
        local valLower = string.lower(value)
        value = (valLower == "true" and true) or (valueLower == "false" and false) or value
        nearbyProps[p]:SetAnimationInput(self.inputName, value)
        
    end
    
end

function PropDynamicAnimator:OnInitialized()

    self:SetListenChannel(self.listenChannel)
    self:RegisterSignalListener(function() OnAnimateMessage(self) end, self.listenMessage)
    
end

Shared.LinkClassToMap("PropDynamicAnimator", PropDynamicAnimator.kMapName, { })