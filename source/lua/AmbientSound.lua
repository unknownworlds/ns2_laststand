// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AmbientSound.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

Script.Load("lua/Effect.lua")

class 'AmbientSound' (Effect)

// Read trigger radius and FMOD event name.
function AmbientSound:OnLoad()

    Effect.OnLoad(self)
    
    // Precache sound name and lookup index for it.
    self.minFalloff = GetAndCheckValue(self.minFalloff, 0, 1000, "minFalloff", 0)
    self.maxFalloff = GetAndCheckValue(self.maxFalloff, 0, 1000, "maxFalloff", 0)
    self.falloffType = GetAndCheckValue(self.falloffType, 1, 2, "falloffType", 1)
    self.positioning = GetAndCheckValue(self.positioning, 1, 2, "positioning", 1)
    self.volume = GetAndCheckValue(self.volume, 0, 1, "volume", 1)
    self.pitch = GetAndCheckValue(self.pitch, -4, 4, "pitch", 0)
    
end

function AmbientSound:OnDestroy()

    if self.soundEffectInstance then
        Client.DestroySoundEffect(self.soundEffectInstance)
    end
    self.soundEffectInstance = nil
    
end

function AmbientSound:StartPlaying()

    if not self.playing then
    
        if not self.soundEffectInstance then
            self.soundEffectInstance = Client.CreateSoundEffect(Shared.GetSoundIndex(self.eventName))
        end
        
        self.soundEffectInstance:Start()
        
        local listenerOrigin = self:GetOrigin()
        if self.positioning == 2 then
            listenerOrigin = Vector(0, 0, 0)
        end
        
        self.soundEffectInstance:SetCoords(Coords.GetTranslation(listenerOrigin))
        self.soundEffectInstance:SetPositional(self.positioning == 1)
        
        local rolloffType = SoundSystem.Rolloff_Logarithmic
        if self.falloffType == 2 then
            rolloffType = SoundSystem.Rolloff_Linear
        elseif self.falloffType == 3 then
            rolloffType = SoundSystem.Rolloff_Custom
        end
        self.soundEffectInstance:SetRolloff(rolloffType)
        
        if self.minFalloff >= self.maxFalloff then
            Shared.Message("Warning: Min Falloff (" .. self.minFalloff .. ") is greater than Max Falloff (" .. self.maxFalloff .. ") for ambient sound event named: " .. self.eventName)
        end
        
        self.soundEffectInstance:SetMaxDistance(self.maxFalloff)
        self.soundEffectInstance:SetMinDistance(self.minFalloff)
        
        self.soundEffectInstance:SetVolume(self.volume)
        self.soundEffectInstance:SetPitch(self.pitch)
        
        self.playing = true
        
    end
    
end

function AmbientSound:StopPlaying()

    if self.playing then
    
        self.soundEffectInstance:Stop()
        self.playing = false
        
    end
    
end

function AmbientSound:StartPlayingAgain()

    if self.playing then
    
        self.soundEffectInstance:Start()
        self.triggered = true
        
    else
    
        self:StartPlaying()
        self.triggered = true
        
    end
    
end