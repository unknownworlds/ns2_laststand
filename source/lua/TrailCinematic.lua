// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TrailCinematic.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Displays and updates a trail of cinematics. Multiple cinematics will bend.
//    Make sure that entities always call Client.DestroyTrailCinematic in OnDestroy.
//
//    segment.cinematic: the cinmatic handle of this segment
//    segment.coords: the coords of this segment
//    
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'TrailCinematic'

TRAIL_ALIGN_X = 1
TRAIL_ALIGN_Y = 2
TRAIL_ALIGN_Z = 3
TRAIL_ALIGN_MOVE = 4 // will align based on origin point movement
TRAIL_NO_ALIGN = 5

// re-use vectors for TrailCinematic:Update
local newOrigin = Vector()
local difference = Vector()
local desiredPos = Vector()
local endPoint = Vector()

local adjustedCoords = Coords.GetIdentity()
local baseCoords = Coords.GetIdentity()

function TrailCinematic:Initialize(renderZone)
    
    self.renderZone = renderZone
    self.repeatStyle = Cinematic.Repeat_Loop    
    self.segments = nil
    self.cinematicNames = {}
    self.timeOfVisibilityChange = 0
    self.attachedToId = Entity.invalidId
    self.attachPointName = nil
    self.attachOffset = Vector(0,0,0)
    self.visible = true
    self.alignAxis = TRAIL_ALIGN_Z
    self.attachFunc = nil
    self.lastLengthFraction = 1.0
    self.lastPosition = nil
    
    // options:
    self.numSegments = 6
    self.collidesWithWorld = false
    self.alignAngles = true
    self.visibilityChangeDuration = 0.4
    self.fadeOutCinematics = false
    self.trailLength = 5
    self.maxLength = 20
    self.stretchTrail = true
    self.trailWeight = 0
    self.minHardening = 0.05
    self.maxHardening = 1
    self.hardeningModifier = 0.2
    
    self.segmentWeight = {}
    
end

// we only fill up the table here
function TrailCinematic:_InitSegments()

    self.segments = {}

    for i = 1, self.numSegments do        
        table.insert(self.segments, { cinematic = nil, coords = Coords(), visible = false })        
    end

end

// pass a table of precached cinematics which will be evenly distrubed to segment 1 - x
function TrailCinematic:SetCinematicNames(cinematicNames)
    self.cinematicNames = cinematicNames
end

function TrailCinematic:SetFadeOutCinematicNames(cinematicNames)
    self.fadeOutCinematicNames = cinematicNames
end    

// manually trigger (re-) loading of cinematics
function TrailCinematic:LoadCinematics()

    if not self.segments then
        self:_InitSegments()
    end
    
    for index, segment in ipairs(self.segments) do
    
        if segment.cinematic then
            Client.DestroyCinematic(segment.cinematic)
            segment.cinematic = nil
        end
        
        self:_CreateSegmentCinematic(index)
    
    end

end

function TrailCinematic:SetRepeatStyle(repeatStyle)
    self.repeatStyle = repeatStyle
end    

function TrailCinematic:GetIsVisible()
    return self.visible
end

function TrailCinematic:SetIsVisible(visible)
    
    if self.visible ~= visible then
    
        self.timeOfVisibilityChange = Client.GetTime()
        self.visible = visible
    
    end
    
end

function TrailCinematic:GetIsVisible()
    return self.visible
end

