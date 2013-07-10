// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Onos.kYStoopCameraOffset = 0.3

// Play footstep effects when moving
function Onos:UpdateClientEffects(deltaTime, isLocal)

    Alien.UpdateClientEffects(self, deltaTime, isLocal)

    if self:GetPlayFootsteps() then
        
        local velocityLength = self:GetVelocityLength()
        local footstepInterval = .8 - (velocityLength / self:GetMaxSpeed(true)) * .15
        
        if self.timeOfLastFootstep == nil or (Shared.GetTime() > (self.timeOfLastFootstep + footstepInterval)) then
        
            self:PlayFootstepEffects(velocityLength / 5)
            
            self.timeOfLastFootstep = Shared.GetTime()
            
        end
        
    end 
    
end

function Onos:GetIdleSoundName()
    return Onos.kLocalIdleSound
end

function Onos:PlayFootstepEffects(scalar)

    if not Shared.GetIsRunningPrediction() then

        scalar = ConditionalValue(scalar == nil, 1, scalar)
        
        // Get all nearby players and shake their screen (including our own)
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        
            if player:GetIsAlive() and not player:isa("Commander") then
            
                self:_PlayFootstepShake(player, scalar)
                
                local distToOnos = (player:GetOrigin() - self:GetOrigin()):GetLength()
                local lightShakeAmount = 1 - Clamp((distToOnos / kOnosLightDistance), 0, 1)
                player:SetLightShakeAmount(lightShakeAmount, kOnosLightShakeDuration, scalar)
                
            end
            
        end
        
        self:TriggerFootstep()
        
    end
    
end

function Onos:OnJumpLandNonLocalClient()

    self:PlayFootstepEffects(3)
    
    self:CreateDirtEffect(self:GetOrigin())
    
end

// Shake camera for nearby players
function Onos:_PlayFootstepShake(player, scalar)

    if player ~= nil and player:GetIsAlive() and player ~= self then
        
        local kMaxDist = 25
        
        local dist = (player:GetOrigin() - self:GetOrigin()):GetLength()
        
        if dist < kMaxDist then
        
            local amount = (kMaxDist - dist)/kMaxDist
            
            local shakeAmount = .002 + amount * amount * .002
            local shakeSpeed = 5 + amount * amount * 9
            local shakeTime = .4 - (amount * amount * .2)
            
            player:SetCameraShake(shakeAmount * scalar, shakeSpeed, shakeTime)
            
        end
        
    end
        
end

function Onos:OnLocationChange(locationName)

    self:ResetShakingLights()
    
    // Get new lights
    self.shakingLightList = GetLightsForLocation(locationName)
    
    for lightIndex, renderLight in ipairs(self.shakingLightList) do
        
        // Add field if needed
        renderLight.lightShakeTime = 0
        
    end
    
end

function Onos:GetHeadAttachpointName()
    return "Onos_Head"
end
