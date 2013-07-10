// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\BaseMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

BaseMoveMixin = { }
BaseMoveMixin.type = "BaseMove"

BaseMoveMixin.optionalCallbacks =
{
    AdjustGravityForce = "Should return the current gravity force for the entity using this Mixin.",
    OnSetVelocityOverride = "Can be provided to modify the passed in velocity"
}

BaseMoveMixin.expectedConstants =
{
    kGravity = "The force on the y axis that gravity will apply."
}

BaseMoveMixin.kMinimumVelocity = 0.01
BaseMoveMixin.kMaximumVelocity = 45 // 50 is the hardlimit
local kNetMaxV = BaseMoveMixin.kMaximumVelocity + 5 // network hard limit
// network step, must be < max length of a Vector(kMinimumVelcity x3) so that the length
// of a min-size vector is << minimum velocity.
local kNetMinV =  BaseMoveMixin.kMinimumVelocity / 4
local kNetRangeStep = "-" .. kNetMaxV .. " to " .. kNetMaxV .. " by " .. kNetMinV
BaseMoveMixin.networkVars =
{
    // different xz compression and y compression
    velocity = "private compensated interpolated vector(" .. kNetRangeStep .. " [ 8 10 13 ], " .. kNetRangeStep .. " [ 1 1 13 ] )",
    
    // the velocity is expensive to propagate, but others need to know how fast we are moving, so we expose that with less resolution
    velocityLength = "compensated interpolated float (0 to " .. kNetMaxV .. " by 0.4 [ 2 ])", // 125 steps, -> 7 bits
    // velocity yaw
    velocityYaw = "compensated interpolated angle ( 7 bits )", 
    // velocity pitch 
    velocityPitch = "compensated interpolated angle ( 7 bits)",

    gravityEnabled = "compensated boolean",
}

function BaseMoveMixin:__initmixin()

    self.velocity = Vector(0, 0, 0)
    self.smoothedVelocity = Vector(0, 0, 0)
    self.velocityLength = 0
    self.velocityYaw = 0
    self.velocityPitch = 0
    
    self.gravityEnabled = true
    
end

function BaseMoveMixin:SetVelocity(velocity)

    // Notify any other mixin that cares. They may want to modify the velocity.
    if self.OnSetVelocityOverride then
        velocity = self:OnSetVelocityOverride(velocity)
    end

    self.velocity = velocity
    
    local len = self.velocity:GetLength()

    // Snap to 0 when close to zero for network performance and our own sanity.
    if len < BaseMoveMixin.kMinimumVelocity then
        self.velocity:Scale(0)
    end
    
    if len > BaseMoveMixin.kMaximumVelocity then
        local frac = BaseMoveMixin.kMaximumVelocity / len
        self.velocity:Scale(frac)
    end
    
end
AddFunctionContract(BaseMoveMixin.SetVelocity, { Arguments = { "Entity", "Vector" }, Returns = { } })

function BaseMoveMixin:GetVelocity()

    // only allowed to ask for velocity if we are on the server or if we are the local player on the client
    if Client and self:isa("Player") and self ~= Client.GetLocalPlayer() then
        // return the reconstructed velocity
        return self:GetVelocityFromPolar()
    end
    return self.velocity
    
end
AddFunctionContract(BaseMoveMixin.GetVelocity, { Arguments = { "Entity" }, Returns = { "Vector" } })

// length of velocity vector
function BaseMoveMixin:GetVelocityLength()
    return self.velocityLength
end
AddFunctionContract(BaseMoveMixin.GetVelocityLength, { Arguments = { "Entity" }, Returns = { "float" } })

// yaw angle for velocity
function BaseMoveMixin:GetVelocityYaw()
    return self.velocityYaw
end
AddFunctionContract(BaseMoveMixin.GetVelocityYaw, { Arguments = { "Entity" }, Returns = { "float" } })

// pitch angle for velocity
function BaseMoveMixin:GetVelocityPitch()
    return self.velocityPitch
end
AddFunctionContract(BaseMoveMixin.GetVelocityPitch, { Arguments = { "Entity" }, Returns = { "bool" } })

// Get a velocity vector from the polar coordinates. 
// This function is always available, while GetVelocity() is only available on 
// the server or the owning client.
function BaseMoveMixin:GetVelocityFromPolar()

    local y = math.sin(self.velocityPitch) * self.velocityLength;
    local xzLength = math.cos(self.velocityPitch) * self.velocityLength;
    local z = math.sin(self.velocityYaw) * xzLength;
    local x = math.cos(self.velocityYaw) * xzLength;
    
    return Vector(x,y,z)
    
end
AddFunctionContract(BaseMoveMixin.GetVelocityFromPolar, { Arguments = { "Entity" }, Returns = { "Vector" } })

function BaseMoveMixin:SetGravityEnabled(state)
    self.gravityEnabled = state
end
AddFunctionContract(BaseMoveMixin.SetGravityEnabled, { Arguments = { "Entity", "boolean" }, Returns = { } })

function BaseMoveMixin:GetGravityEnabled()
    return self.gravityEnabled
end
AddFunctionContract(BaseMoveMixin.GetGravityEnabled, { Arguments = { "Entity" }, Returns = { "boolean" } })

function BaseMoveMixin:GetGravityForce(input)

    local gravity = self:GetMixinConstants().kGravity
    
    if self.AdjustGravityForce then
        gravity = self:AdjustGravityForce(input, gravity)
    end
    
    return gravity
    
end
AddFunctionContract(BaseMoveMixin.GetGravityForce, { Arguments = { "Entity", "Move" }, Returns = { "number" } })

local kSmoothRate = 28
function BaseMoveMixin:OnProcessMove(input)

    self.smoothedVelocity.x = Slerp(self.smoothedVelocity.x, self.velocity.x, input.time * kSmoothRate)
    self.smoothedVelocity.y = Slerp(self.smoothedVelocity.y, self.velocity.y, input.time * kSmoothRate)
    self.smoothedVelocity.z = Slerp(self.smoothedVelocity.z, self.velocity.z, input.time * kSmoothRate)
    
    // update the low-resolution polar coordinates
    local v = self.smoothedVelocity
    self.velocityLength = v:GetLength()
    self.velocityYaw  = math.atan2(v.z, v.x)
    self.velocityPitch = self.velocityLength > 0 and math.asin(v.y / self.velocityLength) or 0

end
