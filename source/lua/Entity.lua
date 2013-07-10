// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Entity.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function EntityToString(entity)

    if (entity == nil) then
        return "nil"
    elseif (type(entity) == "number") then
        string.format("EntityToString(): Parameter is a number (%s) instead of entity ", tostring(entity))
    elseif (entity:isa("Entity")) then
        return entity:GetClassName()
    end
    
    return string.format("EntityToString(): Parameter isn't an entity but %s instead", tostring(entity))
    
end

/*
 * For debuggin; find out who is calling us and from where (can be difficult
 * due to Mixins. So wrap the code you want traced with Shared.showStackTrace 
 true/false to figure out where its being called from.
 
local Shared_GetEntitiesWithTagInRange = Shared.GetEntitiesWithTagInRange
local function wrap1(...)
    if Shared.showStackTrace then
        Log("GEWTIR:\n%s", debug.traceback())
    end
    return Shared_GetEntitiesWithTagInRange(...)
end
Shared.GetEntitiesWithTagInRange = wrap1

local Shared_GetEntitiesWithClassname = Shared.GetEntitiesWithClassname
local function wrap2(...)
    if Shared.showStackTrace then
        Log("GEWCName:\n%s", debug.traceback())
    end
    return Shared_GetEntitiesWithClassname(...)
end
Shared.GetEntitiesWithClassname = wrap2
*/

/**
 * For use in Lua for statements to iterate over EntityList objects.
 */
function ientitylist(entityList)

    local function ientitylist_it(entityList, currentIndex)
    
        local numEntities = entityList:GetSize()
    
        while currentIndex < numEntities do
            // Check if the entity was deleted after we created the list
            local currentEnt = entityList:GetEntityAtIndex(currentIndex)
            currentIndex = currentIndex + 1
            if currentEnt ~= nil then
                return currentIndex, currentEnt    
            end
        end

        return nil
        
    end
    
    return ientitylist_it, entityList, 0
    
end

function GetEntitiesWithFilter(entityList, filterFunction)

    PROFILE("Entity:GetEntitiesWithFilter")

    assert(entityList ~= nil)
    assert(type(filterFunction) == "function")
    
    local numEntities = entityList:GetSize()
    local result = table.array(numEntities)
    local numDstEntities = 0
    
    for entityIndex = 1, numEntities do
        local entity = entityList:GetEntityAtIndex(entityIndex - 1)
        if filterFunction(entity) then
            numDstEntities = numDstEntities + 1
            result[numDstEntities] = entity
        end
    end
    
    return result

end

function EntityListToTable(entityList)

    PROFILE("EntityListToTable")

    assert(entityList ~= nil)
    
    local numEntities = entityList:GetSize()
    local result  = { }
    
    for entityIndex = 1, numEntities do
        result[entityIndex] = entityList:GetEntityAtIndex(entityIndex - 1)
    end
    
    return result

end

function GetEntitiesForTeam(className, teamNumber)

    assert(type(className) == "string")
    assert(type(teamNumber) == "number")
    
    local function teamFilterFunction(entity)
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), teamFilterFunction)

end

function GetEntitiesForTeamWithinRange(className, teamNumber, origin, range)

    assert(type(className) == "string")
    assert(type(teamNumber) == "number")
    assert(origin ~= nil)
    assert(type(range) == "number")
    
    local function teamFilterFunction(entity)    
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
    end
    return Shared.GetEntitiesWithTagInRange("class:" .. className, origin, range, teamFilterFunction)
    
end

function GetEntitiesWithinRange(className, origin, range)

    PROFILE("Entity:GetEntitiesWithinRange")
    
    assert(type(className) == "string")
    assert(origin ~= nil)
    assert(type(range) == "number")

    return Shared.GetEntitiesWithTagInRange("class:" .. className, origin, range)    

end

