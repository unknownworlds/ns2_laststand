//======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PathingUtility.lua
//
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)
//
// Pathing-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

gDebugPathing = false

// Script based pathing flags

kLastFlag = Pathing.PolyFlag_Infestation

Pathing.PolyFlag_Infestation =  bit.lshift(Pathing.PolyFlag_NoBuild, 2)

// Global Pathing Options
local gPathingOptions = {}

function IntializeDefaultPathingOptions()

    gPathingOptions[Pathing.Option_CellSize]         = 0.26         // Grid cell size
    gPathingOptions[Pathing.Option_CellHeight]       = 0.40         // Grid cell height
    gPathingOptions[Pathing.Option_AgentHeight]      = 2.0          // Minimum height where the agent can still walk
    gPathingOptions[Pathing.Option_AgentRadius]      = 0.6          // Radius of the agent in cells
    gPathingOptions[Pathing.Option_AgentMaxClimb]    = 0.9          // Maximum height between grid cells the agent can climb
    gPathingOptions[Pathing.Option_AgentMaxSlope]    = 45.0         // Maximum walkable slope angle in degrees.
    gPathingOptions[Pathing.Option_RegionMinSize]    = 8            // Regions whose area is smaller than this threshold will be removed. 
    gPathingOptions[Pathing.Option_RegionMergeSize]  = 20           // Regions whose area is smaller than this threshold will be merged 
    gPathingOptions[Pathing.Option_EdgeMaxLen]       = 12.0         // Maximum contour edge length 
    gPathingOptions[Pathing.Option_EdgeMaxError]     = 1.3          // Maximum distance error from contour to cells 
    gPathingOptions[Pathing.Option_VertsPerPoly]     = 6.0          // Max number of vertices per polygon
    gPathingOptions[Pathing.Option_DetailSampleDist] = 6.0          // Detail mesh sample spacing.
    gPathingOptions[Pathing.Option_DetailSampleMaxError] = 1.0      // Detail mesh simplification max sample error.
    gPathingOptions[Pathing.Option_TileSize]         = 16           // Width and Height of a tile 
    
end

// Call this function as to make sure stuff gets intialized
IntializeDefaultPathingOptions()

function SetPathingOption(option, value)
    gPathingOptions[option] = value
end

function GetPathingOption(option)
    return gPathingOptions[option]
end

function GetPathingOptions()
    return gPathingOptions
end

// Function that does everything for the building of the mesh
function InitializePathing()

    Pathing.SetOptions(GetPathingOptions())
    Pathing.BuildMesh()
    
end

function ParsePathingSettings(settings)

    // override this setting - anything larger causes huge perf spikes in pathing
    local maxOptionTileSize = 36
    if settings.option_tile_size > maxOptionTileSize then
        Print("Warning: Overriding map's pathing_settings.option_tile_size from %d to %d", settings.option_tile_size, maxOptionTileSize);
        settings.option_tile_size = maxOptionTileSize
    end

    SetPathingOption(Pathing.Option_CellSize, settings.option_cell_size)
    SetPathingOption(Pathing.Option_CellHeight, settings.option_cell_height)
    SetPathingOption(Pathing.Option_AgentHeight, settings.option_agent_height)
    SetPathingOption(Pathing.Option_AgentRadius, settings.option_agent_radius)
    SetPathingOption(Pathing.Option_AgentMaxClimb, settings.option_agent_max_climb)
    SetPathingOption(Pathing.Option_AgentMaxSlope, settings.option_agent_max_slope)
    SetPathingOption(Pathing.Option_RegionMinSize, settings.option_region_min_size)
    SetPathingOption(Pathing.Option_RegionMergeSize, settings.option_region_merge_size)
    SetPathingOption(Pathing.Option_EdgeMaxLen, settings.option_edge_max_len)
    SetPathingOption(Pathing.Option_EdgeMaxError, settings.option_edge_max_error)
    SetPathingOption(Pathing.Option_VertsPerPoly, settings.option_verts_per_poly)
    SetPathingOption(Pathing.Option_DetailSampleDist, settings.option_detail_sample_dist)
    SetPathingOption(Pathing.Option_DetailSampleMaxError, settings.option_detail_sample_max_error)
    SetPathingOption(Pathing.Option_TileSize, settings.option_tile_size)
    
end

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
function SmoothPathPoints(points, maxDistance, maxPoints)

    PROFILE("PathingUtility:SmoothPathPoints")
    
    local numPoints   = #points    
    local maxPoints   = maxPoints
    numPoints = math.min(maxPoints, numPoints)    
    local i = 1
    while i < numPoints do
        
        local point1 = points[i]
        local point2 = points[i + 1]

        // If the distance between two points is large, add intermediate points
        
        local delta = point2 - point1
        local distance = delta:GetLength()
        local numNewPoints = math.floor(distance / maxDistance)
        local p = 0
        
        for j = 1, numNewPoints do

            local f = j / numNewPoints
            local newPoint = point1 + delta * f
            if table.find(points, newPoint) == nil then
            
                i = i + 1
                table.insert( points, i, newPoint )
                p = p + 1
                
            end                     
        end 
        i = i + 1    
        numPoints = numPoints + p        
    end
    
