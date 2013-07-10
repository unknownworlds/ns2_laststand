// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\AlienSpectator.lua
//
//    Created by:   Marc Delorme (marc@unknownworlds.com)
//
// TeamSpectator inherit from Spectator. It's a spectator who belongs to a team, so he should not
// be able to see people of opposite team.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Spectator.lua")

class 'TeamSpectator' (Spectator)

TeamSpectator.kMapName = "teamspectator"

local networkVars = { }

function TeamSpectator:OnProcessMove(input)

    // TeamSpectators never allow mode switching. Follow only.
    input.commands = bit.band(input.commands, bit.bnot(bit.bor(Move.Weapon1, Move.Weapon2, Move.Weapon3)))
    
    // Filter change follow target keys while respawning.
    if self:GetIsRespawning() then
        input.commands = bit.band(input.commands, bit.bnot(bit.bor(Move.Jump, Move.PrimaryAttack, Move.SecondaryAttack)))
    end
    
    Spectator.OnProcessMove(self, input)
    
end

function TeamSpectator:IsValidMode(mode)
    return mode == kSpectatorMode.FirstPerson
end

function TeamSpectator:GetPlayerStatusDesc()
    return kPlayerStatus.Dead
end

function TeamSpectator:GetIsValidTarget(entity)
    return Spectator.GetIsValidTarget(self, entity) and HasMixin(entity, "Team") and entity:GetTeamNumber() == self:GetTeamNumber()
end

Shared.LinkClassToMap("TeamSpectator", TeamSpectator.kMapName, networkVars)