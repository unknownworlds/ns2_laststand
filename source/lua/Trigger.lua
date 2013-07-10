// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Trigger.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// General purpose trigger object. Will notify when another entity enters or leaves a volume.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TriggerMixin.lua")

class 'Trigger' (Entity)

Trigger.kMapName = "trigger"

local networkVars =
{
    name = string.format("string (%d)", kMaxEntityStringLength),
    scale = "vector"
}

function Trigger:OnCreate()

    Entity.OnCreate(self)

    InitMixin(self, TriggerMixin, {kPhysicsGroup = PhysicsGroup.TriggerGroup, kFilterMask = PhysicsMask.AllButTriggers} )
    
    self:SetUpdates(false)

end

function Trigger:OnInitialized()
    self:SetBox(self.scale)
end

function Trigger:GetName()
    return self.name
end

function Trigger:tostring()
    return string.format("Trigger: \"%s\" origin: %s, scale: %s", ToString(self.name), self:GetOrigin():tostring(), self.scale:tostring()) 
end

Shared.LinkClassToMap("Trigger", Trigger.kMapName, networkVars)