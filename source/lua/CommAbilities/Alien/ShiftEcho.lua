// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ShiftEcho.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'ShiftEcho' (CommanderAbility)

ShiftEcho.kMapName = "shiftecho"

ShiftEcho.kShiftEchoEffect = PrecacheAsset("cinematics/alien/shift/echo_target.cinematic")

ShiftEcho.kType = CommanderAbility.kType.OverTime
ShiftEcho.kTeleportCost = kShiftEchoCost // per structure
ShiftEcho.kSearchRange = kEchoRange
ShiftEcho.kTeleportDelay = 5
ShiftEcho.kLifeSpan = 0.5

local networkVars =
{
    shiftId = "entityid"
}

if Server then

    function ShiftEcho:SetShiftId(shiftId)
        self.shiftId = shiftId
    end    

    // find friendly units and teleport them to the shifts location
    function ShiftEcho:Perform()
    
        local entities = GetEntitiesWithMixinForTeamWithinRange("TeleportAble", self:GetTeamNumber(), self:GetOrigin(), ShiftEcho.kSearchRange)

        local CanTeleport = function(entity)
            return entity:GetCanTeleport()
        end
        
        local shift = Shared.GetEntity(self.shiftId)
        
        if shift then
        
            local availableEnergy = shift:GetEnergy()
            
            for i = 1, math.floor(availableEnergy / ShiftEcho.kTeleportCost) do
            
                local closest = self:GetClosestFromTable(entities, CanTeleport)
                
                if closest then
                    closest:TriggerTeleport(ShiftEcho.kTeleportDelay, self.shiftId)
                    
                    if not Shared.GetCheatsEnabled() then
                        shift:AddEnergy(-ShiftEcho.kTeleportCost)
                    end
                end
                
                table.removevalue(entities, closest)
                
            end    
            
        end

    end
    
end

function ShiftEcho:GetStartCinematic()
    return ShiftEcho.kShiftEchoEffect
end

function ShiftEcho:GetType()
    return ShiftEcho.kType
end

function ShiftEcho:GetLifeSpan()
    return ShiftEcho.kLifeSpan
end

Shared.LinkClassToMap("ShiftEcho", ShiftEcho.kMapName, networkVars)