function GetEntitiesForTeamWithinXZRange(className, teamNumber, origin, range)
    
    assert(type(className) == "string")
    assert(type(teamNumber) == "number")
    assert(origin ~= nil)
    assert(type(range) == "number")
    
    local function inRangeXZFilterFunction(entity)
    
        local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
        return inRange and HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
        
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), inRangeXZFilterFunction)
    
end

function GetEntitiesForTeamWithinRangeAreVisible(className, teamNumber, origin, range, visibleState)

    assert(type(className) == "string")
    assert(type(teamNumber) == "number")
    assert(origin ~= nil)
    assert(type(range) == "number")
    assert(type(visibleState) == "boolean")
    
    local function teamAndVisibleStateFilterFunction(entity)
    
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber and entity:GetIsVisible() == visibleState
        
    end
    return Shared.GetEntitiesWithTagInRange("class:" .. className, origin, range, teamAndVisibleStateFilterFunction)
    
end

function GetEntitiesWithinRangeAreVisible(className, origin, range, visibleState)

    assert(type(className) == "string")
    assert(origin ~= nil)
    assert(type(range) == "number")
    assert(type(visibleState) == "boolean")
    
    local rangeSquared = range * range
    
    local function visibleStateFilterFunction(entity)
    
        return entity:GetIsVisible() == visibleState
        
    end
    return Shared.GetEntitiesWithTagInRange("class:" .. className, origin, range, visibleStateFilterFunction)
    
end

function GetEntitiesWithinXZRangeAreVisible(className, origin, range, visibleState)

    assert(type(className) == "string")
    assert(origin ~= nil)
    assert(type(range) == "number")
    assert(type(visibleState) == "boolean")
    
    local function inRangeXZFilterFunction(entity)
    
        local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
        return inRange and entity:GetIsVisible()
        
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), inRangeXZFilterFunction)
    
end

function GetEntitiesWithinRangeInView(className, range, player)

    PROFILE("Entity:GetEntitiesWithinRangeInView")
    
    assert(type(className) == "string")
    assert(type(range) == "number")
    assert(player ~= nil)
    
    function withinViewFilter(entity)
        return GetCanSeeEntity(player, entity)
    end
    
    return Shared.GetEntitiesWithTagInRange("class:" .. className, player:GetOrigin(), range, withinViewFilter)
    
end

function GetEntitiesMatchAnyTypesForTeam(typeList, teamNumber)

    assert(type(typeList) == "table")
    assert(type(teamNumber) == "number")
    
    local function teamFilter(entity)
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
    end
    
    local allMatchingEntsList = { }
    
    for i, type in ipairs(typeList) do
        local matchingEntsForType = GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(type), teamFilter)
        table.adduniquetable(matchingEntsForType, allMatchingEntsList)
    end
    
    return allMatchingEntsList

end

function GetEntitiesMatchAnyTypes(typeList)

    assert(type(typeList) == "table")
    
    local allMatchingEntsList = { }
    
    for i, type in ipairs(typeList) do
        for i, entity in ientitylist(Shared.GetEntitiesWithClassname(type)) do
            table.insertunique(allMatchingEntsList, entity)
        end
    end
    
    return allMatchingEntsList

end

function GetEntitiesWithMixin(mixinType)

    assert(type(mixinType) == "string")
    
    return EntityListToTable(Shared.GetEntitiesWithTag(mixinType))

end

function GetEntitiesWithMixinForTeam(mixinType, teamNumber)

    assert(type(mixinType) == "string")
    assert(type(teamNumber) == "number")
    
    local function onTeamFilterFunction(entity)
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithTag(mixinType), onTeamFilterFunction)

end

function GetEntitiesWithMixinWithinRange(mixinType, origin, range)

    assert(type(mixinType) == "string")
    assert(origin ~= nil)
    assert(type(range) == "number")
    
    return Shared.GetEntitiesWithTagInRange(mixinType, origin, range)
    
end

