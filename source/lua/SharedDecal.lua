// ======= Copyright © 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/SharedDecal.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    kSharedDecalMaterials table is used for indexing all decals hooked up with the effect manager.
//    When triggering a decal generation Server side the coords wont be send, instead only the position
//    and an indexed vector of the normal (yAxis).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kNumSharedDecals = 0

kSharedDecalMaterials =
{
}

function Shared.RegisterDecalMaterial(materialName)

    if table.insertunique(kSharedDecalMaterials, materialName) then
        //Print("Shared.RegisterDecalMaterial(%s)", ToString(materialName))
    end
    kNumSharedDecals = #kSharedDecalMaterials

end

function GetDecalMaterialIndex(materialName)

    for i = 1, kNumSharedDecals do
        
        if materialName == kSharedDecalMaterials[i] then
            return i
        end
        
    end

end

function GetDecalMaterialNameFromIndex(decalIndex)
    return kSharedDecalMaterials[decalIndex]
end

function Shared.CreateTimeLimitedDecal(materialName, coords, scale, ignorePlayer)

    local success = false

    if Server then
    
        local sharedDecalIndex = GetDecalMaterialIndex(materialName)
        if sharedDecalIndex then
        
            
            // send to all players in range, consider ignorePlayer if passed
            local playersInRange = GetEntitiesWithinRange("Player", coords.origin, kMaxRelevancyDistance)
            if ignorePlayer then
                table.removevalue(ignorePlayer)
            end
            
            local message = BuildCreateDecalMessage(GetIndexFromVector(coords.yAxis), coords.origin, sharedDecalIndex, scale)
            for _, player in ipairs(playersInRange) do
                Server.SendNetworkMessage(player, "CreateDecal", message, false)  
            end
 
            success = true
        
        end
    
    elseif Client then
    
        Client.CreateTimeLimitedDecal(materialName, coords, scale)
        success = true
    
    end
    
    return success

end