// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NanoShield.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// That entity is used to ensure triggering client side effects. The
// NanoShield effect for structure / marines (damage reduction) is done in
// NanoShieldMixin, it will get trigger in Perform(), where it searches for the closest
// friendly unit (with that mixin and able to receive a shield).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'NanoShield' (CommanderAbility)

NanoShield.kMapName = "nanoshield"

NanoShield.kNanoShieldEffect = PrecacheAsset("cinematics/marine/nanoshield/nanoshield_trigger.cinematic")

NanoShield.kType = CommanderAbility.kType.Instant
NanoShield.kSearchRange = 6

local networkVars = { }

// find closest friendly unit and shield it
function NanoShield:Perform()

    local entities = GetEntitiesWithMixinForTeamWithinRange("NanoShieldAble", self:GetTeamNumber(), self:GetOrigin(), NanoShield.kSearchRange)
    
    local CheckFunc = function(entity)
        return entity:GetCanBeNanoShielded()
    end
    
    local closest = self:GetClosestFromTable(entities, CheckFunc)
    
    if closest then
    
        closest:ActivateNanoShield()
        self.success = true
        TEST_EVENT("NanoShield activated")
        
    end

end
/*
function NanoShield:GetStartCinematic()
    return NanoShield.kNanoShieldEffect
end
*/
function NanoShield:GetType()
    return NanoShield.kType
end

function NanoShield:GetWasSuccess()
    return self.success
end

Shared.LinkClassToMap("NanoShield", NanoShield.kMapName, networkVars)