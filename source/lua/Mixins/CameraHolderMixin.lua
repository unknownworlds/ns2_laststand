// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CameraHolderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

// The CameraHolderMixin provides first person camera controls and camera setup.

// The mixin will also register a "thirdperson" console command which can be used when cheats are
// enabled to switch to a third person camera. 

local kDefaultSmoothRate = 3
kTweeningFunctions = enum({ "linear", "easein", "easeout", "easein3", "easeout3","easein5", "easeout5", "easein7", "easeout7"})

local Easing = function(n, out)

    return function(x)

        if out == false or out == nil then
            return math.pow(x, n)
        else
            x = 1 - x
            return 1 - math.pow(x, n)
        end

    end
    
end

local TweeningTable = 
{
    [kTweeningFunctions.linear] = function(x)
        return x
    end,
    [kTweeningFunctions.easein] = Easing(1, false),  
    [kTweeningFunctions.easein3] = Easing(3, false),    
    [kTweeningFunctions.easein5] = Easing(5, false),
    [kTweeningFunctions.easein7] = Easing(7, false),
    [kTweeningFunctions.easeout] = Easing(1, true),
    [kTweeningFunctions.easeout3] = Easing(3, true),
    [kTweeningFunctions.easeout5] = Easing(5, true),
    [kTweeningFunctions.easeout7] = Easing(7, true)
}

Script.Load("lua/Vector.lua")
Script.Load("lua/Utility.lua")

CameraHolderMixin = { }
CameraHolderMixin.type = "CameraHolder"

CameraHolderMixin.expectedCallbacks =
{
    GetViewOffset = "Should return a Vector object representing where the camera is attached in relation to the Entity's Origin.",
    GetMaxViewOffsetHeight = "Should return the distance above the origin where the view is located"
}

CameraHolderMixin.optionalCallbacks =
{
    GetCameraViewCoordsOverride = "Overrides the GetCameraViewCoords() function completely.",
    GetPreventCameraPenetration = "Return true to cause the camera to collide with the world."
    
}

CameraHolderMixin.expectedConstants =
{
    kFov = "The default field of view."
}

CameraHolderMixin.networkVars =
{
    fov             = "private integer (0 to 180)", // In degrees.
    
    viewYaw         = "compensated interpolated angle",
    viewPitch       = "compensated interpolated angle",
    viewRoll        = "compensated interpolated angle",
    
    // Player prediction relies on this, so we network at full precision
    // so that the server and client don't have slightly different values
    // due to quantization.
    baseYaw         = "compensated float",
    
    // Third person support
    cameraDistance          = "private float",

    // Desired camera
    desiredCameraPosition   = "private vector",
    desiredCameraAngles     = "private vector",
    desiredCameraDistance   = "private float",
    desiredCameraYOffset    = "private float",
    startCameraPosition     = "private vector",
    startCameraAngles       = "private vector",
    startCameraDistance     = "private float",
    startCameraYOffset      = "private float",
    animatePosition         = "private boolean",
    animateAngles           = "private boolean",
    animateDistance         = "private boolean",
    animateYOffset          = "private boolean",
    transitionDuration      = "private float",
    transitionStart         = "private float",
    followingTransition     = "private boolean",
    moveTransition          = "private boolean",
    tweeningFunction        = "private enum kTweeningFunctions",
    
    resetMouse              = "private integer (0 to 15)",
}

function CameraHolderMixin:__initmixin()

    self.fov = self:GetMixinConstants().kFov
    
    self.viewYaw = 0
    self.viewPitch = 0
    self.viewRoll = 0
    
    self.cameraDistance = 0
    self.desiredCameraDistance = 0
    self.baseYaw = 0
    self.desiredYOffset = 0
    self.offsetSmoothRate = kDefaultSmoothRate
    self.cameraYOffset  = 0    
    self.animatePosition = false
    self.animateAngles = false
    self.animateDistance = false
    self.animateYOffset = false
    self.transitionTime = 0
    self.transitionDuration = 0
    self.tweeningFunction = kTweeningFunctions.linear
    
    self.clientResetMouse = 0
    
end

function CameraHolderMixin:SetCameraOffsetSmoothrate(smoothRate)
    self.offsetSmoothRate = smoothRate
end  
AddFunctionContract(CameraHolderMixin.SetCameraOffsetSmoothrate, { Arguments = { "Entity", "number" }, Returns = { } })  

