// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk_Client.lua
//
// James Gu (twiliteblue), Yuuki (community contribution)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Lerk camera tilt variables
local gEnableTilt = true
Lerk.kCameraRollTilt_YawModifier = 0.4
Lerk.kCameraRollTilt_StrafeModifier = 0.05
Lerk.kCameraRollSpeedModifier = 0.8

local kLerkHealthbarOffset = Vector(0, 0.7, 0)
function Lerk:GetHealthbarOffset()
    return kLerkHealthbarOffset
end

function Lerk:UpdateMisc(input)

    Alien.UpdateMisc(self, input)

    local totalCameraRoll = 0

    if math.abs(self.currentCameraRoll) < 0.0001 then
        self.currentCameraRoll = 0
	end
	
    if math.abs(self.goalCameraRoll) < 0.0001 then
        self.goalCameraRoll = 0
    end

    if self:GetIsOnGround() then
        self.goalCameraRoll = 0
    else
        local strafeDirection = 0

        if input.move.x > 0 then
            strafeDirection = -1
        elseif input.move.x < 0 then
            strafeDirection = 1
        end			

        totalCameraRoll = self.goalCameraRoll + strafeDirection * Lerk.kCameraRollTilt_StrafeModifier
        
    end	
    self.currentCameraRoll = LerpGeneric(self.currentCameraRoll, totalCameraRoll, math.min(1, input.time * Lerk.kCameraRollSpeedModifier))
    
end

function Lerk:GetHeadAttachpointName()
    return "Head_Tongue_02"
end

function Lerk:PlayerCameraCoordsAdjustment(cameraCoords)

    if not Client.GetOptionBoolean("CameraAnimation", false) then 
        return cameraCoords 
    end

    local viewModelTiltAngles = Angles()
    viewModelTiltAngles:BuildFromCoords(cameraCoords)		
    
    local deltaYaw = self.previousYaw - viewModelTiltAngles.yaw
    self.previousYaw = viewModelTiltAngles.yaw

    //transitions from -pi to pi and from pi to -pi		
    if (deltaYaw > math.pi) then
        deltaYaw = deltaYaw - 2*math.pi       		
    elseif (deltaYaw < -math.pi) then
        deltaYaw = deltaYaw + 2*math.pi
    end		

    if self.gliding then
        self.goalCameraRoll = deltaYaw * Lerk.kCameraRollTilt_YawModifier
    else
        self.goalCameraRoll = deltaYaw * Lerk.kCameraRollTilt_YawModifier * 0.5
    end

    if self.currentCameraRoll ~= 0 then
        viewModelTiltAngles.roll = self.currentCameraRoll
    end

    local viewModelTiltCoords = viewModelTiltAngles:GetCoords()
    viewModelTiltCoords.origin = cameraCoords.origin

    return viewModelTiltCoords

end

function OnCommandLerkViewTilt(enableTilt)
    gEnableTilt = enableTilt ~= "false"	
end


local function UpdateFlySound(self)

    if not Shared.GetIsRunningPrediction() and self.flySound and self:GetIsAlive() then

        if self:GetIsOnGround() then
            self.flySound:SetParameter("speed", 0, 10)
        else
            self.flySound:SetParameter("speed", Clamp(self:GetVelocityLength() / self:GetMaxSpeed(), 0, 1), 10)
        end

    end   

end

function Lerk:OnUpdate(deltaTime)
    
    Alien.OnUpdate(self, deltaTime)
    UpdateFlySound(self)

end

function Lerk:OnProcessMove(input)

    Alien.OnProcessMove(self, input)    
    UpdateFlySound(self)

end

Event.Hook("Console_lerk_view_tilt",   OnCommandLerkViewTilt)