end

// Take list of points and return only the points needed to construct a path of no more than maxDistance 
// units apart. Doesn't include start point.
function SplitPathPoints(startPoint, points, maxDistance)

    local splitPoints = {}
    
    local fromPoint = startPoint

    for index, point in ipairs(points) do
    
        local dist = (point - fromPoint):GetLength()
        
        if dist > maxDistance then
        
            // If the first point is more then maxDistance from start, add it (the best it can do)
            if not lastPoint then
                lastPoint = point
            end
        
            table.insert(splitPoints, lastPoint)        
            
            // Now we're checking distance from this added point
            fromPoint = lastPoint
            
        end
        
        lastPoint = point
    
    end
    
    return splitPoints

end

function TraceEndPoint(src, dst, trace, skinWidth)

    local delta    = dst - src
    local distance = delta:GetLength()
    local fraction = trace.fraction
    fraction = Math.Clamp( fraction + (fraction - 1.0) * skinWidth / distance, 0.0, 1.0 )
    
    return src + delta * fraction

end

/**
 * Returns a list of point connecting two points together. If there's no path, returns nil.
 */
local function InternalGeneratePath(src, dst, doSmooth, smoothDist, maxSplitPoints, allowFlying) 
    
    if not smoothDist then
        smoothDist = 0.5
    end

    if not maxSplitPoints then
        maxSplitPoints = 2
    end
    
    local mask = CreateMaskExcludingGroups(PhysicsGroup.SmallStructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)    
    local climbAmount   = ConditionalValue(allowFlying, 0.4, 0.0)   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { }    
    
    // Query the pathing system for the path to the dst
    // if fails then fallback to the old system
    local isReachable = Pathing.GetPathPoints(src, dst, points)     

    if gDebugPathing then
        Print("Pathing.GetPathPoints() isReachable = %s", ToString(isReachable))
        Print("----- points -------")
        for _, point in ipairs(points) do
            Print(ToString(point))
        end
        Print("--------------------")
    end 
    
    if #points ~= 0 and isReachable then      
        if (doSmooth) then
           SmoothPathPoints( points, smoothDist, maxSplitPoints) 
        end
        return points
    end

    if gDebugPathing then
        Print("pathing failed after %s iterations", ToString(maxIterations))
    end
            
    return points

end

function GeneratePath(src, dst, doSmooth, smoothDist, maxSplitPoints, allowFlying)
    
    PROFILE("PathingUtility:GeneratePath") 
    
    local points = InternalGeneratePath(src, dst, doSmooth, smoothDist, maxSplitPoints, allowFlying)
    
    if gDebugPathing then
    
        if points then
            for _, point in ipairs(points) do
                DebugCapsule(point, point, 0.2, 0.2, 2)
            end
        end
    
    end
    
    return points

end

function GetPointDistance(points)
    if (points == nil) then
      return 0
    end
    local numPoints   = #points
    local distance = 0
    local i = 1
    while i < numPoints do
      if (i > 1) then    
        distance = distance + (points[i - 1] - points[i]):GetLength()
      end
      i = i + 1
    end
    
    distance = math.max(0.0, distance)
    return distance
end

function GetPathDistance(src, dst)

    local points = GeneratePath(src, dst)
    
    if points then
        return GetPointDistance(points)
    end

    return nil
    
end

local kMaxPointSearchIterations = 10
function GetRandomPointsWithinRadius(center, minRadius, maxRadius, maxHeight, numPoints, minDistance, filter, validationFunc)
    
    local points = { }
    local minDistanceSquared = minDistance * minDistance
    
    for i = 1, numPoints do

        local point = nil
        local isValid = false
        
        for j = 1, kMaxPointSearchIterations do
        
            point = Pathing.FindRandomPointAroundCircle(center, maxRadius, maxHeight)
            isValid = true
            
            // Check the point is outside the min radius.
            if point:GetDistanceSquared(center) <= (minRadius * minRadius) then
                isValid = false
            end
            
            if isValid and filter then
                isValid = filter(point)
            end
            
            if isValid then
            
                // Check minDistance.
                for k = 1, #points do
                
                    if point:GetDistanceSquared(points[k]) < minDistanceSquared then
                    
                        isValid = false
                        break
                        
                    end
                    
                end
                
            end
            
            if isValid then
                break
            end
            
        end
        
        if isValid and (not validationFunc or validationFunc(point)) then
            table.insert(points, point)
        end
        
    end
    
    return points
    
end