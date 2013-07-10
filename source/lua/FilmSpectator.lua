// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\FilmSpectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'FilmSpectator' (Player)

// Public
FilmSpectator.kMapName = "filmspectator"

local kDollySpeed = .4 // Amount per key press
local networkVars =
{
    // We want these at full precision for smooth camera motion/
    m_origin = "interpolated compensated vector",
    m_angles = "interpolated compensated angles",
    dollySpeed = "vector",
    dollyMode = "boolean",
    dollyViewAngles = "vector",
    lockOn = "boolean",
    lockOnTarget = "vector",
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)

function FilmSpectator:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, CameraHolderMixin, { kFov = 90 })
    InitMixin(self, BaseMoveMixin, { kGravity = 0})
    self.dollyViewAngles = Vector(0, 0, 0)
    
end

function FilmSpectator:OnInitialized()

    Player.OnInitialized(self)
    
    self.lastTargetId = Entity.invalidId
    self.specTargetId = Entity.invalidId
    self.timeFromLastAction = 0
    self.movementModifierState = false
    
    self:SetIsVisible(false)       
    if Server then        
        self:SetIsAlive(false)
    end
    
    self:DestroyController() // Remove physics
    self:SetPropagate(Entity.Propagate_Never) // A spectator is not sync with other player

    self.dollyMode = false

end

function FilmSpectator:OnGetIsVisible(visibleTable)
    visibleTable.Visible = false
end

local function ClampToMaxSpeed(self, velocity)

    local speed = velocity:GetLength()
    local maxSpeed = self:GetMaxSpeed()

    if speed > maxSpeed then
        velocity:Scale(maxSpeed / speed)
    end

    return velocity
    
end

function FilmSpectator:GetMaxSpeed(possible)
    return ConditionalValue(self.movementModifierState, 10000, 100)
end

function FilmSpectator:GetAcceleration()
    return ConditionalValue(self.movementModifierState, 1000, 50)
end

function FilmSpectator:GetFriction()
    return 2
end

// Move us in our dolly direction, relative to our view (ignore friction)
function FilmSpectator:UpdateDollyMove(input)

    // When locked on, we are looking at target already. Move dolly relative to our target view so we're rotating around it.
    local pitch = input.pitch
    local yaw = input.yaw
    
    if self.lockOn then    
    
        local normToTarget = GetNormalizedVector(self.lockOnTarget - self:GetOrigin())        
        
        // Set angles to lock on to target
        pitch = GetPitchFromVector(normToTarget)
        yaw = GetYawFromVector(normToTarget)
        
    end
    
    local angles       = self:ConvertToViewAngles(pitch, yaw, 0)
    local velocity     = angles:GetCoords():TransformVector(self.dollySpeed)
      
    local position = self:GetOrigin() + velocity * input.time

    self:SetOrigin(position)
    
    // Set velocity so it's preserved when we leave dolly mode
    self:SetVelocity(velocity)
    
end

function FilmSpectator:UpdateFreeMove(input)

    local velocity     = self:GetVelocity()
    local angles       = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    local coords       = angles:GetCoords()
    
    // Hack in moving up and down with use and taunt
    local adjustedMove = Vector(input.move)
    if bit.band(input.commands, Move.Use) ~= 0 then
        adjustedMove.y = -1
    end
    if bit.band(input.commands, Move.Taunt) ~= 0 then
        adjustedMove.y = 1
    end
        
    local acceleration = coords:TransformVector(GetNormalizedVector(adjustedMove)) * self:GetAcceleration()
    local friction     = velocity * self:GetFriction()
    local position    
      
    velocity = velocity + (acceleration - friction) * input.time 
    velocity = ClampToMaxSpeed(self, velocity)

    position = self:GetOrigin() + velocity * input.time

    self:SetOrigin(position)
    self:SetVelocity(velocity)
    
end

function FilmSpectator:UpdateMove(input)

    // If we're in dolly mode, move us that way
    if self.dollyMode or self.lockOn then
        self:UpdateDollyMove(input)
    else
        // Otherwise update in free-cam mode
        self:UpdateFreeMove(input)
    end    
    
