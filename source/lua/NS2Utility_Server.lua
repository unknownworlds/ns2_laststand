//======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Utility_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Server-side NS2-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

function SetAlwaysRelevantToCommander(unit, relevant)
    
    local includeMask = 0
    
    if relevant then
    
        if not HasMixin(unit, "Team") then
            includeMask = bit.bor(kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        elseif unit:GetTeamNumber() == 1 then
            includeMask = kRelevantToTeam1Commander
        elseif unit:GetTeamNumber() == 2 then
            includeMask = kRelevantToTeam2Commander
        end
    end
    
    unit:SetIncludeRelevancyMask( includeMask )
    
end    

function PushPlayersInRange(origin, range, impulseStrength, team)

    local players = GetEntitiesForTeamWithinRange("Player", team, origin, range)
    
    for _, player in ipairs(players) do
    
        player:AddPushImpulse(GetNormalizedVector( player:GetOrigin() - origin)  * impulseStrength)
    
    end

end

local gLastHitEffectCounterReset = 0
local gCurrentNumHitEffects = 0

function GetShouldSendHitEffect()

    if gLastHitEffectCounterReset + 1 < Shared.GetTime() then
        gLastHitEffectCounterReset = Shared.GetTime()
        gCurrentNumHitEffects = 0
    end
    
    gCurrentNumHitEffects = gCurrentNumHitEffects + 1

    return gCurrentNumHitEffects < kMaxHitEffectsPerSecond

end

local kUp = Vector(0, 1, 0)

function CreateEntityForTeam(techId, position, teamNumber, player)

    local newEnt = nil
    
    local mapName = LookupTechData(techId, kTechDataMapName)
    if mapName ~= nil then
    
        // Allow entities to be positioned off ground (eg, hive hovers over tech point)        
        local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, 0)
        local spawnHeightPosition = Vector(position.x,
                                           position.y + spawnHeight,
                                           position.z)
        
        newEnt = CreateEntity( mapName, spawnHeightPosition, teamNumber )
        
        // Hook it up to attach entity
        local attachEntity = GetAttachEntity(techId, position)    
        if attachEntity then    
            newEnt:SetAttached(attachEntity)        
        end
        
    else
        Print("CreateEntityForTeam(%s): Couldn't kTechDataMapName for entity.", EnumToString(kTechId, techId))
        assert(false)    
    end
    
    return newEnt
    
end

// 6 players means 0 reduction in time, under 6 players respawn scalar is below 1
local kPlayerNumBase = 6
local kPlayerNumMax = 16
local kOverSizeExponent = 1.1
local kMinTimeFraction = 0.1
local kTimeReductionMultiplier = 2
function GetPlayerSizeBasedRespawnTime(team, defaultTime)

    local numPlayer = team:GetNumPlayers()
    local overSize = math.max(0, numPlayer - kPlayerNumBase)
    
    if overSize == 0 then
        return defaultTime
    end    
    
    local overSizeFraction = (overSize / kPlayerNumMax) 
    local timeReduction = (overSizeFraction ^ kOverSizeExponent) * defaultTime * kTimeReductionMultiplier
    
    local spawnTime = math.max(kMinTimeFraction * defaultTime, defaultTime - timeReduction)
    
    //Print("timeReduction : %s", ToString(timeReduction))
    //Print("spawnTime: %s", ToString(spawnTime))
    
    return spawnTime

end

function CreateEntityForCommander(techId, position, commander)

    local newEnt = CreateEntityForTeam(techId, position, commander:GetTeamNumber(), commander)
    ASSERT(newEnt ~= nil, "Didn't create entity for techId: " .. EnumToString(kTechId, techId))
    
    // It is possible the new entity was created in a spot where it was instantly destroyed.
    if newEnt:GetIsDestroyed() then
        newEnt = nil
    end
    
    if newEnt then
    
        newEnt:SetOwner(commander)
        UpdateInfestationMask(newEnt)
        
    end
    
    return newEnt
    
end

// returns a time fraction of the passed base time
function GetAlienCatalystTimeAmount(baseTime, entity)

    if HasMixin(entity, "Catalyst") then
        
        local catalystTime = entity:GetCatalystScalar() * baseTime * (1 + kNutrientMistPercentageIncrease/100)
        return catalystTime
        
    end    
    
    return 0
    
end

