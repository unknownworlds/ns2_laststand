// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfestationMap.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


function UpdateInfestationMasks()

    PROFILE("InfestationMap:UpdateInfestationMasks")

    local infestationTrackers = GetEntitiesWithMixin("InfestationTracker")    
    for index = 1, #infestationTrackers do
        UpdateInfestationMask(infestationTrackers[index])
    end
    
end

// Clear OnInfestation game effect mask on all entities, unless they are standing on infestation
function UpdateInfestationMask(forEntity)

    if HasMixin(forEntity, "InfestationTracker") then
        forEntity:SetInfestationState(GetIsPointOnInfestation(forEntity:GetOrigin()))
    end
    
end