// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DigestMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Allow digestion of structures. Use server side only.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

DigestMixin = CreateMixin( DigestMixin )
DigestMixin.type = "Digest"

local kDefaultDigestDuration = 0.5
local kAllowedReleaseTimeBeforeReset = 0.3 // Steve: I got this number from ConstructMixin...

DigestMixin.optionalCallbacks =
{
    GetCanDigest = "player passed as param."
}

DigestMixin.networkVars =
{
    digestDoneTime = "time",
    lastDigestUseTime = "time"
}

function DigestMixin:__initmixin()

    self.digestDoneTime = 0
    self.lastDigestUseTime = 0
    
end

local function GetEffectiveDigestDuration(self)

    if self.GetDigestDuration then
        return self:GetDigestDuration()
    else
        return kDefaultDigestDuration
    end
 
end

local function Digest(self)

    local digestDuration = GetEffectiveDigestDuration(self)
    
    // Reset the digest timer if this entity hasn't been
    // digested in a while.
    local now = Shared.GetTime()
    if now - self.lastDigestUseTime > kAllowedReleaseTimeBeforeReset then
        self.digestDoneTime = Shared.GetTime()+digestDuration
    end
    
    // Are we done??
    if now >= self.digestDoneTime then
    
        self:TriggerEffects("digest", {effecthostcoords = self:GetCoords()} )
        self.consumed = true

        if self.OnDigested then
            self:OnDigested()
        else
            self:Kill()
        end
        
    end
    
    // update
    self.lastDigestUseTime = now
    
end

function DigestMixin:OnUse(player, elapsedTime, useSuccessTable)

    local canDigest = false

    if self.GetCanDigest then
        canDigest = self:GetCanDigest(player)
    else
        canDigest = player == self:GetOwner() and player:isa("Gorge") and (not HasMixin(self, "Live") or self:GetIsAlive())
    end
    
    if canDigest then
        Digest(self)
    end
    
end

function DigestMixin:GetDigestFraction()

    local now = Shared.GetTime()
    if now-self.lastDigestUseTime > kAllowedReleaseTimeBeforeReset then
        return 0
    else
    
        local digestDuration = GetEffectiveDigestDuration(self)
        local digestRemaining = self.digestDoneTime - now;
        return 1.0 - (digestRemaining/digestDuration)
        
    end
    
end
