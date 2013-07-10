// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spores.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
// 
// Spores main attack, spikes secondary
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SpikesMixin.lua")
Script.Load("lua/Weapons/Alien/SporeCloud.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

kSporesHUDSlot = 2

local function CreateSporeCloud(self, origin, player)

    local spores = CreateEntity(SporeCloud.kMapName, origin, player:GetTeamNumber())
    
    spores:SetOwner(player)
    
    local coords = player:GetCoords()
    
    local velocity = player:GetVelocity()
    if velocity:Normalize() > 0.0 then
        // adjusts the effect to the players move direction (strafe + sporing)
        zAxis = velocity
    end
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
    coords.yAxis = coords.xAxis:CrossProduct(coords.zAxis)
    
    spores:SetCoords(coords)

    return spores
    
end

local function GetHasSporeCloudsInRangeWithLifeTime(position, range, minLifeTime)
    
    for index, sporeCloud in ipairs(GetEntitiesWithinRange("SporeCloud", position, range)) do
    
        if sporeCloud:GetRemainingLifeTime() >= minLifeTime then
            return true
        end
    
    end
    
end

class 'Spores' (Ability)

Spores.kMapName = "Spores"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")

// no sporeclouds will be created when another cloud in kCheckSporeRange with remaining life time > kCheckSporeLifeTime is found
local kCheckSporeRange = kSporesDustCloudRadius * 0.7
local kCheckSporeLifeTime = kSporesDustCloudLifetime * 0.7

local kSporesBlockingTime = 0.3

local kLoopingDustSound = PrecacheAsset("sound/NS2.fev/alien/lerk/spore_spray")

local networkVars =
{
    lastPrimaryAttackStartTime = "time",
    lastPrimaryAttackEndTime = "time"
}

AddMixinNetworkVars(SpikesMixin, networkVars)

function Spores:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, SpikesMixin)
    
    self.primaryAttacking = false
    
    if Server then
        
        self.loopingSporesSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingSporesSound:SetAsset(kLoopingDustSound)
        self.loopingSporesSound:SetParent(self)
        
    elseif Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function Spores:OnDestroy()

    Ability.OnDestroy(self)
    
    // The loopingSporesSound was already destroyed at this point, clear the reference.
    if Server then
        self.loopingSporesSound = nil  
    end
    
end

function Spores:GetAnimationGraphName()
    return kAnimationGraph
end

function Spores:GetEnergyCost(player)
    return kSporesDustEnergyCost
end

function Spores:GetHUDSlot()
    return kSporesHUDSlot
end

function Spores:GetRange()
    return kRange
end

function Spores:GetDeathIconIndex()
    return kDeathMessageIcon.Spikes
end

function Spores:GetSecondaryTechId()
    return kTechId.Spikes
end

function Spores:GetAttackDelay()
    return kSporesDustFireDelay
end

function Spores:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not GetHasSporeCloudsInRangeWithLifeTime(player:GetOrigin(), kCheckSporeRange, kCheckSporeLifeTime) then
    
        self.primaryAttacking = true
        self:PerformPrimaryAttack(player)
        
    else
        self.primaryAttacking = false
    end
    
end

function Spores:OnPrimaryAttackEnd()
    
    self.primaryAttacking = false
    self.lastPrimaryAttackEndTime = Shared.GetTime()
    
    if Server then
        self.loopingSporesSound:Stop()
    end
    
end

function Spores:PerformPrimaryAttack(player)

    // Create long-lasting spore cloud near player that can be used to prevent marines from passing through an area.
    if (Shared.GetTime() - self.lastPrimaryAttackStartTime) > self:GetAttackDelay() then
    
        self.lastPrimaryAttackStartTime = Shared.GetTime()
        
        if Client then
            self:TriggerEffects("spores_attack")
        end
        
        if Server then
        
            local origin = player:GetModelOrigin()
            local sporecloud = CreateSporeCloud(self, origin, player)
            if not self.loopingSporesSound:GetIsPlaying() and not GetHasSilenceUpgrade(player) then
                self.loopingSporesSound:Start()
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
        end
        
    end
    
end

function Spores:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self.primaryAttacking = false
    // in case the sound has not been created yet (spamming weapon switch or client sync), check if it exists
    if self.loopingSporesSound then
        self.loopingSporesSound:Stop()
    end
    
end



function Spores:OnUpdateAnimationInput(modelMixin)

    PROFILE("Spikes:OnUpdateAnimationInput")
    

    if not self:GetIsSecondaryBlocking() then
    
        modelMixin:SetAnimationInput("ability", "spores")
        
        local activityString = "none"
        if self.primaryAttacking then
            activityString = "primary"
        end
        
        modelMixin:SetAnimationInput("activity", activityString)
    
    end
    
end

Shared.LinkClassToMap("Spores", Spores.kMapName, networkVars)