// Assumes position is at the bottom center of the egg
function GetCanEggFit(position)

    local extents = LookupTechData(kTechId.Egg, kTechDataMaxExtents)
    local maxExtentsDimension = math.max(extents.x, extents.y)
    ASSERT(maxExtentsDimension > 0, "invalid x extents for")

    local eggCenter = position + Vector(0, extents.y + .05, 0)

    local filter = nil
    local physicsMask = PhysicsMask.AllButPCs
    
    if not Shared.CollideBox(extents, eggCenter, CollisionRep.Default, physicsMask, filter) then
            
        return true
                    
    end
    
    return false
    
end

// Don't spawn eggs on railings or edges of steps, etc. Check each corner of the egg to make 
// sure the heights are all about the same
function GetFullyOnGround(position, maxExtentsDimension, numSlices, variationAllowed)

    ASSERT(type(maxExtentsDimension) == "number")
    ASSERT(maxExtentsDimension > 0)
    ASSERT(type(numSlices) == "number")
    ASSERT(numSlices > 1)
    ASSERT(type(variationAllowed) == "number")
    ASSERT(variationAllowed > 0)

    function GetGroundHeight(position)

        local trace = Shared.TraceRay(position, position - kUp, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(nil))
        return position.y - trace.fraction
        
    end
    
    
    // Get height of surface underneath center of egg
    local centerHeight = GetGroundHeight(position)
    
    // Make sure center isn't overhanging
    if math.abs(centerHeight - position.y) > variationAllowed then    
    
        return false        
        
    end

    // Four slices, in radius around edge of egg    
    for index = 1, numSlices do
        
        local angle = (index / numSlices) * math.pi * 2        
        local xOffset = math.cos(angle) * maxExtentsDimension
        local zOffset = math.sin(angle) * maxExtentsDimension
        
        local edgeHeight = GetGroundHeight(position + Vector(xOffset, 0, zOffset))
        
        if math.abs(edgeHeight - centerHeight) > variationAllowed then
        
            return false
            
        end
        
    end
    
    return true
    
end

// Assumes position is at the bottom center of the egg
function GetIsPlacementForTechId(position, checkInfestation, techId)

    local extents = Vector(LookupTechData(techId, kTechDataMaxExtents, Vector(0.4, 0.4, 0.4)))
    local center = position + Vector(0, extents.y, 0)
    
    if not Shared.CollideBox(extents, center, CollisionRep.Move, PhysicsMask.All, nil) then
    
        local maxExtentsDimension = math.max(extents.x, extents.z)
        ASSERT(maxExtentsDimension > 0, "invalid x extents for")
        
        if GetFullyOnGround(position, maxExtentsDimension, 4, 0.5) then
        
            if not checkInfestation or GetIsPointOnInfestation(position) then
                return true
            end
            
        end
        
    end
    
    return false
    
end

local kBigUpVector = Vector(0, 1000, 0)
local function CastToGround(pointToCheck, height, radius, filterEntity)

    local filter = EntityFilterOne(filterEntity)
    
    local extents = Vector(radius, height * 0.5, radius)
    trace = Shared.TraceBox( extents, pointToCheck, pointToCheck - kBigUpVector, CollisionRep.Move, PhysicsMask.All, filter)
    
    if trace.fraction ~= 1 then
    
        // Check the start point is not colliding.
        if not Shared.CollideBox(extents, trace.endPoint, CollisionRep.Move, PhysicsMask.All, filter) then
            return trace.endPoint - Vector(0, height * 0.5, 0)
        end
        
    end
    
    return nil
    
end

// Find random spot near hive that we could put an egg. Allow spawn points that are on the other side of walls
// but pathable. Returns point on ground.
local function FindPlaceForTechId(filterEntity, origin, techId, minRange, maxRange, checkPath, maxVerticalDistance)

    PROFILE("NS2Utility:FindPlaceForTechId")
    
    local extents = LookupTechData(techId, kTechDataMaxExtents, Vector(0.4, 0.4, 0.4))
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    
    // Find random spot within range, using random orientation (0 to -45 degrees)
    local randomRange = minRange + math.random() * (maxRange - minRange)
    
    local randomRadians = math.random() * math.pi * 2
    local randomHeight = -math.random() * 3
    local randomPoint = Vector(origin.x + randomRange * math.cos(randomRadians),
                               origin.y + randomHeight,
                               origin.z + randomRange * math.sin(randomRadians))
    
    local pointToUse = CastToGround(randomPoint, capsuleHeight, capsuleRadius, filterEntity)
    if pointToUse then
    
        if checkPath then
        
            local pathPoints = { }
            local hasPathToPoint = Pathing.GetPathPoints(origin, pointToUse, pathPoints)
            
            // This path is invalid if no path was found or the last path point was not the
            // exact point we were looking for.
            if not hasPathToPoint or #pathPoints == 0 or pathPoints[#pathPoints] ~= pointToUse then
                return nil
            end
            
        end
        
        if maxVerticalDistance then
        
            if math.abs(origin.y - pointToUse.y) > maxVerticalDistance then
                return nil
            end
            
        end
        
        return pointToUse
        
    end
    
    return nil
    
