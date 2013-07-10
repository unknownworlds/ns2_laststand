// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Rumble.lua
//
// Rumbling effects due to nearby Onos.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kRumbleSoundRadius = 25
local kDirtEffectChance = .9
local kDirtEffectInterval = .1
local kDirtEffectRadius = 12 // lights in this radius are chosen

function Player:UpdateShakingLights(deltaTime)

    // This is disabled because it creates a lot of garbage vectors, and shaking all of 
    // the lights forces a lot of shadow maps to be recomputed. Instead we should probably
    // just have a few key lights that are setup to shake.
    /*
    if self.shakingLightList then
    
        local time = Shared.GetTime()
        
        for lightIndex, renderLight in ipairs(self.shakingLightList) do
        
            if self.lightShakeAmount == 0 then
                renderLight.lightShakeTime = 0
            else
        
                local coords = renderLight:GetCoords()
            
                // Update light vibration amount along sin curve
                renderLight.lightShakeTime = renderLight.lightShakeTime + deltaTime
                
                // Have speed change randomly for each light, so they don't all shake in unison
                local speed = kLightShakeBaseSpeed + (lightIndex /table.count(self.shakingLightList) ) * kLightShakeVariableSpeed
                
                // Allow scalar to affect amount of shake
                local yOffset = math.sin(renderLight.lightShakeTime * speed) * kLightShakeMaxYDiff * self.lightShakeAmount * self.lightShakeScalar                
                
                coords.origin.y = renderLight.originalCoords.origin.y + yOffset
                
                renderLight:SetCoords(coords)
                
                //DebugLine(self:GetOrigin(), renderLight.originalCoords.origin, .1, 0, 1, 0, 1)
                
            end
            
            if time > self.lightShakeEndTime then
            
                // Have light shake amount fall off expontially over short interval
                local kFalloffTime = .1
                
                if time < (self.lightShakeEndTime + kFalloffTime) then
                
                    local falloffScalar = Clamp((time - self.lightShakeEndTime) / kFalloffTime, 0, 1)
                    local sin = math.sin( falloffScalar * math.pi / 2 )                    
                    self.lightShakeAmount = self.savedLightShakeAmount - sin * self.savedLightShakeAmount
                    
                else
                
                    self.lightShakeAmount = 0
                
                end
                
            end
            
        end
        
    end
    */    
    
end

// Pick random light within range
function Player:GetRandomNearbyLight(range)

    local light = nil
    
    if self.shakingLightList then
    
        for i = 0, 10 do
        
            local currentLight = table.random(self.shakingLightList)
            if currentLight then
            
                if (currentLight and (currentLight.originalCoords.origin - self:GetOrigin()):GetLength() < range) then
                
                    // Check to make sure light is attached to the world, not just floating in the air
                    local lightOrigin = currentLight.originalCoords.origin
                    local trace = Shared.TraceBox(Vector(.2, .2, .2), lightOrigin, lightOrigin + Vector(0, .1, 0), CollisionRep.Default, PhysicsMask.Movement, nil)
                    if trace.fraction ~= 1 and trace.entity == nil then
                
                        light = currentLight
                        break

                    end
                    
                end
                
            end
            
        end    
        
    end
    
    return light

end

function Player:CreateDirtEffect()

    local light = self:GetRandomNearbyLight(kDirtEffectRadius)
    
    if light then

        local coords = Coords.GetLookIn( light.originalCoords.origin, Vector.zAxis )
        Shared.CreateEffect(self, Player.kFallingDirtEffect, nil, coords)
        
    end
    
    return (light ~= nil)

end

function Player:UpdateDirtFalling(deltaTime)

    // Every so often, create dirt falling from random light nearby
    if self.shakingLightList and (self:GetSpeedScalar() > .5) then
    
        if (self.lastDirtTime == nil or Shared.GetTime() > self.lastDirtTime + kDirtEffectInterval) then
        
            if (math.random() < kDirtEffectChance) and self:CreateDirtEffect() then
            
                self.lastDirtTime = Shared.GetTime()            
                
            end
                
        end
        
    end
    
end

// Look for nearby Oni and determine how much rumbling of the sound effect we should play
// Returns 0-1/0-1 for amount and speed
function CalculateRumble(listenerOrigin)

    local rumbleAmount = 0
    local rumbleSpeed = 0
    
    local oni = GetEntitiesWithinRange("Onos", listenerOrigin, kRumbleSoundRadius)
    for index, onos in ipairs(oni) do
    
        // Rumble is cumulative, adding from each onos
        local dist = (onos:GetOrigin() - listenerOrigin):GetLength()
        local currentRumbleAmount = (1 - (dist / kRumbleSoundRadius))
        rumbleAmount = Clamp(rumbleAmount + currentRumbleAmount, 0, 1)
        
        // Speed = the max speed of any onos
        local currentRumbleSpeed = Clamp(onos:GetSpeedScalard(), 0, 1)
        rumbleSpeed = math.max(rumbleSpeed, currentRumbleSpeed)
        
    end

    return rumbleAmount, rumbleSpeed
    
end

function Player:UpdateOnosRumble(deltaTime)

    if self.lastRumbleUpdate == nil or (Shared.GetTime() > (self.lastRumbleUpdate + 1)) then
    
        // Look for nearby Oni and play rumbling sound effect (includes self if an Onos)
        local rumbleAmount, rumbleSpeed = CalculateRumble(self:GetOrigin())
        
        if rumbleAmount == 0 and rumbleSpeed == 0 then
        
            // Delete sound if we have one
            if self.rumbleSoundInstance then
            
                self.rumbleSoundInstance:Stop()
                Client.DestroySoundEffect(self.rumbleSoundInstance)
                self.rumbleSoundInstance = nil
                
            end
            
        else
        
            // Create sound if we don't have one
            if self.rumbleSoundInstance == nil then
            
                local rumbleSoundIndex = Shared.GetSoundIndex(Player.kRumbleSoundEffect)
                
                if rumbleSoundIndex > 0 then
                
                    self.rumbleSoundInstance = Client.CreateSoundEffect(rumbleSoundIndex)
                    self.rumbleSoundInstance:Start()
                
                end
                
            end
            
            if self.rumbleSoundInstance ~= nil then
            
                // Update parameters
                self.rumbleSoundInstance:SetParameter("amount", rumbleAmount, 10)
                self.rumbleSoundInstance:SetParameter("speed", rumbleSpeed, 10)
                self.rumbleSoundInstance:SetParameter("volume", rumbleAmount * rumbleAmount, 10)
                
            end
            
        end
        
        self.lastRumbleUpdate = Shared.GetTime()
        
    end
    
end

function Player:ResetShakingLights()

    if self.shakingLightList then
    
        for lightIndex, renderLight in ipairs(self.shakingLightList) do
            renderLight.lightShakeTime = 0
        end
        
    end
    
end