function CameraHolderMixin:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset() + Vector(0, self.cameraYOffset, 0)
end
AddFunctionContract(CameraHolderMixin.GetEyePos, { Arguments = { "Entity" }, Returns = { "Vector" } })

function CameraHolderMixin:GetCameraViewCoords()

    local position, angles, distance, yOffset = self:GetCameraParams()
    
    local viewCoords = angles:GetCoords()
    viewCoords.origin = position + Vector(0, yOffset, 0)
    local originAtDistance = viewCoords.origin - viewCoords.zAxis * distance
    
    // Check if the host wants to avoid having the camera penetrate the world.
    if distance ~= 0 and self.GetPreventCameraPenetration and self:GetPreventCameraPenetration() then
    
        local trace = Shared.TraceRay(position, originAtDistance, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAll())
        if trace.fraction < 1 then
        
            local direction = trace.endPoint - position
            local newDistance = direction:Normalize()
            originAtDistance = trace.endPoint - (direction * 0.5)
            
        end
        
    end
    
    viewCoords.origin = originAtDistance
    
    if self.GetCameraViewCoordsOverride then
        return self:GetCameraViewCoordsOverride(viewCoords)
    end
    
    return viewCoords
    
end
AddFunctionContract(CameraHolderMixin.GetCameraViewCoords, { Arguments = { "Entity" }, Returns = { "Coords" } })

function CameraHolderMixin:IsAnimated()
    return self.animatePosition or self.animateAngles or self.animateDistance or self.animateYOffset
end

function CameraHolderMixin:GetInterpolatedCameraParams()

    local p = 1
    local f = TweeningTable[self.tweeningFunction]

    if self.transitionDuration ~= 0 then
        p = self.transitionTime / self.transitionDuration
    end
    p = f(p)
    
    local angles = (1 - p) * self.startCameraAngles + p * self.desiredCameraAngles
    local position = (1 - p) * self.startCameraPosition + p * self.desiredCameraPosition
    local distance = (1 - p) * self.startCameraDistance + p * self.desiredCameraDistance
    local yOffset = (1 - p) * self.startCameraYOffset + p * self.desiredCameraYOffset
    
    return position, Angles(angles.x, angles.y, angles.z), distance, yOffset
    
end

function CameraHolderMixin:GetCameraParams()

    local position, angles, distance, yOffset
    local iPosition, iAngles, iDistance, iYOffset
    if self.animatePosition or self.animateAngles or self.animateDistance or self.animateYOffset then
        iPosition, iAngles, iDistance, iYOffset = self:GetInterpolatedCameraParams()
    end
    
    if self.animatePosition then
        position = iPosition
    else
        position = self:GetOrigin() + self:GetViewOffset()
    end

    if self.animateAngles then
        angles = iAngles
    else
        angles = self:GetViewAngles()
    end

    if self.animateDistance then
        distance = iDistance
    else
        distance = self.cameraDistance
    end

    if self.animateYOffset then
        yOffset = iYOffset
    else
        yOffset = self.cameraYOffset
    end

    return position, angles, distance, yOffset

end

function CameraHolderMixin:GetRenderFov()

    // Convert degree to radians.
    return math.rad(self:GetFov())

end
AddFunctionContract(CameraHolderMixin.GetRenderFov, { Arguments = { "Entity" }, Returns = { "number" } })

function CameraHolderMixin:SetFov(fov)
    self.fov = fov
end
AddFunctionContract(CameraHolderMixin.SetFov, { Arguments = { "Entity", "number" }, Returns = { } })

function CameraHolderMixin:GetFov()
    return self.fov
end
AddFunctionContract(CameraHolderMixin.GetFov, { Arguments = { "Entity" }, Returns = { "number" } })

function CameraHolderMixin:GetViewAngles()
    return Angles(self.viewPitch, self.viewYaw, self.viewRoll)
end
AddFunctionContract(CameraHolderMixin.GetViewAngles, { Arguments = { "Entity" }, Returns = { "Angles" } })

/**
 * Sets the view angles for the player. Note that setting the yaw of the
 * view will also adjust the player's yaw.
 */
function CameraHolderMixin:SetViewAngles(viewAngles)

    local adjustAllowed = true
    if self.GetCanChangeViewAngles then
        adjustAllowed = self:GetCanChangeViewAngles()
    end
    
    if adjustAllowed then
        self.viewYaw = viewAngles.yaw + self.baseYaw
    end
    
    self.viewPitch = viewAngles.pitch
    self.viewRoll = viewAngles.roll

