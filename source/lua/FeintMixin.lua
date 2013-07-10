// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FeintMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)    
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

FeintMixin = CreateMixin( FeintMixin )
FeintMixin.type = "Feint"

FeintMixin.expectedMixins =
{
    Live = "To react on damage taken and trigger the fake ragdoll."
}

FeintMixin.networkVars =
{
    timeLastFeint = "time"
}

local kFeintTimeOut = 20
local kFeintTriggerHealthScalar = 0.1
local kFeintDuration = 3

local kFeintMaxSpeed = 1.5

function FeintMixin:__initmixin()
    self.timeLastFeint = 0
    self.wasOnFullHealth = true
end

function FeintMixin:GetIsFeinting()
    return self.timeLastFeint + kFeintDuration > Shared.GetTime()
end

if Server then

    local function FeintDeath(self, attacker, doer)

        self.wasOnFullHealth = false
    
        local index = kDeathMessageIcon.None
        
        if doer and doer.GetDeathIconIndex then
        
            index = doer:GetDeathIconIndex()
            assert(type(index) == "number")
            
        end
        
        local enemyTeam = GetGamerules():GetTeam(GetEnemyTeamNumber(self:GetTeamNumber()))
        enemyTeam:SendCommand(enemyTeam:GetDeathMessage(attacker, index, self))
        CreateRagdoll(self)
        
        if HasMixin(self, "GameEffects") then
            self:SetGameEffectMask(kGameEffect.OnFire, false)
        end
        
        self.timeLastFeint = Shared.GetTime()
        
        // cancel any attacks
        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon then
        
            activeWeapon:OnPrimaryAttackEnd(self)
            activeWeapon:OnSecondaryAttackEnd(self)
        
        end
        
        self:SetHealth(kFeintTriggerHealthScalar * self:GetMaxHealth())
    
    end

    local function GetCanFeint(self)    
        return GetHasFeintUpgrade(self) and self.timeLastFeint + kFeintTimeOut < Shared.GetTime() and self:GetHealthScalar() < kFeintTriggerHealthScalar and self.wasOnFullHealth   
    end
    
    function FeintMixin:AttemptToKill(damage, attacker, doer, point)
    
        if GetCanFeint(self) then
            FeintDeath(self, attacker, doer)
        end
        
        // return false to prevent actual dying
        return not self:GetIsFeinting()
        
    end

    function FeintMixin:OnTakeDamage(damage, attacker, doer, point)
    
        if GetCanFeint(self) then
            FeintDeath(self, attacker, doer)        
        end
        
    end
    
    function FeintMixin:OnHealed()
    
        if self:GetHealthScalar() == 1 then
            self.wasOnFullHealth = true
        end
    
    end

elseif Client then
    
    function FeintMixin:OnGetIsVisible(visibleTable, viewerTeamNumber)
    
        local player = Client.GetLocalPlayer()
        
        if self:GetIsAlive() and self:GetIsFeinting() then
            visibleTable.Visible = false        
        end

    end
    
end

function FeintMixin:OnClampSpeed(input, velocity)

    PROFILE("FeintMixin:OnClampSpeed")
    
    if self:GetIsFeinting() and (self.GetIsOnSurface and self:GetIsOnSurface()) then
    
        local moveSpeed = velocity:GetLength()
        if moveSpeed > kFeintMaxSpeed then        
            velocity:Scale(kFeintMaxSpeed / moveSpeed)
        end
        
    end
    
end
