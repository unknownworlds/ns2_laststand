// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\SoundEffect.lua
//
//    Created by:   Brain Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalListenerMixin.lua")

// Utility functions below.
if Server then

    function StartSoundEffectAtOrigin(soundEffectName, atOrigin, volume, predictor)
    
        local soundEffectEntity = Server.CreateEntity(SoundEffect.kMapName)
        soundEffectEntity:SetOrigin(atOrigin)
        soundEffectEntity:SetAsset(soundEffectName)
        soundEffectEntity:SetVolume(volume)
        soundEffectEntity:SetPredictor(predictor)
        soundEffectEntity:Start()
        
        return soundEffectEntity
        
    end
    
    function StartSoundEffectOnEntity(soundEffectName, onEntity, volume, predictor)
    
        local soundEffectEntity = Server.CreateEntity(SoundEffect.kMapName)
        soundEffectEntity:SetParent(onEntity)
        soundEffectEntity:SetAsset(soundEffectName)
        soundEffectEntity:SetVolume(volume)
        soundEffectEntity:SetPredictor(predictor)
        soundEffectEntity:Start()
        
        return soundEffectEntity
        
    end
    
    /**
     * Starts a sound effect which only 1 player will hear.
     */
    function StartSoundEffectForPlayer(soundEffectName, forPlayer, volume)
    
        local soundEffectEntity = Server.CreateEntity(SoundEffect.kMapName)
        soundEffectEntity:SetParent(forPlayer)
        soundEffectEntity:SetAsset(soundEffectName)
        soundEffectEntity:SetPropagate(Entity.Propagate_Callback)
        soundEffectEntity:SetVolume(volume)
        function soundEffectEntity:OnGetIsRelevant(player)
            return player == forPlayer
        end
        soundEffectEntity:Start()
        
        return soundEffectEntity
        
    end
    
end

if Client then

    function StartSoundEffectAtOrigin(soundEffectName, atOrigin, volume, predictor)
        Shared.PlayWorldSound(nil, soundEffectName, nil, atOrigin, volume or 1)
    end
    
    function StartSoundEffectOnEntity(soundEffectName, onEntity, volume, predictor)
        Shared.PlaySound(onEntity, soundEffectName, volume or 1)
    end
    
    function StartSoundEffect(soundEffectName, volume)
        Shared.PlaySound(nil, soundEffectName, volume or 1)
    end

    function StartSoundEffectForPlayer(soundEffectName, forPlayer, volume)
        Shared.PlayPrivateSound(forPlayer, soundEffectName, forPlayer, volume or 1, forPlayer:GetOrigin())
    end
    
end


if Predict then

    function StartSoundEffectAtOrigin(soundEffectName, atOrigin)
    end
    
    function StartSoundEffectOnEntity(soundEffectName, onEntity)
    end

    function StartSoundEffectForPlayer(soundEffectName, forPlayer)
    end
    
end

local kDefaultMaxAudibleDistance = 50
local kSoundEndBufferTime = 0.5

class 'SoundEffect' (Entity)

SoundEffect.kMapName = "sound_effect"

local networkVars =
{
    playing = "boolean",
    assetIndex = "resource",
    startTime = "time",
    predictorId  = "entityid",
    volume = "float (0 to 1 by 0.01)"
}

function SoundEffect:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, SignalListenerMixin)
    
    self.playing = false
    self.assetIndex = 0
    self.volume = 1
    
    self:SetUpdates(true)
    self.predictorId = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kDefaultMaxAudibleDistance)
    
    if Server then
    
        self.assetLength = 0
        self.startTime = 0
        
    end
    
    if Client then
    
        self.clientPlaying = false
        self.clientAssetIndex = 0
        self.soundEffectInstance = nil
        
    end
    
    self:SetUpdates(true)
    
end

function SoundEffect:GetIsPlaying()
    return self.playing
end

function GetSoundEffectLength(soundName)

    local fevStart, fevEnd = string.find(soundName, ".fev")
    local fixedAssetPath = string.sub(soundName, fevEnd + 1)
    return Server.GetSoundLength(fixedAssetPath)

end