function GetEntitiesWithMixinWithinRangeAreVisible(mixinType, origin, range, visibleState)

    assert(type(mixinType) == "string")
    assert(origin ~= nil)
    assert(type(range) == "number")
    assert(type(visibleState) == "boolean")
    
    local function visibleStateFilterFunction(entity)
        return entity:GetIsVisible() == visibleState
    end
    return Shared.GetEntitiesWithTagInRange(mixinType, origin, range, visibleStateFilterFunction)
    
end

function GetEntitiesWithMixinForTeamWithinRange(mixinType, teamNumber, origin, range)

    assert(type(mixinType) == "string")
    assert(type(teamNumber) == "number")
    assert(origin ~= nil)
    assert(type(range) == "number")
    
    local function teamFilterFunction(entity)
    
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
        
    end
    return Shared.GetEntitiesWithTagInRange(mixinType, origin, range, teamFilterFunction)
end

// Fades damage linearly from center point to radius (0 at far end of radius)
function RadiusDamage(entities, centerOrigin, radius, fullDamage, doer, ignoreLOS, fallOffFunc)

    assert(HasMixin(doer, "Damage"))

    // Do damage to every target in range
    for index, target in ipairs(entities) do
    
        // Find most representative point to hit
        local targetOrigin = target:GetOrigin()
        if target.GetModelOrigin then
            targetOrigin = target:GetModelOrigin()
        end
        if target.GetEngagementPoint then
            targetOrigin = target:GetEngagementPoint()
        end    
        
        // Trace line to each target to make sure it's not blocked by a wall 
        local wallBetween = false
        local distanceFromTarget = (targetOrigin - centerOrigin):GetLength()
        
        if not ignoreLOS then
            wallBetween = GetWallBetween(centerOrigin, targetOrigin, target)
        end
        
        if (ignoreLOS or not wallBetween) and (distanceFromTarget <= radius) then
        
            // Damage falloff
            local distanceFraction = distanceFromTarget / radius
            if fallOffFunc then
                distanceFraction = fallOffFunc(distanceFraction)
            end
            
            distanceFraction = Clamp(distanceFraction, 0, 1)        
            damage = fullDamage * (1 - distanceFraction)

            local damageDirection = targetOrigin - centerOrigin
            damageDirection:Normalize()
            
            // we can't hit world geometry, so don't pass any surface params and let DamageMixin decide
            doer:DoDamage(damage, target, target:GetOrigin(), damageDirection, "none")

        end
        
    end
    
end

/**
 * Get list of child entities for player. Pass optional class name
 * to get only entities of that type.
 */
function GetChildEntities(player, isaClassName)

    local childEntities = { }
    
    for i = 0, player:GetNumChildren() - 1 do
        local currentChild = player:GetChildAtIndex(i)
        if isaClassName == nil or currentChild:isa(isaClassName) then
            table.insert(childEntities, currentChild)
        end
    end
    
    return childEntities
    
end

/**
 * Iterates over the children of the passed in entity of the passed in type
 * and calls the function passed in. All children will be iterated if the
 * childType is nil.
 */
function ForEachChildOfType(entity, childType, callback)

    for i = 0, entity:GetNumChildren() - 1 do
    
        local currentChild = entity:GetChildAtIndex(i)
        if childType == nil or currentChild:isa(childType) then
            callback(currentChild)
        end
        
    end

end

/**
 * For use in Lua for statements to iterate over an Entities' children.
 * Optionally pass in a string class name to only iterate children of that class.
 */
function ientitychildren(parentEntity, optionalClass)

    local function ientitychildren_it(parentEntity, currentIndex)
    
        if currentIndex >= parentEntity:GetNumChildren() then
            return nil
        end
        
        local currentEnt = parentEntity:GetChildAtIndex(currentIndex)
        currentIndex = currentIndex + 1
        if optionalClass and not currentEnt:isa(optionalClass) then
            return ientitychildren_it(parentEntity, currentIndex)
        end
        return currentIndex, currentEnt
        
    end
    
    return ientitychildren_it, parentEntity, 0
    