end

function FilmSpectator:OnProcessMove(input)

    self:UpdateSpectatorMode(input)
    
    self:UpdateViewAngles(input)
    
    self:UpdateMove(input)
    
    self:OnUpdatePlayer(input.time)
    
    Player.UpdateMisc(self,input)
    
end

function FilmSpectator:UpdateViewAngles(input)

    // When locked on, always view target
    if self.lockOn == true then
    
        local dir = GetNormalizedVector(self.lockOnTarget - self:GetOrigin())
        local angles = Angles(GetPitchFromVector(dir), GetYawFromVector(dir), 0)
        self:SetViewAngles(angles)
        
        // Keep view angles in synch so we don't pop after leaving lock on mode
        //input.pitch = angles.pitch
        //input.yaw = angles.yaw
        
    else
    
        local newAngles = Angles(input.pitch, input.yaw, 0)
        self:SetViewAngles(newAngles)
        
    end
    
end

function FilmSpectator:GetAnimateDeathCamera()
    return false
end

function FilmSpectator:UpdateSpectatorMode(input)

    local newDollyMode = (bit.band(input.commands, Move.Crouch) ~= 0)
    if newDollyMode ~= self.dollyMode then
    
        self.dollyMode = newDollyMode
        self.dollySpeed.x = 0
        self.dollySpeed.y = 0
        self.dollySpeed.z = 0
        
        // Save view angles so we can override them when in dolly mode
        if self.dollyMode then
            self.dollyViewAngles = self:GetViewAngles()
        end
        
    end
    
    // Add new fixed speed to our dolly rate as we press buttons
    if self.dollyMode then
    
        // Hack in moving up and down with use and taunt
        local adjustedMove = Vector(input.move)
        if bit.band(input.commands, Move.Use) ~= 0 then
            adjustedMove.y = -1
        end
        if bit.band(input.commands, Move.Taunt) ~= 0 then
            adjustedMove.y = 1
        end
        
        if adjustedMove:GetLength() > .0001 then

            local move = GetNormalizedVector(adjustedMove) * kDollySpeed
            self.dollySpeed = self.dollySpeed + move * input.time * 30
            
        end
        
    end

    self.movementModifierState = bit.band(input.commands, Move.MovementModifier) ~= 0 --movement modifier for fast freelook cam
    
    self:UpdateLockOn(input)
    
end

function FilmSpectator:UpdateLockOn(input)

    // If we now attack, find new target to lock on
    local oldLockOn = self.lockOn
    if bit.band(input.commands, Move.PrimaryAttack) ~= 0 then
    
        // Optimization
        if not self.lockOn then
        
            // Do traceline to target
            local viewCoords = self:GetViewAngles():GetCoords()

            local trace = Shared.TraceRay(self:GetOrigin(), self:GetOrigin() + viewCoords.zAxis * 1000, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self))
            if trace.fraction < 1 then
            
                self.lockOn = true
                self.lockOnTarget = trace.endPoint
                if trace.entity and trace.entity.GetModelOrigin then
                    Print("Locking on to %s model origin", SafeClassName(trace.entity))
                    self.lockOnTarget = trace.entity:GetModelOrigin()
                end
                
            else
                self.lockOn = false
            end
            
        end
        
    else
        self.lockOn = false
    end
    
end

function FilmSpectator:GetMovePhysicsMask()
    return PhysicsMask.All
end

function FilmSpectator:GetCanTakeDamageOverride()
    return false
end

function FilmSpectator:GetTraceCapsule()
    return 0, 0
end

if Client then

    function FilmSpectator:GetDisplayUnitStates()
        return false
    end

    // Don't change visibility on client
    function FilmSpectator:UpdateClientEffects(deltaTime, isLocal)
        
        Player.UpdateClientEffects(self, deltaTime, isLocal)
        
        self:SetIsVisible(false)

    end

    function FilmSpectator:GetCrossHairText()
        return nil
    end
    
end

Shared.LinkClassToMap("FilmSpectator", FilmSpectator.kMapName, networkVars)