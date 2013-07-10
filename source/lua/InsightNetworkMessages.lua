// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InsightNetworkMessages.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kHealthMessage =
{
    clientIndex = "entityid",
    health = "integer",
    maxHealth = "integer",
    armor = "integer",
    maxArmor = "integer"
}

function BuildHealthMessage(player)

    local t = {}

    t.clientIndex       = player:GetClientIndex()
    t.health            = player:GetHealth()
    t.maxHealth         = player:GetMaxHealth()
    t.armor             = player:GetArmor()
    t.maxArmor          = player:GetMaxArmor()

    return t

end

Shared.RegisterNetworkMessage( "Health", kHealthMessage )

local kTechPointsMessage =
{
    entityIndex = "entityid",
    teamNumber = "integer",
    techId = "integer",
    location = "integer",
    healthFraction = "float",
    powerNodeFraction = "float",
    builtFraction = "float",
    eggCount = "integer"
}

function BuildTechPointsMessage(techPoint, powerNodes, eggs)

    local t = {}
    local techPointLocation = techPoint:GetLocationId()
    t.entityIndex = techPoint:GetId()
    t.location = techPointLocation
    t.teamNumber = techPoint.occupiedTeam
    
    local structure = Shared.GetEntity(techPoint.attachedId)
    
    if structure then

        local eggCount = 0
        for _, egg in ientitylist(eggs) do
            if egg:GetLocationId() == techPointLocation and egg:GetIsAlive() and egg:GetIsEmpty() then
                eggCount = eggCount + 1
            end
        end
        t.eggCount = eggCount
        
        for _, powerNode in ientitylist(powerNodes) do
            if powerNode:GetLocationId() == techPointLocation then
                if powerNode:GetIsSocketed() then
                    t.powerNodeFraction = powerNode:GetHealthScalar()
                else
                    t.powerNodeFraction = -1
                end
                break
            end
        end

        t.teamNumber = structure:GetTeamNumber()
        t.techId     = structure:GetTechId()
        if structure:GetIsAlive() then
            t.builtFraction = structure:GetBuiltFraction()
            t.healthFraction= structure:GetHealthScalar()
        else
            t.builtFraction = -1
            t.healthFraction= -1
        end
        return t

    end
    
    return t

end

Shared.RegisterNetworkMessage( "TechPoints", kTechPointsMessage )


local kRecycleMessage =
{
    resLost = "float",
    techId = "enum kTechId",
    resGained = "integer"
}

function BuildRecycleMessage(resLost, techId, resGained)

    local t = {}

    t.resLost = resLost
    t.techId = techId
    t.resGained = resGained

    return t

end

Shared.RegisterNetworkMessage( "Recycle", kRecycleMessage )

-- empty network message for game reset
Shared.RegisterNetworkMessage( "Reset" )