// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DeathTrigger.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// Kill entity that touches this.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechMixin.lua")
Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'DeathTrigger' (Trigger)

DeathTrigger.kMapName = "death_trigger"

local networkVars =
{
}

AddMixinNetworkVars(TechMixin, networkVars)

local function KillEntity(self, entity)

    if Server and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanDie(true) then
    
        local direction = GetNormalizedVector(entity:GetModelOrigin() - self:GetOrigin())
        entity:Kill(self, self, self:GetOrigin(), direction)
        
    end
    
end

local function KillAllInTrigger(self)

    for _, entity in ipairs(self:GetEntitiesInTrigger()) do
        KillEntity(self, entity)
    end
    
end

function DeathTrigger:OnCreate()

    Trigger.OnCreate(self)
    
    InitMixin(self, TechMixin)
    InitMixin(self, SignalListenerMixin)
    
    self.enabled = true
    
    self:RegisterSignalListener(function() KillAllInTrigger(self) end, "kill")
    
end

local function GetDamageOverTimeIsEnabled(self)
    return self.damageOverTime ~= nil and self.damageOverTime > 0
end

function DeathTrigger:OnInitialized()

    Trigger.OnInitialized(self)
    
    self:SetTriggerCollisionEnabled(true)
    
    self:SetUpdates(GetDamageOverTimeIsEnabled(self))
    
end

local function DoDamageOverTime(entity, damage)

    if HasMixin(entity, "Live") then
        entity:TakeDamage(damage, nil, nil, nil, nil, 0, damage, kDamageType.Normal)
    end
    
end

function DeathTrigger:OnUpdate(deltaTime)

    if GetDamageOverTimeIsEnabled(self) then
        self:ForEachEntityInTrigger(function(entity) DoDamageOverTime(entity, self.damageOverTime * deltaTime) end)
    end
    
end

function DeathTrigger:OnTriggerEntered(enterEnt, triggerEnt)

    if self.enabled and not GetDamageOverTimeIsEnabled(self) then
        KillEntity(self, enterEnt)
    end
    
end

Shared.LinkClassToMap("DeathTrigger", DeathTrigger.kMapName, networkVars)