end

function CameraHolderMixin:SetOffsetAngles(offsetAngles)

    // eliminate bad values
    if offsetAngles.yaw > 2 * math.pi then
        offsetAngles.yaw = offsetAngles.yaw - 2 * math.pi
    elseif offsetAngles.yaw < 0 then
        offsetAngles.yaw = offsetAngles.yaw + 2 * math.pi
    end

    self:SetBaseViewAngles(offsetAngles)       
    self:SetViewAngles(Angles(0, 0, 0))
    self:SetAngles(Angles(0, offsetAngles.yaw, 0))

    if Server then
        self.resetMouse = (self.resetMouse + 1) % 16
    elseif Client and self == Client.GetLocalPlayer() then
        Client.SetPitch(0)
        Client.SetYaw(0)
    end

end

function CameraHolderMixin:SetBaseViewAngles(viewAngles)
    self.baseYaw = viewAngles.yaw
end

function CameraHolderMixin:GetBaseViewAngles()
    return Angles(0, self.baseYaw, 0)
end

/**
 * Whenever view angles are needed this function must be called
 * to compute them.
 */
function CameraHolderMixin:ConvertToViewAngles(forPitch, forYaw, forRoll)
    return Angles(forPitch, forYaw + self.baseYaw, forRoll)
end

function CameraHolderMixin:SetDesiredCameraDistance(distance, duration, callback)

    duration = duration or 0.3

    if self.cameraDistance ~= distance then

        if not self:IsAnimated() then
            self:SetDesiredCamera(duration, { follow = true }, nil, nil, nil, nil, callback)
        end

        self:SetCameraDistance(distance)

    end

end

function CameraHolderMixin:SetCameraDistance(distance)
    self.cameraDistance = distance
end

function CameraHolderMixin:GetCameraDistance()
    return self.cameraDistance
end

function CameraHolderMixin:GetIsThirdPerson()

    if self.animateDistance then
        return self.startCameraDistance ~= 0 or self.desiredCameraDistance ~= 0
    end
    
    return self.cameraDistance ~= 0
    
end

function CameraHolderMixin:SetDesiredCameraYOffset(yOffset)

    if self.cameraYOffset ~= yOffset then

        if not self:IsAnimated() then
            self:SetDesiredCamera(0.3, { follow = true })
        end

        self:SetCameraYOffset(yOffset)

    end

end  
AddFunctionContract(CameraHolderMixin.SetDesiredCameraYOffset, { Arguments = { "Entity", "number" }, Returns = { } })

function CameraHolderMixin:SetCameraYOffset(yOffset)
    self.cameraYOffset = yOffset
end

function CameraHolderMixin:GetCameraYOffset()
    return self.cameraYOffset
end

/**
 * Set to 0 to get out of third person.
 */
function CameraHolderMixin:SetIsThirdPerson(distance, duration)

    self:SetDesiredCameraDistance(distance, duration, callback)
    
end

local function properAnglesDirection(start, desired)

    if desired.x - start.x > math.pi then
        desired.x = desired.x - 2 * math.pi
    elseif start.x - desired.x > math.pi then
        start.x = start.x - 2 * math.pi
    end

    if desired.y - start.y > math.pi then
        desired.y = desired.y - 2 * math.pi
    elseif start.y - desired.y > math.pi then
        start.y = start.y - 2 * math.pi
    end

    if desired.z - start.z > math.pi then
        desired.z = desired.z - 2 * math.pi
    elseif start.z - desired.z > math.pi then
        start.z = start.z - 2 * math.pi
    end

    return start, desired

end

