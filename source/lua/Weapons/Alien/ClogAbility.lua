// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\ClogAbility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ClogAbility' (StructureAbility)

local kMinDistance = 0.5
local kClogOffset = 0.15

function ClogAbility:OverrideInfestationCheck(trace)

    if trace.entity and trace.entity:isa("Clog") then
        return true
    end

    return false    

end

function ClogAbility:AllowBackfacing()
    return true
end

function ClogAbility:GetIsPositionValid(position, player)

    local valid = true
    local entities = GetEntitiesWithinRange("ScriptActor", position, 7)    
    for _, entity in ipairs(entities) do
    
        if not entity:isa("Infestation") and entity ~= player then
        
            local checkDistance = ConditionalValue(entity:isa("PhaseGate") or entity:isa("TunnelEntrance"), 3, kMinDistance)
            valid = ((entity:GetCoords().yAxis * checkDistance * 0.75 + entity:GetOrigin()) - position):GetLength() > checkDistance

            if not valid then
                break
            end
        
        end
    
    end
    
    return valid

end

function ClogAbility:ModifyCoords(coords)
    coords.origin = coords.origin + coords.yAxis * kClogOffset
end

function ClogAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function ClogAbility:GetDropRange()
    return 3
end

/*
function ClogAbility:IsAllowed(player)
    return player and player.GetHasTwoHives and player:GetHasTwoHives()
end
*/

function ClogAbility:GetPrimaryAttackDelay()
    return 1.0
end

function ClogAbility:GetGhostModelName(ability)
    return Clog.kModelName
end

function ClogAbility:GetDropStructureId()
    return kTechId.Clog
end

function ClogAbility:GetSuffixName()
    return "clog"
end

function ClogAbility:GetDropClassName()
    return "Clog"
end

function ClogAbility:GetDropMapName()
    return Clog.kMapName
end    