end

// Return entity number or -1 if not found
function FindNearestEntityId(className, location)

    local entityId = -1
    local shortestDistance = nil   
    
    for index, current in ientitylist(Shared.GetEntitiesWithClassname(className)) do

        local distance = (current:GetOrigin() - location):GetLength()
        
        if(shortestDistance == nil or distance < shortestDistance) then
        
            entityId = current:GetId()
            shortestDistance = distance
            
        end
            
    end    
    
    return entityId
    
end

/**
 * Given a list of entities (representing spawn points), returns a randomly chosen
 * one which is unobstructed for the player. If none of them are unobstructed, the
 * method returns nil.
 */
function GetRandomClearSpawnPoint(player, spawnPoints)

    local numSpawnPoints = table.maxn(spawnPoints)
    
    // Start with random spawn point then move up from there
    local baseSpawnIndex = NetworkRandomInt(1, numSpawnPoints)

    for i = 1, numSpawnPoints do

        local spawnPointIndex = ((baseSpawnIndex + i) % numSpawnPoints) + 1
        local spawnPoint = spawnPoints[spawnPointIndex]

        // Check to see if the spot is clear to spawn the player.
        local spawnOrigin = Vector(spawnPoint:GetOrigin())
        local spawnAngles = Angles(spawnPoint:GetAngles())
        spawnOrigin.y = spawnOrigin.y + .5
        
        spawnAngles.pitch = 0
        spawnAngles.roll  = 0
        
        player:SpaceClearForEntity(spawnOrigin)
        
        return spawnPoint
            
    end
    
    Print("GetRandomClearSpawnPoint - No unobstructed spawn point to spawn %s (tried %d)", player:GetName(), numSpawnPoints)
    
    return nil

end

// Look for unoccupied spawn point nearest given position
function GetClearSpawnPointNearest(player, spawnPoints, position)

    // Build sorted list of spawns, closest to farthest
    local sortedSpawnPoints = {}
    table.copy(spawnPoints, sortedSpawnPoints)
    
    // The comparison function must return a boolean value specifying whether the first argument should 
    // be before the second argument in the sequence (he default behavior is <).
    function sort(spawn1, spawn2)
        return (spawn1:GetOrigin() - position):GetLength() < (spawn2:GetOrigin() - position):GetLength()
    end    
    table.sort(sortedSpawnPoints, sort)

    // Build list of spawns in 
    for i = 1, table.maxn(sortedSpawnPoints) do 

        // Check to see if the spot is clear to spawn the player.
        local spawnPoint = sortedSpawnPoints[i]
        local spawnOrigin = Vector(spawnPoint:GetOrigin())

        if (player:SpaceClearForEntity(spawnOrigin)) then
        
            return spawnPoint
            
        end
        
    end
    
    Print("GetClearSpawnPointNearest - No unobstructed spawn point to spawn " , player:GetName())
    
    return nil

end

/**
 * Not all Entities have eyes. Play it safe.
 */
function GetEntityEyePos(entity)

    if entity.GetEyePos then
        return entity:GetEyePos()
    end
    return (HasMixin(entity, "Model") and entity:GetModelOrigin()) or entity:GetOrigin()
    
end

/**
 * Not all Entities have view angles. Play it safe.
 */
function GetEntityViewAngles(entity)
    return (entity.GetViewAngles and entity:GetViewAngles()) or entity:GetAngles()
end

function GetEntityInfo(entity)

    local entInfo = entity:GetClassName() .. " | " .. entity:GetId() .. "\n"
    local entMT = getmetatable(entity)
    local className, properties = entMT.__towatch(entity)
    for key, val in pairs(properties) do
        entInfo = entInfo .. key .. " = " .. ToString(val) .. "\n"
    end
    return entInfo
    
end