function CameraHolderMixin:UpdateCamera(timePassed)

    if self:IsAnimated() then

        self.transitionTime = Shared.GetTime() - self.transitionStart
        if self.transitionTime < 0 then
            self.transitionTime = 0
        end

        if self.followingTransition then

            local viewAngles           = self:GetViewAngles()

            self.desiredCameraAngles   = Vector(viewAngles.pitch ,viewAngles.yaw ,viewAngles.roll )
            self.desiredCameraPosition = self:GetOrigin() + self:GetViewOffset()
            self.desiredCameraYOffset  = self.cameraYOffset
            self.desiredCameraDistance = self.cameraDistance

            self.startCameraAngles, self.desiredCameraAngles = properAnglesDirection(self.startCameraAngles, self.desiredCameraAngles)

        elseif self.moveTransition then

            local position, angles, distance, yOffset = self:GetCameraParams()

            if self.animatePosition then
                self:SetOrigin( position - self:GetViewOffset() )
            end

            if self.animateAngles then
                self:SetViewAngles( angles )
            end

            if self.animateDistance then
                self.cameraDistance = distance
            end

            if self.animateYOffset then
                self.cameraYOffset  = yOffset
            end

        end

        if  self.transitionTime > self.transitionDuration then
            self.animatePosition = false
            self.animateAngles   = false
            self.animateDistance = false
            self.animateYOffset  = false
            self.cameraDistance  = self.desiredCameraDistance
            self.cameraYOffset   = self.desiredCameraYOffset

            if self.callback ~= nil then
                self.callback()
                self.callback = nil
            end

        end

    end

    if self.OnUpdateCamera then
        self:OnUpdateCamera(timePassed)
    end
    
end

function CameraHolderMixin:OnProcessMove(input)

    if Client and self.clientResetMouse ~= self.resetMouse then
        self.clientResetMouse = self.resetMouse
        Client.SetYaw(0)
        Client.SetPitch(0)
    end
    
    self:UpdateCamera(input.time)
    
end

function CameraHolderMixin:OnProcessIntermediate(input)
    self:UpdateCamera(input.time)
end

// This is needed, since when we are spectating a player we won't
// get OnProcess... calls
function CameraHolderMixin:OnProcessSpectate(deltaTime)
    self:UpdateCamera(deltaTime)
end

function CameraHolderMixin:SetDesiredCamera(transitionDuration, mode, position, angles, distance, yOffset, callback)

    local viewAngles           = self:GetViewAngles()

    self.startCameraPosition   = self:GetOrigin() + self:GetViewOffset()
    self.startCameraAngles     = Vector(viewAngles.pitch ,viewAngles.yaw ,viewAngles.roll )
    self.startCameraDistance   = self.cameraDistance
    self.startCameraYOffset    = self.cameraYOffset

    self.transitionTime        = 0
    self.transitionDuration    = transitionDuration

    if Server then
        self.transitionStart   = Shared.GetTime() + (1.0 * self:GetPing()) / 1000.0
    elseif Client then
        self.transitionStart   = Shared.GetTime()
    end

    self.followingTransition   = false
    self.moveTransition        = false

    self.callback              = callback

    if position then
        self.animatePosition       = true
        self.desiredCameraPosition = position
    else
        self.animatePosition       = false
        self.desiredCameraPosition = self.startCameraPosition
    end

    if angles then
        self.animateAngles       = true
        self.desiredCameraAngles = Vector(angles.pitch, angles.yaw, angles.roll)
    else
        self.animateAngles       = false
        self.desiredCameraAngles = self.startCameraAngles
    end

    if distance then
        self.animateDistance       = true
        self.desiredCameraDistance = distance
    else
        self.animateDistance       = false
        self.desiredCameraDistance = self.startCameraDistance
    end

    if mode.tweening then
        self.tweeningFunction = mode.tweening
    else
        self.tweeningFunction = kTweeningFunctions.linear
    end

    if mode.follow then

        self.followingTransition   = true
        self.animatePosition       = true
        self.animateAngles         = true
        self.animateDistance       = true
        self.animateYOffset        = true

        self.desiredCameraAngles   = self.startCameraAngles
        self.desiredCameraPosition = self.startCameraPosition
        self.desiredCameraDistance = self.startCameraDistance
        self.desiredCameraYOffset  = self.startCameraYOffset

    elseif mode.move then
        self.moveTransition = true
    end

    self.startCameraAngles, self.desiredCameraAngles = properAnglesDirection(self.startCameraAngles, self.desiredCameraAngles)

end

if Server then

    local function OnCommandThirdperson(client, distance)

        if client ~= nil and Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            
            if player ~= nil and HasMixin(player, "CameraHolder") then
        
                local numericDistance = 3
                if distance ~= nil then
                    numericDistance = tonumber(distance)
                elseif player:GetIsThirdPerson() then
                    numericDistance = 0
                end
                
                player:SetIsThirdPerson(numericDistance)
            
            end
            
        end
        
    end

    Event.Hook("Console_thirdperson", OnCommandThirdperson)
    
end

