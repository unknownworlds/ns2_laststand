// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\MaturityMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//  
//    Responsible for letting alien structures become mature. Determine "Mature Fraction" which
//    increases over time, 0.0 - 1.0.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")

MaturityMixin = CreateMixin( MaturityMixin )
MaturityMixin.type = "Maturity"

kMaturityLevel = enum({ 'Newborn', 'Grown', 'Mature' })

// 1 minute until structure is fully grown
local kDefaultMaturityRate = 60

MaturityMixin.networkVars =
{
    isMature = "boolean"
}

MaturityMixin.expectedMixins =
{
    Live = "MaturityMixin will adjust max health/armor over time.",
}

MaturityMixin.optionalCallbacks = 
{
    GetMaturityRate = "Return individual maturity rate in seconds.",
    GetMatureMaxHealth = "Return individual mature health.",
    GetMatureMaxArmor = "Return individual mature armor.",
    OnMaturityComplete = "Callback once 100% maturity has been reached."
}

local function GetMaturityRate(self)

    if self.GetMaturityRate then
        return self:GetMaturityRate()
    end
    
    return kDefaultMaturityRate
    
end

function MaturityMixin:__initmixin()

    if Server then
    
        self.matureFraction = 0
        self.timeMaturityLastUpdate = 0
        self.isMature = false
        self.updateMaturity = not HasMixin(self, "Construct") or self:GetIsBuilt()

        if self.startsMature then
            self:SetMature()
        end
        
    end
    
end

function MaturityMixin:OnConstructionComplete()
    self.updateMaturity = true
end

function MaturityMixin:OnKill()
    self.updateMaturity = false
end

local function GetMaturityHealth(self)

    local maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth, 100)
    // use 1.5 times normal health as default
    local matureHealth = maxHealth * 1.5
    
    if self.GetMatureMaxHealth then
        matureHealth = self:GetMatureMaxHealth()
    end
    
    return maxHealth + (matureHealth - maxHealth) * self:GetMaturityFraction()
    
end

local function GetMaturityArmor(self)

    local maxArmor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, 0)
    // use 1.5 times normal armor as default
    local matureArmor = maxArmor * 1.5
    
    if self.GetMatureMaxArmor then
        matureArmor = self:GetMatureMaxArmor()
    end
    
    return maxArmor + (matureArmor - maxArmor) * self:GetMaturityFraction()
    
end

function MaturityMixin:UpdateMaturity()

    // health/armor fractions are maintained by using "Adjust" functions
    local newMaxHealth = GetMaturityHealth(self)
    self:AdjustMaxHealth(newMaxHealth)
    
    local newMaxArmor = GetMaturityArmor(self)
    self:AdjustMaxArmor(newMaxArmor)

end

local function SharedUpdate(self, deltaTime)

    PROFILE("MaturityMixin:OnUpdate")
    
    if Server then
    
        if self.updateMaturity then
        
            local updateRate = GetMaturityRate(self)
            local devMultiplier = ConditionalValue(Shared.GetDevMode(), 100, 1)
            local mistMultiplier = ConditionalValue(HasMixin(self, "Catalyst") and self:GetIsCatalysted(), kNutrientMistMaturitySpeedup, 1)
            
            local prevmatureFraction = self.matureFraction
            self.matureFraction = math.min(self.matureFraction + deltaTime * (1 / updateRate) * devMultiplier * mistMultiplier, 1)
            
            if prevmatureFraction ~= self.matureFraction and self.matureFraction == 1.0 then
            
                if self.OnMaturityComplete then
                    self:OnMaturityComplete()
                    self.updateMaturity = false
                    self.isMature = true
                end
            
            end
            
            // to prevent too much network spam from happening we update only every second the max health
            if self.isMature or (self.timeMaturityLastUpdate + 1 < Shared.GetTime()) then
            
                self:UpdateMaturity()
                self.timeMaturityLastUpdate = Shared.GetTime()
                
            end
            
        end
        
    elseif Client then
    
        // TODO: maturity effects, shaders
        if HasMixin(self, "Model") then
        
            local model = self:GetRenderModel()
            if model then
                model:SetMaterialParameter("maturity", self:GetMaturityFraction())
            end
        
        end
        
    end
    
end

function MaturityMixin:GetIsMature()
    return self:GetMaturityFraction() == 1
end

function MaturityMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function MaturityMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

// TODO: set maturity param
/*function MaturityMixin:OnUpdateAnimationInput(modelMixin)
end*/

function MaturityMixin:GetMaturityFraction()

    if Server then
        return self.matureFraction
    elseif Client then
    
        if self.isMature then
            return 1.0
        end
        
        local defaultHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth, 1)
        local matureHealth = self:GetMatureMaxHealth()
        
        local defaultArmor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, 1)
        local matureArmor = self:GetMatureMaxArmor()
        
        local currentDiff = 0
        local totalDiff = 0
        
        if defaultHealth ~= matureHealth then    
        
            currentDiff = matureHealth - self:GetMaxHealth()
            totalDiff = matureHealth - defaultHealth
        
        elseif defaultArmor ~= matureArmor then
        
            currentDiff = matureArmor - self:GetMaxArmor()
            totalDiff = matureArmor - defaultArmor
        
        end
        
        if totalDiff == 0 then
            return 0
        end    
    
        return 1 - Clamp(currentDiff / totalDiff, 0, 1)
        
    end
    
end

function MaturityMixin:GetMaturityLevel()

    local matureFraction = self:GetMaturityFraction()

    if matureFraction < 0.5 then
        return kMaturityLevel.Newborn
    elseif matureFraction < 1 then
        return kMaturityLevel.Grown
    else
        return kMaturityLevel.Mature
    end    
    
end

if Server then

    // For testing.
    function MaturityMixin:SetMature()
        self.matureFraction = 0.999
    end
    
    function MaturityMixin:ResetMaturity()
    
        self.matureFraction = 0
        self.updateMaturity = true
        self.isMature = false
        
    end
    
end