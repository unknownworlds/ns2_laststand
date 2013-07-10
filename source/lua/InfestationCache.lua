// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfestationCache.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Caches positions of infestation blobs based on infestation patch position.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Infestation_Client_SparserBlobPatterns.lua")

class 'InfestationCache'

local kBlobGenNum = 50
local kMaxIterations = 16

gInfestationCache = gInfestationCache or InfestationCache()

local function random(min, max)
    return math.random() * (max - min) + min
end

local function TraceBlobSpaceRay(x, z, hostCoords)

    local checkDistance = 2
    local startPoint = hostCoords.origin + hostCoords.yAxis * checkDistance / 2 + hostCoords.xAxis * x + hostCoords.zAxis * z
    local endPoint   = startPoint - hostCoords.yAxis * checkDistance
    return Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, EntityFilterAll())
    
end

local function GetBlobPlacement(x, z, xRadius, hostCoords)

    local trace = TraceBlobSpaceRay(x, z, hostCoords)
    
    // No geometry to place the blob on
    if trace.fraction == 1 then
        return nil
    end
    
    local position = trace.endPoint
    local averageNormal = Vector(0,0,0)

    // Trace some rays to determine the average position and normal of
    // the surface the blob will cover.    
    
    local numTraces = 3
    local numHits   = 0
    local point = { }
    
    local maxDistance = 2
    
    for i=1,numTraces do
    
        local q = ((i - 1) * math.pi * 2) / numTraces
        local xOffset = math.cos(q) * xRadius * 1
        local zOffset = math.sin(q) * xRadius * 1
        local randTrace = TraceBlobSpaceRay(x + xOffset, z + zOffset, hostCoords)
        
        if randTrace.fraction == 1 or (randTrace.endPoint - position):GetLength() > maxDistance then
            return nil
        end
        
        point[i] = randTrace.endPoint
        averageNormal = averageNormal + randTrace.normal
    
    end
 
    local normal = Math.CrossProduct( point[3] - point[1], point[2] - point[1] ):GetUnit()
    if normal:DotProduct(averageNormal) < 0 then
        normal:Scale(-1)
    end
    
    return position, normal

end

local function GenerateBlobCoords(infestation)

    PROFILE("InfestationCache:GenerateBlobCoords")
    
    local blobCoords = {}
   
    local xOffset = 0
    local zOffset = 0
    local maxRadius = infestation:GetMaxRadius()
    local hostCoords = infestation:GetCoords()
    local blobGenNum = kBlobGenNum * infestation.blobMultiplier

    for j = 1, blobGenNum do
    
        local xRadius = random(0.5, 1.5)
        local yRadius = xRadius * 0.5   // Pancakes
        
        local minRand = 0.2
        local maxRand = maxRadius - xRadius

        // Get a uniformly distributed point the circle
        local x, z
        local hasValidPoint = false
        for iteration = 1, kMaxIterations do
            x = random(-maxRand, maxRand)
            z = random(-maxRand, maxRand)
            if x * x + z * z < maxRand * maxRand then
                hasValidPoint = true
                break
            end
        end
        
        if not hasValidPoint then
            Print("Error placing blob, max radius is: %f", maxRadius)
            x, z = 0, 0
        end
        
        local position, normal = GetBlobPlacement(x, z, xRadius, hostCoords)
        
        if position then
        
            local angles = Angles(0, 0, 0)
            angles.yaw = GetYawFromVector(normal)
            angles.pitch = GetPitchFromVector(normal) + (math.pi / 2)
            
            local normalCoords = angles:GetCoords()
            normalCoords.origin = position
            
            local coords = CopyCoords(normalCoords)
            
            coords.xAxis  = coords.xAxis * xRadius
            coords.yAxis  = coords.yAxis * yRadius
            coords.zAxis  = coords.zAxis * xRadius

            table.insert(blobCoords, coords)
            
        end
    
    end
    
    return blobCoords

end

local function GetPositionId(self, position)
    
    if not self.positionIds then
        self.positionIds = {}
    end

    for i = 1, #self.positionIds do
        
        if self.positionIds[i] == position then
            return i
        end
        
    end
    
    // create new id
    table.insert(self.positionIds, Vector(position))
    return #self.positionIds
    
end

function InfestationCache:GetBlobCoords(infestation)

    PROFILE("InfestationCache:GetBlobCoords")

    local coords = infestation:GetCoords()
    if not self.cachedBlobCoords then
        self.cachedBlobCoords = {}
    end
    
    local id = GetPositionId(self, coords.origin)
    
    if not self.cachedBlobCoords[id] then        
        self.cachedBlobCoords[id] = GenerateBlobCoords(infestation)        
    end
    
    return self.cachedBlobCoords[id]

end