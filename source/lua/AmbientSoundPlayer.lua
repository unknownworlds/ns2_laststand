// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/AmbientSoundPlayer.lua
//
// A signal listener that will play nearby ambient sounds when messaged.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'AmbientSoundPlayer' (Entity)

AmbientSoundPlayer.kMapName = "ambient_sound_player"

local networkVars = { }

local function PlayNearbyAmbientSounds(origin, distance)
    Server.SendNetworkMessage("StartNearbyAmbientSounds", { origin = origin, distance = distance }, true)
end

function AmbientSoundPlayer:OnCreate()

    Entity.OnCreate(self)
    
    self:SetUpdates(false)
    
    InitMixin(self, SignalListenerMixin)
    
    if Server then
        self:RegisterSignalListener(function() PlayNearbyAmbientSounds(self:GetOrigin(), self.nearbyDistance) end, self.startsOnMessage)
    end
    
end

local kStartNearbyAmbientSounds =
{
    origin = "vector",
    distance = "float"
}
Shared.RegisterNetworkMessage("StartNearbyAmbientSounds", kStartNearbyAmbientSounds)

if Client then

    local function OnStartNearbyAmbientSounds(message)
    
        local distSq = message.distance * message.distance
        for a = 1, #Client.ambientSoundList do
        
            local ambientSound = Client.ambientSoundList[a]
            if ambientSound:GetOrigin():GetDistanceSquared(message.origin) < distSq then
                ambientSound:StartPlayingAgain()
            end
            
        end
        
    end
    Client.HookNetworkMessage("StartNearbyAmbientSounds", OnStartNearbyAmbientSounds)
    
end

Shared.LinkClassToMap("AmbientSoundPlayer", AmbientSoundPlayer.kMapName, networkVars)