// sets the options for the trail:
// **************************************************************************************************************************************************************************
// optionTable.numSegments              "integer"           number of segments in the trail
// optionTable.collidesWithWorld        "boolean"           cinematics will stack up at the end if the trail collides with the world
// optionTable.alignAngles              "boolean"           cinematics will align angles
// optionTable.visibilityChangeDuration "float"             time it takes to change visibility of the trail (starts at first segment)
// optionTable.fadeOutCinematics        "boolean"           if fade out is true, cinematics will be recreated everytime visiblity changes to true or to false then set them to Repeat_None and reject handle
// optionTable.trailLength              "float"             total length of the trail
// optionTable.stretchTrail             "boolean"           the trail will exceed the total length and stretches
// optionTable.trailWeight              "float"             weight of the trail. Segments closer to the end will have more weight applied to them (Y values reduced
// optionTable.maxLength           "float"
// 
// following 3 options control the bending of the trail. minHardening is applied to the last segment (higher values will make the trail stiff) and is interpolated
// to maxHardening for the first segments. hardeningModifier is multiplied with the result
// optionTable.hardeningModifier        "float"             
// optionTable.minHardening             "float"
// optionTable.maxHardening             "float"
// **************************************************************************************************************************************************************************
function TrailCinematic:SetOptions(optionTable)

    // to prevent nil values
    self.collidesWithWorld = ConditionalValue(optionTable.collidesWithWorld ~= nil, optionTable.collidesWithWorld, false)
    self.alignAngles = ConditionalValue(optionTable.alignAngles ~= nil, optionTable.alignAngles, true)
    self.visibilityChangeDuration = ConditionalValue(optionTable.visibilityChangeDuration ~= nil, optionTable.visibilityChangeDuration, 0.4)
    self.fadeOutCinematics = ConditionalValue(optionTable.fadeOutCinematics, true, false)
    self.numSegments = ConditionalValue(optionTable.numSegments ~= nil, optionTable.numSegments, 1)
    self.trailLength = ConditionalValue(optionTable.trailLength ~= nil, optionTable.trailLength, 1)
    self.stretchTrail = ConditionalValue(optionTable.stretchTrail ~= nil, optionTable.stretchTrail, true)
    self.collisionFunc = ConditionalValue(optionTable.collisionFunc ~= nil, optionTable.collisionFunc, EntityFilterAll)
    self.trailWeight = ConditionalValue(optionTable.trailWeight ~= nil, optionTable.trailWeight, 0)
    
    self.minHardening = ConditionalValue(optionTable.minHardening ~= nil and optionTable.minHardening ~= 0, optionTable.minHardening, 0.05)
    self.maxHardening = ConditionalValue(optionTable.maxHardening ~= nil, optionTable.maxHardening, 1)
    self.hardeningModifier = ConditionalValue(optionTable.hardeningModifier ~= nil, optionTable.hardeningModifier, 1)
    self.maxLength = ConditionalValue(optionTable.maxHardening ~= nil, optionTable.maxLength, 20)

end

function TrailCinematic:_InitializeLastPosition(entity)

    if entity then
        self.lastPosition = entity:GetCoords().zAxis * -1 + entity:GetOrigin()
    else 
        self.lastPosition = Vector(0,0,0)
    end    

end

// set attachCoords.origin to 0 if you want the trail be placed at the same location as the host entity
function TrailCinematic:AttachTo(entity, alignAxis, attachOffset, attachPointName)

    if entity ~= nil then
        self.attachedToId = entity:GetId()
    end
    
    self.attachPointName = attachPointName
    self.attachOffset = ConditionalValue(attachOffset ~= nil, attachOffset, Vector(0,0,0))
    self.alignAxis = ConditionalValue(alignAxis >= 1 and alignAxis <= 5, alignAxis, TRAIL_NO_ALIGN)
    
end

function TrailCinematic:AttachToFunc(entity, alignAxis, attachOffset, attachFunc)

    self.attachedToId = entity:GetId()
    self.attachFunc = attachFunc
    self.attachOffset = ConditionalValue(attachOffset ~= nil, attachOffset, Vector(0,0,0))
    self.alignAxis = ConditionalValue(alignAxis >= 1 and alignAxis <= 5, alignAxis, TRAIL_NO_ALIGN)

end

function TrailCinematic:Destroy()

    if self.segments then
        for index, segment in ipairs(self.segments) do
            Client.DestroyCinematic(segment.cinematic)
        end
        self.segments = nil
    end
    
    return true
    
end

function TrailCinematic:_CreateSegmentCinematic(index)

    local cinematicNum = Clamp(math.ceil((index / self.numSegments) * table.count(self.cinematicNames)), 1, table.count(self.cinematicNames))

    local cinematic = Client.CreateCinematic(self.renderZone)
    cinematic:SetCinematic(self.cinematicNames[cinematicNum])
    cinematic:SetRepeatStyle(self.repeatStyle)
    
    return cinematic

end

function TrailCinematic:_TriggerFadeOutCinematic(index)

    local cinematicNum = Clamp(math.ceil((index / self.numSegments) * table.count(self.fadeOutCinematicNames)), 1, table.count(self.fadeOutCinematicNames))
    
    local cinematic = Client.CreateCinematic(self.renderZone)
    cinematic:SetCinematic(self.fadeOutCinematicNames[cinematicNum])
    cinematic:SetRepeatStyle(Cinematic.Repeat_None)
    cinematic:SetCoords(self.segments[index].coords)
    
    
