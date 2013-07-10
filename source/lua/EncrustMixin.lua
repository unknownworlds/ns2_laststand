// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EncrustMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

EncrustMixin = CreateMixin( EncrustMixin )
EncrustMixin.type = "Encrust"

EncrustMixin.kDefaultOverHealTreshold = 10
// add 10% of overheal to armor
EncrustMixin.kEncrustArmorRate = 0.1
EncrustMixin.kDefaultPoint = 5
EncrustMixin.kEnrustFalloffRate = 0.05

EncrustMixin.expectedCallbacks =
{
    OnOverHealTreshold = "Called when the treshold has been passed."
}

EncrustMixin.optionalCallbacks =
{
    GetOverHealTresholdOverride = "Custom treshold that defined when an effect happens.",
    GetEnrustReward = "Return an option reward amount for healing.",
    GetCanReward = "Return true or false, for example adding a time out between rewards."
}

EncrustMixin.networkVars = {
    encrustFraction = "float (0 to 1 by 0.01)"
}

function EncrustMixin:__initmixin()

    self.healerTable = {}
    self.encrustFraction = 0
    
end

function EncrustMixin:GetEncrustFraction()
    return self.encrustFraction
end    

function EncrustMixin:StoreHealer(healerId, amountHealed)

    local heal = amountHealed
    if self.healerTable[healerId] then
        heal = heal + self.healerTable[healerId] 
    end
    
    self.healerTable[healerId] = heal
    
end

function EncrustMixin:GetOverHealTreshold()

    if self.GetOverHealTresholdOverride then
        return self:GetOverHealTresholdOverride()
    end

    return EncrustMixin.kDefaultOverHealTreshold
    
end

function EncrustMixin:ResetHealer(healerId)
    self.healerTable[healerId] = nil
end

function EncrustMixin:RewardHealer(healer)

    local reward = EncrustMixin.kDefaultPoint
    local resources = 0

    if self.GetEnrustReward then
        reward, resources = self:GetEnrustReward()
    end
    
    healer:AddScore(reward, resources)
    
end

function EncrustMixin:OnEntityChange(oldEntityId, newEntityId)

    if self.healerTable[oldEntityId] then

        if newEntityId and Shared.GetEntity(newEntityId):GetIsAlive() == true then
            self.healerTable[newEntityId] = self.healerTable[oldEntityId]
        end
        
        self.healerTable[oldEntityId] = nil
    
    end
    
end

function EncrustMixin:OverHeal(player, overHealAmount)

    if player and (not HasMixin(self, "Construct") or self:GetIsBuilt()) then
    
        if not self.GetCanReward or self:GetCanReward(player) then
        
            local addFraction = amountHealed / self:GetOverHealTreshold()
            self.encrustFraction = self.encrustFraction + addFraction
    
	        local playerId = player:GetId()
	        
	        overHealAmount = EncrustMixin.kEncrustArmorRate * overHealAmount
	        self.armor = math.min(self:GetMaxArmor() + self:GetOverHealTreshold(), self.armor + overHealAmount)
	        
	        self:StoreHealer(playerId, overHealAmount)
	        
	        // check if treshold has been passed
	        if self.healerTable[playerId] > self:GetOverHealTreshold() then
	            self:OnOverHealTreshold(player)
	            self:ResetHealer(playerId)
	            self:RewardHealer(player)
	        else
	            local percentage = math.floor((self.healerTable[playerId] / self:GetOverHealTreshold()) * 100)
	            Print("encrust percentage: ", ToString(percentage))
	        end
        
        else
        
            self.healerTable = {}
        
        end
    
    end

end

local function SharedUpdate(self, deltaTime)

    if Server then
    
        local oldFraction = self.encrustFraction
        self.encrustFraction = math.max(0, self.encrustFraction - deltaTime * EncrustMixin.kEnrustFalloffRate)
        
        if self:GetArmor() > self:GetMaxArmor() then
        
            self.armor = math.max(self:GetMaxArmor(), self:GetArmor() - self:GetOverHealTreshold() * (oldFraction - self.encrustFraction) )
        
        end
    
    elseif Client then
    
        // TODO: load material and pass self.encrustFraction as parameter
    
    end

end

function EncrustMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function EncrustMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end