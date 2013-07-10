// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//    
// lua\EffectsMixin.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//  
//    Supports trigging effects in the EffectManager.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

EffectsMixin = CreateMixin(EffectsMixin)
EffectsMixin.type = "Effects"

function EffectsMixin:__initmixin()
end

function EffectsMixin:OnInitialized()

    // delay triggering of spawn effect to be independant of mixin initialization order
    // effects inherit the relevancy of the triggering entity, so this needs to be set first, otherwise players
    // could miss an effect which they were intended to so
    if Server then
        self.spawnEffectTriggered = false
    end
    
end

function EffectsMixin:OnDestroy()

    // TODO: destroy any effects?
    
end

function EffectsMixin:GetEffectParams(tableParams)

    // Only override if not specified.
    if not tableParams[kEffectFilterClassName] and self.GetClassName then
        tableParams[kEffectFilterClassName] = self:GetClassName()
    end
    
    if not tableParams[kEffectHostCoords] and self.GetCoords then
        tableParams[kEffectHostCoords] = self:GetCoords()
    end
    
end

function EffectsMixin:TriggerEffects(effectName, tableParams)

    PROFILE("EffectsMixin:TriggerEffects")
    
    assert(effectName and effectName ~= "")
    tableParams = tableParams or { }
    
    self:GetEffectParams(tableParams)
    
    GetEffectManager():TriggerEffects(effectName, tableParams, self)
    
end

if Server then

    local function UpdateSpawnEffect(self)

        if not self.spawnEffectTriggered then
            self:TriggerEffects("spawn", { ismarine = GetIsMarineUnit(self), isalien = GetIsAlienUnit(self) })
            self.spawnEffectTriggered = true
        end

    end

    function EffectsMixin:OnProcessMove()
        UpdateSpawnEffect(self)
    end

    function EffectsMixin:OnUpdate()
        UpdateSpawnEffect(self)  
    end

end