if Server then

    function SoundEffect:SetVolume(volume)
        self.volume = volume or 1
    end
    
    function SoundEffect:SetPredictor(predictor)
        self.predictorId = predictor and predictor:GetId() or Entity.invalidId
    end

    function SoundEffect:SetAsset(assetPath)
    
        if string.len(assetPath) == 0 then
            return
        end
        
        local assetIndex = Shared.GetSoundIndex(assetPath)
        if assetIndex == 0 then
        
            Shared.Message("Effect " .. assetPath .. " wasn't precached")
            return
            
        end
        
        self.assetIndex = assetIndex
        self.assetLength = GetSoundEffectLength(assetPath)
        /*
        if not self:GetParent() and self:GetOrigin() == Vector(0,0,0) then
            Print("Warning: %s is being player at (0,0,0)", assetPath)
        end
        */
        
    end
    
    function SoundEffect:Start()
    
        // Asset must be assigned before playing.
        assert(self.assetIndex ~= 0)
        
        self.playing = true
        self.startTime = Shared.GetTime()
        
    end
    
    function SoundEffect:Stop()
    
        self.playing = false
        self.startTime = 0
        
    end
    
    function SoundEffect:GetIsPlaying()
        return self.playing
    end
    
    local function SharedUpdate(self)
    
        PROFILE("SoundEffect:SharedUpdate")
        
        // If the assetLength is < 0, it is a looping sound and needs to be manually destroyed.
        if not self:GetIsMapEntity() and self.playing and self.assetLength >= 0 then
        
            // Add in a bit of time to make sure the Client has had enough time to fully play.
            local endTime = self.startTime + self.assetLength + kSoundEndBufferTime
            if Shared.GetTime() > endTime then
                DestroyEntity(self)
            end
            
        end
        
    end
    
    function SoundEffect:OnProcessMove()
        SharedUpdate(self)
    end
    
    function SoundEffect:OnUpdate(deltaTime)
        SharedUpdate(self)
    end
    
end

if Client then

    local function DestroySoundEffect(self)
    
        if self.soundEffectInstance then
        
            Client.DestroySoundEffect(self.soundEffectInstance)
            self.soundEffectInstance = nil
            
        end
        
    end
    
    function SoundEffect:OnDestroy()
        DestroySoundEffect(self)
    end
    
    local function SharedUpdate(self)
    
        PROFILE("SoundEffect:SharedUpdate")
        
        if self.predictorId ~= Entity.invalidId then
        
            local predictor = Shared.GetEntity(self.predictorId)
            if Client.GetLocalPlayer() == predictor then
                return
            end
            
        end
       
        if self.clientAssetIndex ~= self.assetIndex then
        
            DestroySoundEffect(self)
            
            self.clientAssetIndex = self.assetIndex
            
            if self.assetIndex ~= 0 then
            
                self.soundEffectInstance = Client.CreateSoundEffect(self.assetIndex)
                self.soundEffectInstance:SetParent(self:GetId())
                
            end
        
        end
        
        // Only attempt to play if the index seems valid.
        if self.assetIndex ~= 0 then
        
            if self.clientPlaying ~= self.playing or self.clientStartTime ~= self.startTime then
            
                self.clientPlaying = self.playing
                self.clientStartTime = self.startTime
                
                if self.playing then
                
                    self.soundEffectInstance:Start()
                    self.soundEffectInstance:SetVolume(self.volume)
                    if self.clientSetParameters then
                    
                        for c = 1, #self.clientSetParameters do
                        
                            local param = self.clientSetParameters[c]
                            self.soundEffectInstance:SetParameter(param.name, param.value, param.speed)
                            
                        end
                        self.clientSetParameters = nil
                        
                    end
                    
                else
                    self.soundEffectInstance:Stop()
                end
                
            end
            
        end    
    end
    
    function SoundEffect:OnUpdate(deltaTime)
        SharedUpdate(self)
    end
    
    function SoundEffect:OnProcessMove()
        SharedUpdate(self)
    end
    
    function SoundEffect:OnProcessSpectate()
        SharedUpdate(self)
    end
    
    function SoundEffect:SetParameter(paramName, paramValue, paramSpeed)
    
        ASSERT(type(paramName) == "string")
        ASSERT(type(paramValue) == "number")
        ASSERT(type(paramSpeed) == "number")
        
        local success = false
        
        if self.soundEffectInstance and self.playing then
        
            if self.clientPlaying then
                success = self.soundEffectInstance:SetParameter(paramName, paramValue, paramSpeed)
            else
            
                // SharedUpdate() has not been called yet, save the parameters until it has.
                self.clientSetParameters = self.clientSetParameters or { }
                table.insert(self.clientSetParameters, { name = paramName, value = paramValue, speed = paramSpeed })
                success = true
                
            end
            
        end
        
        return success
        
    end
    
    // will create a sound effect instance
    function CreateLoopingSoundForEntity(entity, localSoundName, worldSoundName)
    
        local soundEffectInstance = nil
    
        if entity then
        
            if entity == Client.GetLocalPlayer() and localSoundName then
                soundName = localSoundName
            else
                soundName = worldSoundName
            end
            
            if soundName then
            
                soundEffectInstance = Client.CreateSoundEffect(Shared.GetSoundIndex(soundName))
                soundEffectInstance:SetParent(entity:GetId())
        
            end
        
        end
        
        return soundEffectInstance
    
    end

end

Shared.LinkClassToMap("SoundEffect", SoundEffect.kMapName, networkVars)