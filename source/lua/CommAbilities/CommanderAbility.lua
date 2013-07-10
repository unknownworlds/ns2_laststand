// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommanderAbility.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// An ability that is triggered by the commander. It's effect can be over time or instant or
// have a looping effect that get triggers in a specific interval and disappears after some
// conditions are met. This class is actually just here for utility to make it easier to implement
// new abilities.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")

class 'CommanderAbility' (ScriptActor)

CommanderAbility.kMapName = "commanderability"

/**
*   Instant:    Perform() called once and then immedeately destroyed
*   OverTime:   Perform() called once and destroyed after some time (passive behavior)
*   Repeat:    Perform() called repeatedly until life span is over 
*/
CommanderAbility.kType = enum({ 'Instant', 'OverTime', 'Repeat' })

CommanderAbility.kDefaultLifeSpan = 2
local kDefaultUpdateTime = 0.5
CommanderAbility.kDefaultType = CommanderAbility.kType.Instant

local networkVars =
{
    timeCreated = "float"
}

AddMixinNetworkVars(TeamMixin, networkVars)

function CommanderAbility:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    
end

local function CommanderAbilityUpdate(self)

    self:CreateRepeatEffect()
    
    local abilityType = self:GetType()
    // Instant types have already been performed in OnInitialized.
    if abilityType ~= CommanderAbility.kType.Instant then
        self:Perform()
    end
    
    local lifeSpanEnded = not self:GetLifeSpan() or (self:GetLifeSpan() + self.timeCreated) <= Shared.GetTime()
    if Server and (lifeSpanEnded or self:GetAbilityEndConditionsMet() or abilityType == CommanderAbility.kType.OverTime or abilityType == CommanderAbility.kType.Instant) then
        DestroyEntity(self)
    elseif abilityType == CommanderAbility.kType.Repeat then
        return true
    end
    
    return false
    
end

function CommanderAbility:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    if Server then
        self.timeCreated = Shared.GetTime()
    end
    
    if self.timeCreated + kDefaultUpdateTime > Shared.GetTime() then
        self:CreateStartEffect()
    end
    
    self:CreateRepeatEffect()
    
    local callbackRate = nil
    
    if self:GetType() == CommanderAbility.kType.Repeat then
        callbackRate = self:GetUpdateTime()
    elseif self:GetType() == CommanderAbility.kType.OverTime then
        callbackRate = self:GetLifeSpan()
    elseif self:GetType() == CommanderAbility.kType.Instant then
    
        self:Perform()
        // give some time to ensure propagation of the entity
        callbackRate = 0.1
        
    end
    
    if callbackRate then
        self:AddTimedCallback(CommanderAbilityUpdate, callbackRate)
    end
    
end

function CommanderAbility:OnDestroy()

    self:DestroyRepeatEffect()
    self:CreateEndEffect()
    
    ScriptActor.OnDestroy(self)

end

function CommanderAbility:GetTimeCreated()
    return self.timeCreated
end

function CommanderAbility:CreateRepeatEffect()

    // Glowing rotating particles
    if Client then
    
        local cinematic = self:GetRepeatCinematic()
    
        if cinematic ~= nil and not self.repeatingEffect then
    
            self.repeatingEffect = Client.CreateCinematic(RenderScene.Zone_Default)    
            self.repeatingEffect:SetCinematic(cinematic)    
            self.repeatingEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
    
            local coords = Coords.GetIdentity()
            coords.origin = self:GetOrigin()
            self.repeatingEffect:SetCoords(coords)
        
        end
        
    end

end

function CommanderAbility:DestroyRepeatEffect()

    if Client then
    
        if self.repeatingEffect then
        
            Client.DestroyCinematic(self.repeatingEffect)
            self.repeatingEffect = nil
            
        end
        
    end

end

function CommanderAbility:CreateStartEffect()

    if Client then
    
        local cinematic = self:GetStartCinematic()
    
        if cinematic ~= nil then
        
            local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
            effect:SetCinematic(cinematic)
            effect:SetCoords(self:GetCoords())

        end
        
    end

end

function CommanderAbility:CreateEndEffect()

    // Glowing rotating particles
    if Client then
    
        local cinematic = self:GetEndCinematic()
    
        if cinematic ~= nil then
        
            local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
            effect:SetCinematic(cinematic)    
    
            local coords = Coords.GetIdentity()
            coords.origin = self:GetOrigin()
            effect:SetCoords(coords)
            
        end
        
    end

end

// functions should be overriden by derrived classes

function CommanderAbility:GetStartCinematic()
    return nil
end

function CommanderAbility:GetEndCinematic()
    return nil
end

function CommanderAbility:GetRepeatCinematic()
    return nil
end

function CommanderAbility:GetAbilityEndConditionsMet()
    return false
end

function CommanderAbility:Perform()
end

function CommanderAbility:GetUpdateTime()
    return kDefaultUpdateTime
end

function CommanderAbility:GetType()
    return CommanderAbility.kDefaultType
end
    
function CommanderAbility:GetLifeSpan()
    return CommanderAbility.kDefaultLifeSpan
end

function CommanderAbility:GetClassesInRange(range, teamNumber, ...)

    local result = {}
    for i = 1, select('#', ...) do
    
        local className = select(i, ...)
        local entities = GetEntitiesForTeamWithinRange(className, teamNumber, self:GetOrigin(), range)
        for index, entity in ipairs(entities) do
            table.insert(result, entity)
        end
    
    end
    
    return result

end

function CommanderAbility:GetClosestFromTable(entities, CheckFunc)

    Shared.SortEntitiesByDistance(self:GetOrigin(), entities)
    
    for index, entity in ipairs(entities) do

        if not CheckFunc or CheckFunc(entity) then        
            return entity
        end
    
    end
    
end

if Client then

    function CommanderAbility:OnUpdateRender()
    
        if self.repeatingEffect then
        
            local coords = self:GetCoords()
        
            if self.GetRepeatingEffectCoords then
                coords = self:GetRepeatingEffectCoords() or coords
            end
        
            self.repeatingEffect:SetCoords(coords)
        end
    
    end

end

Shared.LinkClassToMap("CommanderAbility", CommanderAbility.kMapName, networkVars)