end

function CalculateRandomSpawn(filterEntity, origin, techId, checkPath, minDistance, maxDistance, maxVerticalDistance)

    PROFILE("NS2Utility:CalculateRandomSpawn")
    
    local possibleSpawn = FindPlaceForTechId(filterEntity, origin, techId, minDistance, maxDistance, checkPath, maxVerticalDistance)
    if possibleSpawn then
    
        if GetIsPlacementForTechId(possibleSpawn, false, techId) then
            return possibleSpawn
        end
        
    end
    
    return nil
    
end

// Translate from SteamId to player (returns nil if not found)
function GetPlayerFromUserId(userId)

    for index, currentPlayer in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        local owner = Server.GetOwner(currentPlayer)
        if owner and owner:GetUserId() == userId then
            return currentPlayer
        end
    end
    
    return nil
    
end

function SocketPowerForLocation(locationName)

    for index, powerPoint in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do            
    
        if powerPoint:GetLocationName() == locationName then
        
            if powerPoint:GetPowerState() == PowerPoint.kPowerState.unsocketed then
            
                powerPoint:SocketPowerNode()
                
            end
            
        end
        
    end
    
end

local function UnlockAbility(forAlien, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)
    if mapName and forAlien:GetIsAlive() then
    
        local activeWeapon = forAlien:GetActiveWeapon()

        local tierWeapon = forAlien:GetWeapon(mapName)
        if not tierWeapon then
            forAlien:GiveItem(mapName)
        end
        
        if activeWeapon then
            forAlien:SetActiveWeapon(activeWeapon:GetMapName())
        end
    
    end

end

local function LockAbility(forAlien, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)    
    if mapName and forAlien:GetIsAlive() then
    
        local tierWeapon = forAlien:GetWeapon(mapName)
        local activeWeapon = forAlien:GetActiveWeapon()
        local activeWeaponMapName = nil
        
        if activeWeapon ~= nil then
            activeWeaponMapName = activeWeapon:GetMapName()
        end
        
        if tierWeapon then
            forAlien:RemoveWeapon(tierWeapon)
        end
        
        if activeWeaponMapName == mapName then
            forAlien:SwitchWeapon(1)
        end
        
    end    
    
end

function UpdateAbilityAvailability(forAlien, tierTwoTechId, tierThreeTechId)

    local time = Shared.GetTime()
    if forAlien.timeOfLastNumHivesUpdate == nil or (time > forAlien.timeOfLastNumHivesUpdate + 0.5) then

        local team = forAlien:GetTeam()
        if team and team.GetTechTree then
        
            local hasTwoHivesNow = GetGamerules():GetAllTech() or (tierTwoTechId ~= nil and tierTwoTechId ~= kTechId.None and GetHasTech(forAlien, tierTwoTechId, true))
            local hadTwoHives = forAlien.twoHives
            // Don't lose abilities unless you die.
            forAlien.twoHives = forAlien.twoHives or hasTwoHivesNow

            if forAlien.twoHives then
                UnlockAbility(forAlien, tierTwoTechId)
            else
                LockAbility(forAlien, tierTwoTechId)
            end
            
            local hasThreeHivesNow = GetGamerules():GetAllTech() or (tierThreeTechId ~= nil and tierThreeTechId ~= kTechId.None and GetHasTech(forAlien, tierThreeTechId, true))
            local hadThreeHives = forAlien.threeHives
            // Don't lose abilities unless you die.
            forAlien.threeHives = forAlien.threeHives or hasThreeHivesNow

            if forAlien.threeHives then
                UnlockAbility(forAlien, tierThreeTechId)
            else
                LockAbility(forAlien, tierThreeTechId)
            end
            
        end
        
        forAlien.timeOfLastNumHivesUpdate = time
        
    end

end
