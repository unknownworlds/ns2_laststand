// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Upgrade.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Utility functions for readability.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetHasPrereqs(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techTree:GetHasTech(techNode:GetPrereq1()) and techTree:GetHasTech(techNode:GetPrereq2())
        end 
   
    end
    
    return false

end

function GetIsTechAvailable(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techNode:GetAvailable()
        end 
   
    end
    
    return false

end

function GetIsTechResearched(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techNode:GetResearched()
        end 
   
    end
    
    return false

end

local function GetTeamHasTech(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
        return techTree:GetHasTech(techId, true)
    end
    
    return false

end

function GetHasHealingBedUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.HealingBed)
end

function GetHasMucousMembraneUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.MucousMembrane)
end

function GetHasBacterialReceptorsUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.BacterialReceptors)
end

local function HasUpgrade(callingEntity, techId)

    if not callingEntity then
        return false
    end

    if callingEntity:GetHasUpgrade(techId) then
        return true
    end

    local techtree = GetTechTree(callingEntity:GetTeamNumber())

    if techtree then
        return callingEntity:GetHasUpgrade(techId) // and techtree:GetIsTechAvailable(techId)
    else
        return false
    end

end

function GetHasCelerityUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Celerity)
end

function GetHasHyperMutationUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.HyperMutation)
end

function GetHasRegenerationUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Regeneration)
end

function GetHasFeintUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Feint)
end

function GetHasAdrenalineUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Adrenaline)
end

function GetHasCarapaceUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Carapace)
end

function GetHasAuraUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Aura)
end

function GetHasCamouflageUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Camouflage)
end

function GetHasSilenceUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Silence)
end

function GetHiveTypeForUpgrade(upgradeId)

    local hiveType = LookupTechData(upgradeId, kTechDataCategory, kTechId.None)
    return hiveType

end

// checks if upgrade category is already used
function GetIsUpgradeAllowed(callingEntity, techId, upgradeList)

    local allowed = false

    if callingEntity then
    
        allowed = true
    
        local hiveType = GetHiveTypeForUpgrade(techId)
    
        for i = 1, #upgradeList do
        
            if GetHiveTypeForUpgrade(upgradeList[i]) == hiveType then
                allowed = false
                break
            end
        
        end
    
    end
    
    return allowed

end