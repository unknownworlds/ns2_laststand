// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommAbilities\Marine\EMPBlast.lua
//
//      Created by: Andreas Urwalek (andi@unknownworlds.com)
//
//      Takes kEMPBlastEnergyDamage energy away from all aliens in detonation radius.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'EMPBlast' (CommanderAbility)

EMPBlast.kMapName = "empblast"

EMPBlast.kSplashEffect = PrecacheAsset("cinematics/marine/mac/empblast.cinematic")

EMPBlast.kType = CommanderAbility.kType.Instant
EMPBlast.kRadius = 6

local networkVars =
{
}

function EMPBlast:GetStartCinematic()
    return EMPBlast.kSplashEffect
end   

function EMPBlast:GetType()
    return EMPBlast.kType
end

if Server then

    function EMPBlast:Perform()
        
        for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), EMPBlast.kRadius)) do
        
            // queues deduction of ability energy for next tick (fade ability energy is lag compensated)
            alien:SetEMPBlasted()
            alien:TriggerEffects("emp_blasted")
            
        end

    end

end

Shared.LinkClassToMap("EMPBlast", EMPBlast.kMapName, networkVars)