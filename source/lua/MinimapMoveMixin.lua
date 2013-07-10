// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// 	lua\MinimapMoveMixin.lua    
//    
//    Created by:   Marc Delorme (marc@unknownworlds.com)
//
//    REQUIRE: OverheadMoveMixin
//    Move the player in overhead mode when he click on the minimap
//    
// =========== For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/OverheadMoveMixin.lua")

MinimapMoveMixin = CreateMixin( MinimapMoveMixin )
MinimapMoveMixin.type = "MinimapMove"

MinimapMoveMixin.expectedMixin =
{
    OverheadMove = ""
}

MinimapMoveMixin.expectedCallbacks =
{
}

MinimapMoveMixin.expectedConstants =
{
}

/**
 * Player's position on the floor is different of the
 * screen center's position on the floor ()
 *
 * Return the absolute value of the offset
 */
local function GetScreenCenterPositionOffset(self)

	local height = self:GetMixinConstant("kDefaultHeight")
	local pitch  = self:GetViewAngles().pitch

	return math.abs( height / math.tan(pitch) ) 


end

/**
 * Move the player when he click on de minimap
 */
function MinimapMoveMixin:UpdateMove(input)

    if bit.band(input.commands, Move.Minimap) ~= 0 then
    
        local position  = Vector()
        local heightmap = GetHeightmap()
        
        position.x = heightmap:GetWorldX(input.pitch) - GetScreenCenterPositionOffset(self)
        position.z = heightmap:GetWorldZ(input.yaw)
        position = self:ConstrainToOverheadPosition(position)
        
        self:SetOrigin(position)
        
    end
    
end

// Coords coming in are in terms of playable width and height
// Ie, not 0,0 to 1,1 most of the time, but for a vertical map, perhaps 0 to .4 for xc
// and 0 to 1 for yc.
function OverheadUI_MapMoveView(xc, yc)

    // Scroll map with left-click
    local player = Client.GetLocalPlayer()        
    local normX, normY = GetMinimapNormCoordsFromPlayable(GetHeightmap(), xc, yc)
    
    player:SetScrollPosition(normX, normY)

end

// Called when commander is jumping to a world position (jumping to an alert, etc.).
function MinimapMoveMixin:SetWorldScrollPosition(x, z)

    local heightmap = GetHeightmap()
    if heightmap then
    
        self.minimapNormX = heightmap:GetMapX(z)
        self.minimapNormY = heightmap:GetMapY(x)
        self.setScrollPosition = true
        
    end
    
end

// Called when minimap is clicked or scrolled. 0, 0 is upper left, 1, 1 is lower right.
function MinimapMoveMixin:SetScrollPosition(x, y)

    local heightmap = GetHeightmap()
    if heightmap then
    
        self.minimapNormX = x
        self.minimapNormY = y
        
        self.setScrollPosition = true
        
    end
    
end

function OverheadUI_MapImage()
    return "map"
end

/**
 * Return width of view in geometry space.
 */
function OverheadUI_MapViewWidth()
    return 1
end

/**
 * Return height of view in geometry space.
 */
function OverheadUI_MapViewHeight()
    return 1
end

/**
 * Return x center of view in geometry coordinate space.
 */
function OverheadUI_MapViewCenterX()
    local player = Client.GetLocalPlayer()
    return player:GetScrollPositionX()
end

/**
 * Return y center of view in geometry coordinate space
 */
function OverheadUI_MapViewCenterY()
    local player = Client.GetLocalPlayer()
    return player:GetScrollPositionY()
end

/**
 * Return horizontal scale (geometry/pixel)       
 */
function OverheadUI_MapLayoutHorizontalScale()
    return GetMinimapHorizontalScale(GetHeightmap())
end

/**
 * Return vertical scale (geometry/pixel).
 */
function OverheadUI_MapLayoutVerticalScale()
    return GetMinimapVerticalScale(GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function OverheadUI_MapLayoutPlayableWidth()
    return GetMinimapPlayableWidth(GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function OverheadUI_MapLayoutPlayableHeight()
    return GetMinimapPlayableHeight(GetHeightmap())
end

// x and y are the normalized map coords just like OverheadUI_MapMoveView(xc, yc).
// button is 0 for LMB, 1 for RMB
// Index is the button index whose targeting mode we're in (only if button == 0, nil otherwise)
function OverheadUI_MapClicked(x, y, button, index)

    // Translate minimap coords to world position
    local player = Client.GetLocalPlayer()
    local worldCoords = MinimapToWorld(player, x, y)
    
    if PlayerUI_IsACommander() then
    
        if button == 0 then

            if index ~= nil then

                player:SendTargetedActionWorld(GetTechIdFromButtonIndex(index), worldCoords)
                
            else
                Print("OverheadUI_MapClicked(x, y, button, index) called with button 0 and no button index.")
            end        
            
        // Give default order with right-click
        elseif button == 1 then

            player:SendTargetedActionWorld(kTechId.Default, worldCoords)
            player.timeMinimapRightClicked = Shared.GetTime()
                
        end
        
    end
    
end

/**
 * Returns the overhead view far frustum plane points in world space.
 */
function OverheadUI_ViewFarPlanePoints()

    local player = Client.GetLocalPlayer()
    
    local camera = Camera()
    camera:SetType(Camera.Perspective)
    local cameraCoords = player:GetCameraViewCoords()
    camera:SetCoords(cameraCoords)
    camera:SetFov(player:GetRenderFov())
    
    local heightmap = GetHeightmap()
    
    // Find the ground elevation.
    local groundConstant = 11.5
    local elevation = heightmap:GetElevation(cameraCoords.origin.x, cameraCoords.origin.z) - groundConstant
    local planePoint = Vector(cameraCoords.origin.x, elevation, cameraCoords.origin.z)
    local planeNormal = GetNormalizedVector(cameraCoords.origin - planePoint)
    
    local frustum = Client.GetCameraFrustum(camera)
    
    local topLeftLine = frustum:GetPoint(4) - frustum:GetPoint(0)
    local topLeftPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(0), GetNormalizedVector(topLeftLine))
    
    local topRightLine = frustum:GetPoint(7) - frustum:GetPoint(3)
    local topRightPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(3), GetNormalizedVector(topRightLine))
    
    local bottomLeftLine = frustum:GetPoint(5) - frustum:GetPoint(1)
    local bottomLeftPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(1), GetNormalizedVector(bottomLeftLine))
    
    local bottomRightLine = frustum:GetPoint(6) - frustum:GetPoint(2)
    local bottomRightPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(2), GetNormalizedVector(bottomRightLine))
    
    if topLeftPoint == nil or topRightPoint == nil or bottomLeftPoint == nil or bottomRightPoint == nil then
        return
    end
    
    ASSERT(topLeftPoint.z < topRightPoint.z)
    ASSERT(bottomLeftPoint.z < bottomRightPoint.z)
    ASSERT(topLeftPoint.x > bottomLeftPoint.x)
    ASSERT(topRightPoint.x > bottomRightPoint.x)
    
    return topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint
    
end