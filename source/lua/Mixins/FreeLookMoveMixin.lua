// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FreeLookMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/Mixins/BaseMoveMixin.lua")

FreeLookMoveMixin = CreateMixin(FreeLookMoveMixin)
FreeLookMoveMixin.type = "FreeLookMove"

FreeLookMoveMixin.networkVars =
{
    freeLookMoveEnabled = "private boolean"
}

FreeLookMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

FreeLookMoveMixin.expectedCallbacks =
{
    GetAcceleration = "Should return a number value representing the acceleration.",
    GetMaxSpeed = "Should return a number value representing the maximum speed this Entity can go.",
    ConvertToViewAngles = "Return the current view angles based on the input pitch and yaw passed in.",
    SetViewAngles = "Set the view of the player"
}

FreeLookMoveMixin.defaultConstants =
{
    kFriction = 5
}

function FreeLookMoveMixin:__initmixin()
    self.freeLookMoveEnabled = true
end

function FreeLookMoveMixin:SetFreeLookMoveEnabled(enabled)
    self.freeLookMoveEnabled = enabled
end

local function ClampToMaxSpeed(self, velocity)

    local speed = velocity:GetLength()
    local maxSpeed = self:GetMaxSpeed()
    
    if speed > maxSpeed then
        velocity:Scale(maxSpeed / speed)
    end
    
    return velocity
    
end

function FreeLookMoveMixin:UpdateMove(input)

    if not self.freeLookMoveEnabled then
        return
    end
    
    if bit.band(input.commands, Move.MovementModifier) ~= 0 then
    
        input.move.y = input.move.z
        input.move.z = 0
        
    end
    
    local velocity = self:GetVelocity()
    local angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    local acceleration = angles:GetCoords():TransformVector(input.move) * self:GetAcceleration()
    local friction = velocity * self:GetMixinConstant("kFriction")
    
    velocity = velocity + (acceleration - friction) * input.time
    veloctiy = ClampToMaxSpeed(self, velocity)
    
    local position = self:GetOrigin() + velocity * input.time
    
    self:SetOrigin(position)
    self:SetViewAngles(Angles(input.pitch, input.yaw, 0))
    self:SetVelocity(velocity)
    
end