end

function TrailCinematic:_ShouldCheckCollision()

    local shouldCheck = false

    if not self.timeLastCollisionCheck then
        self.timeLastCollisionCheck = Client.GetTime()
    end
    
    if self.timeLastCollisionCheck + 0.1 < Client.GetTime() then
        shouldCheck = true
        self.timeLastCollisionCheck = Client.GetTime()
    end
    
    return shouldCheck

end

function TrailCinematic:SetSegmentWeight(index, weight)
    self.segmentWeight[index] = weight
end

// update the position and angles
function TrailCinematic:Update(deltaTime)

    baseCoords = self:_GetBaseCoords(deltaTime)
    
    // apply the attach offset
    baseCoords.origin = baseCoords:TransformPoint(self.attachOffset)
    
    if self.alignAxis == TRAIL_ALIGN_Z then
        direction = baseCoords.zAxis
        endPoint = baseCoords.origin + baseCoords.zAxis * self.trailLength
    elseif self.alignAxis == TRAIL_ALIGN_X then
        direction = baseCoords.xAxis
        endPoint = baseCoords.origin + baseCoords.xAxis * self.trailLength
    elseif self.alignAxis == TRAIL_ALIGN_Y then
        direction = baseCoords.yAxis
        endPoint = baseCoords.origin + baseCoords.yAxis * self.trailLength
    elseif self.alignAxis == TRAIL_ALIGN_MOVE then
    
        if not self.lastPosition then
            self:_InitializeLastPosition(Shared.GetEntity(self.attachedToId))
        end
    
        direction = self.lastPosition - baseCoords.origin
        direction:Normalize()
        endPoint =  baseCoords.origin + direction * self.trailLength
    end
    
    // create a trace ray to check if the trail would collide with the world. this modifies the desired positions
    if self.collidesWithWorld and self:_ShouldCheckCollision() then    
        local trace = Shared.TraceRay(baseCoords.origin, endPoint, CollisionRep.Default, PhysicsMask.Bullets, self.collisionFunc())
        self.lastLengthFraction = trace.fraction - 1 / self.numSegments
    end
    
    local shouldReset = false
    
    if self.segments == nil then
        self:_InitSegments()
        shouldReset = true
    end
    
    local totalLength = self.trailLength * self.lastLengthFraction
    local segmentLength = totalLength / (self.numSegments - 1)
    
    // update segment positions
    for index, segment in ipairs(self.segments) do

        self:_UpdateSegmentVisible(index)
    
        if index == 1 then
        
            if #self.segments == 1 then
                baseCoords.zAxis = direction
                baseCoords.xAxis = baseCoords.yAxis:CrossProduct(baseCoords.zAxis)
                baseCoords.yAxis = baseCoords.xAxis:CrossProduct(baseCoords.zAxis)
            end
        
            segment.coords = CopyCoords(baseCoords)
            if segment.cinematic then
                segment.cinematic:SetCoords(segment.coords)
            end

        else
        
            // calculate the desired position (bending, stretching ignored)
            desiredPos = baseCoords.origin + direction * ( segmentLength * (index-1) )
            
            // apply some fake gravity to the segment. no complex calculations here
            if self.segmentWeight[index] then
                desiredPos.y = desiredPos.y - self.segmentWeight[index]            
            elseif self.trailWeight ~= 0 then
                desiredPos.y = desiredPos.y - ( ((index * index * 0.1)/self.numSegments) * self.trailWeight )
            end

            // apply bending factor and set new position, clamp the vector others the segments will jump around at lower fps
            difference = desiredPos - segment.coords.origin
            newOrigin = segment.coords.origin + difference * Clamp(self:_GetBend(index) * deltaTime * 40,0,1)
            segment.coords.origin = newOrigin
            
            if segment.cinematic then
                segment.cinematic:SetCoords(segment.coords)   
            end
            
            local prevSegmentOrigin = self.segments[index - 1].coords.origin
            local directionToPrev = prevSegmentOrigin - segment.coords.origin
            directionToPrev:Normalize()

            // prevent stretching
            if not self.stretchTrail and ( (prevSegmentOrigin - segment.coords.origin):GetLength() > segmentLength ) then
                segment.coords.origin = prevSegmentOrigin - directionToPrev * segmentLength
            end
            
            // adjust the angles of the previous segment            
            local angles = Angles(0,0,0)
            angles.yaw = GetYawFromVector(directionToPrev)
            angles.pitch = GetPitchFromVector(directionToPrev)
            
            adjustedCoords = angles:GetCoords()
            adjustedCoords.origin = prevSegmentOrigin
            
            self.segments[index - 1].coords = CopyCoords(adjustedCoords)
            
            if self.segments[index - 1].cinematic then
                self.segments[index - 1].cinematic:SetCoords(adjustedCoords)
            end
            
            // fit the last segment to the previous angles
            if index == self.numSegments then    
            
                segment.coords.xAxis = self.segments[index - 1].coords.xAxis
                segment.coords.yAxis = self.segments[index - 1].coords.yAxis
                segment.coords.zAxis = self.segments[index - 1].coords.zAxis

                if segment.cinematic then
                    segment.cinematic:SetCoords(segment.coords)
                end
                
            end
        
        end
    
    end
    
    self.lastPosition = baseCoords.origin

