// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//    
// lua\FlinchMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

FlinchMixin = CreateMixin(FlinchMixin)
FlinchMixin.type = "Flinch"

FlinchMixin.expectedCallbacks =
{
    TriggerEffects = "The flinch effect will be triggered through this callback.",
    GetMaxHealth = "Returns the maximum amount of health this entity can have.",
    SetPoseParam = "Set the named pose parameter to the passed in value."
}

FlinchMixin.optionalCallbacks =
{
    GetCustomFlinchEffectName = "Return a custom effect name."
}

// Takes this much time to reduce flinch completely.
local kFlinchIntensityReduceRate = 0.4

FlinchMixin.networkVars =
{
    // how intense the flinching is from 0 to 1
    flinchIntensity = "compensated float (0 to 1 by 0.05)"
}

local kWorldY = Vector(0, 1, 0)
local function UpdateDamagedEffects(self)

    PROFILE("FlinchMixin:UpdateDamagedEffects")
    
    local updateDamagedEffects = not self:isa("Player") or (not self:GetIsLocalPlayer() or self:GetIsThirdPerson())
    updateDamagedEffects = updateDamagedEffects and (not HasMixin(self, "Live") or self:GetIsAlive())
    updateDamagedEffects = updateDamagedEffects and (not HasMixin(self, "Construct") or self:GetIsBuilt())
    updateDamagedEffects = updateDamagedEffects and (not HasMixin(self, "Cloakable") or not self:GetIsCloaked())
    updateDamagedEffects = updateDamagedEffects and self:GetIsVisible()
    
    if updateDamagedEffects then
    
        local coords = self:GetCoords()
        if coords.yAxis:DotProduct(kWorldY) ~= 1 then
            coords = Coords.GetTranslation(self:GetOrigin())
        end
        
        local healthScalar = self:GetHealthScalar()
        if healthScalar < 0.3 then
            self:TriggerEffects("damaged", { flinch_severe = true, effecthostcoords = coords })
        elseif healthScalar < 0.6 then
            self:TriggerEffects("damaged", { flinch_severe = false, effecthostcoords = coords })
        end
        
    end
    
    -- Continue forever.
    return true
    
end

local function UpdateFlinchEffects(self)

    PROFILE("FlinchMixin:UpdateFlinchEffects")
    
    if self.flinchDamageThisFrame ~= 0 then
    
        local flinchParams = { flinch_severe = self.flinchDamageThisFrame > 0.35 or self.flinchIntensity > 0.35, effecthostcoords = self:GetCoords(), damagetype = self.flinchLastDamageType }
        self:TriggerEffects("flinch", flinchParams)
        
        self.flinchDamageThisFrame = 0
        
    end
    
    -- Continue forever.
    return true
    
end

function FlinchMixin:__initmixin()

    self.flinchIntensity = 0
    self.lastHealthScalar = 1
    
    if Server then
        self.flinchIntensityStored = 0
    end
    
    if Client then
    
        self.flinchDamageThisFrame = 0
        self.flinchLastDamageType = kDamageType.Normal
        self:AddTimedCallback(UpdateDamagedEffects, 3)
        self:AddTimedCallback(UpdateFlinchEffects, 1)
        
    end
    
end

if Server then

    function FlinchMixin:OnTakeDamage(damage, attacker, doer, point, direction)
    
        // Once entity has taken this much damage in a second, it is flinching at it's maximum amount
        local maxFlinchDamage = self:GetMaxHealth() * 0.2
        
        local flinchAmount = damage / maxFlinchDamage
        self.flinchIntensityStored = Clamp(self.flinchIntensityStored + flinchAmount, 0.2, 1)
        
        // Make sure new flinch intensity is big enough to be visible, but don't add too much from a bunch of small hits
        // Flamethrower make Harvester go wild
        
        local damageType = kDamageType.Flame
        if doer then
        
            if doer.GetDamageType then
                damageType = doer:GetDamageType()
            end
            
        end
        
        if doer and HasMixin(doer, "Live") and damageType == kDamageType.Flame then
            self.flinchIntensityStored = self.flinchIntensityStored + 0.1
        end
        
    end
    
    local function UpdateFlinch(self, deltaTime)
    
        self.flinchIntensityStored = Clamp(self.flinchIntensityStored - deltaTime * kFlinchIntensityReduceRate, 0, 1)
        self.flinchIntensity = self.flinchIntensityStored
        
    end
    
    function FlinchMixin:OnUpdate(deltaTime)
        UpdateFlinch(self, deltaTime)
    end
    
    function FlinchMixin:OnProcessMove(input)
        UpdateFlinch(self, input.time)
    end
    
end

function FlinchMixin:OnTakeDamageClient(damage, doer, position)

    // Get damage type from source.
    local damageType = kDamageType.Normal
    if doer then
    
        if doer.GetDamageType then
            damageType = doer:GetDamageType()
        elseif HasMixin(doer, "Tech") then
            damageType = LookupTechData(doer:GetTechId(), kTechDataDamageType, kDamageType.Normal)
        end
        
    end
    
    self.flinchDamageThisFrame = self.flinchDamageThisFrame + math.abs(self.lastHealthScalar - self:GetHealthScalar())
    self.flinchLastDamageType = damageType
    self.lastHealthScalar = self:GetHealthScalar()
    
end

function FlinchMixin:OnUpdatePoseParameters()

    PROFILE("FlinchMixin:OnUpdatePoseParameters")
    
    self:SetPoseParam("intensity", self.flinchIntensity)

end

function FlinchMixin:GetFlinchIntensity()
    return self.flinchIntensity
end

function FlinchMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("FlinchMixin:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("flinch", self.flinchIntensity > 0)
    
end