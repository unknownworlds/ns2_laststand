// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NutrientMist.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'NutrientMist' (CommanderAbility)

NutrientMist.kMapName = "nutrientmist"

NutrientMist.kNutrientMistEffect = PrecacheAsset("cinematics/alien/nutrientmist.cinematic")

NutrientMist.kType = CommanderAbility.kType.Repeat
NutrientMist.kSearchRange = 10

local netWorkVars =
{
}

if Server then

    function NutrientMist:OnInitialized()
    
        CommanderAbility.OnInitialized(self)
        
        // never show for marine commander
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom, kRelevantToTeam2Commander)
        self:SetExcludeRelevancyMask(mask)

    end

end

function NutrientMist:Perform()

    self.success = false

    local entities = GetEntitiesWithMixinForTeamWithinRange("Catalyst", self:GetTeamNumber(), self:GetOrigin(), NutrientMist.kSearchRange)
    
    for index, entity in ipairs(entities) do    
        entity:TriggerCatalyst(2)    
    end

end

function NutrientMist:GetStartCinematic()
    return NutrientMist.kNutrientMistEffect
end

function NutrientMist:GetType()
    return NutrientMist.kType
end

function NutrientMist:GetUpdateTime()
    return 1.5
end

function NutrientMist:GetLifeSpan()
    return kNutrientMistDuration
end

Shared.LinkClassToMap("NutrientMist", NutrientMist.kMapName, netWorkVars)