// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CatalystMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used for catalyst abilities. It manages client effects and uses the stackable catalyst game
//    effect mask. GetCatalystScalar returns a value between 0.5 - 1 (0 when not catalysted).
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

CatalystMixin = CreateMixin( CatalystMixin )
CatalystMixin.type = "Catalyst"

CatalystMixin.kDefaultDuration = 10
CatalystMixin.kCatalystSpeedUp = 0.7

CatalystMixin.kEffectIntervall = 1.5
CatalystMixin.kEffectName = "catalyst"

CatalystMixin.optionalCallbacks = {

    OnCatalyst = "Called when catalyst is triggered.",
    OnCatalystEnd = "Called at catalyst time out."
    
}

CatalystMixin.networkVars = {
    
    isCatalysted = "boolean"
    
}

function CatalystMixin:__initmixin()

    self.maxCatalystStacks = CatalystMixin.kDefaultCatalystStacks

    if Client then
    
        self.isCatalystedClient = false
        
    elseif Server then
    
        self.isCatalysted = false
        self.timeUntilCatalystEnd = 0
        
    end
    
end

function CatalystMixin:GetCatalystScalar()

    if self.isCatalysted then
        return 1
    end
    
    return 0
    
end

function CatalystMixin:GetIsCatalysted()
    return self.isCatalysted
end

function CatalystMixin:GetCanCatalyst()
    return (not HasMixin(self, "Construct") or self:GetIsBuilt()) and (( HasMixin(self, "Maturity") and not self:GetIsMature() ) or self:isa("Embryo"))
end

if Client then

    function CatalystMixin:UpdateCatalystClientEffects(deltaTime)
    
        local player = Client.GetLocalPlayer()
        
        if player and player == self and not player:GetIsThirdPerson() then
            return
        end    

        if not self.timeLastCatalystEffect then
            self.timeLastCatalystEffect = Shared.GetTime()
        end
        
        local showEffect = not HasMixin(self, "Cloakable") or not self:GetIsCloaked() or not GetAreEnemies(self, player)

        if self.timeLastCatalystEffect + CatalystMixin.kEffectIntervall < Shared.GetTime() then
        
            if showEffect then
                self:TriggerEffects(CatalystMixin.kEffectName)
            end
            
            self.timeLastCatalystEffect = Shared.GetTime()
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    if self.isCatalysted then
    
        if Client then
        
            if self.isCatalystedClient == false then
                if self.OnCatalyst then
                    self:OnCatalyst()
                end
                self.isCatalystedClient = true
            end
            
            self:UpdateCatalystClientEffects(deltaTime)
        
        elseif Server then
    
            self.timeUntilCatalystEnd = math.max(self.timeUntilCatalystEnd - deltaTime, 0)
            
            if self.timeUntilCatalystEnd == 0 then
                self.isCatalysted = false
            end
        
        end
    
    else
        if Client then
        
            if self.isCatalystedClient then
                if self.OnCatalystEnd then
                    self:OnCatalystEnd()
                end
                self.isCatalystedClient = false
            end
            
        end
    end

end

function CatalystMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function CatalystMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function CatalystMixin:TriggerCatalyst(duration)

    if Server and self:GetCanCatalyst() then
        self.timeUntilCatalystEnd = ConditionalValue(duration ~= nil, duration, CatalystMixin.kDefaultDuration)
        self.isCatalysted = true
    end
    
end

function CatalystMixin:CopyPlayerDataFrom(player)

    if player.isCatalysted then
        self.isCatalysted = player.isCatalysted
    end
    
    if player.timeUntilCatalystEnd then
        self.timeUntilCatalystEnd = player.timeUntilCatalystEnd
    end

end