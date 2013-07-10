// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CamouflageMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//
// Have entities disappear if they have camouflage upgrade and are still.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

CamouflageMixin = CreateMixin( CamouflageMixin )
CamouflageMixin.type = "Camouflage"
CamouflageMixin.kVelocityThreshold = kCamouflageVelocity
CamouflageMixin.kBreakingDelay = 1

CamouflageMixin.kCamouflageRate = 0.5
CamouflageMixin.kUnCamouflageRate = 2

CamouflageMixin.expectedMixins = 
{
    Cloakable = "Maintains visibility."
}

CamouflageMixin.expectedCallbacks = 
{
    GetVelocity = "Return vector representing velocity.",
    GetIsAlive = "Bool returning alive/dead",
    GetHasUpgrade = "Pass bit mask indicating upgrade, return true/false if entity has it",

}

CamouflageMixin.optionalCallbacks = 
{
    GetCanCamouflage = "Returns boolean",
}

CamouflageMixin.networkVars =
{
    camouflaged = "boolean"
}

function CamouflageMixin:__initmixin()

    self.camouflaged = false
    self.timeLastUncamouflageTriggered = 0
    
end

function CamouflageMixin:GetIsCamouflaged()
    return self.camouflaged
end

function CamouflageMixin:TriggerUncamouflage()
    self.timeLastUncamouflageTriggered = Shared.GetTime()
end

local function UpdateCamouflage(self, deltaTime)

    // Have entities disappear if they have camouflage and are still
    local velocity = self:GetVelocity():GetLength()
    local currentTime = Shared.GetTime()
    
    local canCamouflage = not self.GetCanCamouflage or self:GetCanCamouflage()
    canCamouflage = canCamouflage and currentTime > (self.timeLastUncamouflageTriggered + CamouflageMixin.kBreakingDelay)
    
    if self:GetIsAlive() and GetHasCamouflageUpgrade(self) and velocity <= CamouflageMixin.kVelocityThreshold and canCamouflage then    
        self.camouflaged = true
    else
        self.camouflaged = false
    end

end


// only do the checking for uncamo on the server side
if Server then

    function CamouflageMixin:OnUpdate(deltaTime)
        UpdateCamouflage(self, deltaTime)
    end

    function CamouflageMixin:OnProcessMove(input)
        UpdateCamouflage(self, input.time)
    end
    
end

//self.movementModiferState
function CamouflageMixin:GetCamouflageMaxSpeed(walking)

    if walking and self:GetIsCamouflaged() then
        return true, CamouflageMixin.kVelocityThreshold * .75
    end
    
    return false, nil
    
end

function CamouflageMixin:OnScan()
    self:TriggerUncamouflage()
end

function CamouflageMixin:PrimaryAttack()
    self:TriggerUncamouflage()
end

function CamouflageMixin:SecondaryAttack()
     //$AS Check to make sure we have a secondary weapon active
    // this way we do not trigger
    local hasSecondary = true
    local weapon = self:GetActiveWeapon()
    
    if (weapon ~= nil and weapon:isa("Ability")) then
        hasSecondary = weapon:GetHasSecondary(self)
    end
    
    if (hasSecondary) then
        self:TriggerUncamouflage()
    end
end

function CamouflageMixin:OnJump()
    self:TriggerUncamouflage()
end

function CamouflageMixin:OnTakeDamage(damage, attacker, doer, point)
    self:TriggerUncamouflage()
end

function CamouflageMixin:OnCapsuleTraceHit(entity)

    if GetAreEnemies(self, entity) then
        self:TriggerUncamouflage()
    end
    
end
