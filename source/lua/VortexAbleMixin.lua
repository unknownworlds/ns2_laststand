// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\VortexAbleMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used in combination with onos "stomp" ability.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

VortexAbleMixin = CreateMixin( VortexAbleMixin )
VortexAbleMixin.type = "VortexAble"

VortexAbleMixin.expectedCallbacks = {}

VortexAbleMixin.kEffectInterval = 1
local kVortexEffectOffset = Vector(0, 0.7, 0)

VortexAbleMixin.optionalCallbacks =
{
    OnVortex = "Called when the entity is hit by stomp and was functional before.",
    OnVortexEnd = "Called when vortex time is over.",
    GetCanBeVortexed = "Return false if it is not possible to be vortexed currently.",
    OnVortexClient = "Called when the entity is hit by vortex and was functional before, client side.",
    OnVortexEndClient = "Called when vortex time is over.",
}

VortexAbleMixin.networkVars =
{
    vortexed = "boolean"
}

function VortexAbleMixin:__initmixin()

    self.remainingVortexDuration = 0
    self.vortexed = false
    
    if Client then
        self.vortexedClient = false
    end
    
end

function VortexAbleMixin:OnVortexClient()
    self:TriggerEffects("vortexed_start")
end

function VortexAbleMixin:OnVortexEndClient()
    self:TriggerEffects("vortexed_end")
end

function VortexAbleMixin:GetIsVortexed()
    return self.vortexed
end

function VortexAbleMixin:FreeVortexed()
    
    if self:GetIsVortexed() and self.OnVortexEnd then
        self:OnVortexEnd()
    end

    self.remainingVortexDuration = 0
    self.vortexed = false
end

function VortexAbleMixin:SetVortexDuration(duration)

    if self.GetCanBeVortexed and not self:GetCanBeVortexed() then
        return
    elseif self:GetIsVortexed() then
        return
    end    
    
    self:OnVortex(duration)
    
    self.remainingVortexDuration = duration
    self.vortexed = true
    
end

function VortexAbleMixin:UpdateVortextClientEffects(deltaTime)

    if self:GetIsVortexed() then

        if not self.timeLastVortexEffect then
            self.timeLastVortexEffect = Shared.GetTime()
        end
        
        if self.timeLastVortexEffect + VortexAbleMixin.kEffectInterval < Shared.GetTime() then
        
            self:TriggerEffects("vortexed")
            self.timeLastVortexEffect = Shared.GetTime()
            
        end
    
    end

end

local function UpdateVortexShaderEffects(self)

    if self:GetIsVortexed() then
        self.vortexDissolve = 0.75 + math.sin(Shared.GetTime() * 7) * 0.07
    else
        self.vortexDissolve = 0
    end
    
    self:SetOpacity(1 - self.vortexDissolve, "vortexDissolve")

    for i = 1, self:GetNumChildren() do
    
        local child = self:GetChildAtIndex(i - 1)
        if child and HasMixin(child, "Model") then        
            child:SetOpacity(1 - self.vortexDissolve, "vortexDissolve")        
        end
        
    end    
        
end

local function SharedUpdate(self, deltaTime)

    if Client then
        UpdateVortexShaderEffects(self)
    end

    if Server then
    
        if self:GetIsVortexed() then
        
            self.remainingVortexDuration = self.remainingVortexDuration - deltaTime            
            if self.remainingVortexDuration < 0 then
            
                self.remainingVortexDuration = 0
                self.vortexed = false
                
                self:OnVortexEnd()
                
            end
            
        end
            
    elseif Client then
    
        self:UpdateVortextClientEffects(deltaTime)
        
        if not Shared.GetIsRunningPrediction() then
        
            if self.vortexedClient ~= self:GetIsVortexed() then
            
                if self:GetIsVortexed() then
                
                    self:OnVortexClient()
                    
                else
                
                    self:OnVortexEndClient()

                end
                
                self.vortexedClient = self:GetIsVortexed()
            
            end
            
        end
        
    end
    
end

function VortexAbleMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function VortexAbleMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function VortexAbleMixin:ComputeDamageAttackerOverrideMixin(attacker, damage, damageType, doer)

    if self:GetIsVortexed() and (doer == self or doer:GetParent() == self) then
        damage = 0
    end

    return damage

end

function VortexAbleMixin:GetCanTakeDamageOverrideMixin()
    return not self:GetIsVortexed()
end