end

function TrailCinematic:_GetBend(index)

    local fraction = Clamp( 1 - ( (index - 1 ) / (self.numSegments - 1) ),  0, 1)
    return ((self.maxHardening) * fraction + self.minHardening) * self.hardeningModifier

end

function TrailCinematic:SetCoords(coords)
    self.baseCoords = coords
end

function TrailCinematic:_GetBaseCoords(deltaTime)

    local baseCoords = Coords()
    local attachedTo = Shared.GetEntity(self.attachedToId)
    
    // in case the entity does not exist anymore we destroy that cinematic. This should not happen!
    if not attachedTo and self.attachedToId ~= Entity.invalidId then
        Client.DestroyTrailCinematic(self)
    end
    
    if self.attachFunc then
    
        baseCoords = self.attachFunc(Shared.GetEntity(self.attachedToId), deltaTime)
    
    elseif attachedTo then
    
        local entityCoords = nil
        
        if self.attachPointName then
            entityCoords = attachedTo:GetAttachPointCoords(self.attachPointName)
        else
            entityCoords = attachedTo:GetCoords()
        end
        
        baseCoords.origin = entityCoords.origin
        baseCoords.xAxis = entityCoords.xAxis
        baseCoords.yAxis = entityCoords.yAxis
        baseCoords.zAxis = entityCoords.zAxis
        
    elseif self.baseCoords then
        baseCoords = self.baseCoords
    end    
    
    return baseCoords

end 

function TrailCinematic:_UpdateSegmentVisible(segmentIndex)

    local fraction =  (Client.GetTime() - self.timeOfVisibilityChange) / self.visibilityChangeDuration
    local visible = self.segments[segmentIndex].visible

    if self:GetIsVisible() and math.ceil(fraction * self.numSegments) >= segmentIndex then
        visible = true
    end

    if not self:GetIsVisible() and math.ceil(fraction * self.numSegments) >= segmentIndex then
        visible = false
    end  

    if self.segments[segmentIndex] then
    
        if self.segments[segmentIndex].visible == visible then
            return
        end    
    
        // trails that don't fade out don't destroy their cinematics
        if not self.fadeOutCinematics then
        
            if self.segments[segmentIndex].cinematic == nil then
                self.segments[segmentIndex].cinematic = self:_CreateSegmentCinematic(segmentIndex)
            end 
            self.segments[segmentIndex].cinematic:SetIsVisible(visible)
        
        // on fade out destroy the cinematic and on fade in (re-)create it
        else
        
            if visible == false then
                if self.segments[segmentIndex].cinematic ~= nil then
                    Client.DestroyCinematic(self.segments[segmentIndex].cinematic)
                    self.segments[segmentIndex].cinematic = nil
                    
                    if self.fadeOutCinematicNames then
                        self:_TriggerFadeOutCinematic(segmentIndex)
                    end
                end
            else
                if self.segments[segmentIndex].cinematic == nil then
                    self.segments[segmentIndex].cinematic = self:_CreateSegmentCinematic(segmentIndex)
                end
            end
            
        end
        
        self.segments[segmentIndex].visible = visible
        
    end

end




