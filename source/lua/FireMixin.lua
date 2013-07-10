// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FireMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com) and
//                  Andreas Urwalek (andi@unknownworlds.com)   
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

FireMixin = CreateMixin( FireMixin )
FireMixin.type = "Fire"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/burning.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/burning_view.surface_shader")

local kBurnBigCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_big.cinematic")
local kBurnHugeCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_huge.cinematic")
local kBurnMedCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_med.cinematic")
local kBurnSmallCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_small.cinematic")
local kBurn1PCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_1p.cinematic")

local fireCinematicTable = { }
fireCinematicTable["Hive"] = kBurnHugeCinematic
fireCinematicTable["CommandStation"] = kBurnHugeCinematic
fireCinematicTable["Clog"] = kBurnSmallCinematic
fireCinematicTable["Onos"] = kBurnBigCinematic
fireCinematicTable["MAC"] = kBurnSmallCinematic
fireCinematicTable["Drifter"] = kBurnSmallCinematic
fireCinematicTable["Sentry"] = kBurnSmallCinematic
fireCinematicTable["Egg"] = kBurnSmallCinematic
fireCinematicTable["Embryo"] = kBurnSmallCinematic

local function GetOnFireCinematic(ent, firstPerson)

    if firstPerson then
        return kBurn1PCinematic
    end
    
    return fireCinematicTable[ent:GetClassName()] or kBurnMedCinematic
    
end

FireMixin.networkVars =
{
    isOnFire = "boolean",
    numStacks = string.format("integer (0 to %d)", kFlamethrowerMaxStacks)
}

function FireMixin:__initmixin()

    self.numStacks = 0

    if Server then
    
        self.fireAttackerId = Entity.invalidId
        self.fireDoerId = Entity.invalidId
        
        self.timeBurnInit = 0
        self.timeLastStackAdded = 0
        
        self.isOnFire = false
        
    end
    
end

function FireMixin:OnDestroy()

    if self:GetIsOnFire() then
        self:SetGameEffectMask(kGameEffect.OnFire, false)
    end
    
end

function FireMixin:SetOnFire(attacker, doer)

    if Server then
    
        if not self:GetCanBeSetOnFire() then
            return
        end
        
        self:SetGameEffectMask(kGameEffect.OnFire, true)
        
        if attacker then
            self.fireAttackerId = attacker:GetId()
        end
        
        if doer then
            self.fireDoerId = doer:GetId()
        end
        
        if self.timeLastStackAdded == 0 or Shared.GetTime() - self.timeLastStackAdded > kFlamethrowerStackRate then
        
            self.timeLastStackAdded = Shared.GetTime()
            if self.numStacks < kFlamethrowerMaxStacks then
                self.numStacks = self.numStacks + 1;
            end
            
        end
        
        self.timeBurnInit = Shared.GetTime()
        self.isOnFire = true
        
    end
    
end

function FireMixin:GetIsOnFire()

    if Client then
        return self.isOnFire
    end

    return self:GetGameEffectMask(kGameEffect.OnFire)
    
end

function FireMixin:GetCanBeSetOnFire()

    if self.OnOverrideCanSetFire then
        return self:OnOverrideCanSetFire(attacker, doer)
    else
        return true
    end
  
end

function UpdateFireMaterial(self)

    if self._renderModel then
    
        if self.isOnFire and not self.fireMaterial then
        
            self.fireMaterial = Client.CreateRenderMaterial()
            self.fireMaterial:SetMaterial("cinematics/vfx_materials/burning.material")
            self._renderModel:AddMaterial(self.fireMaterial)
            
        elseif not self.isOnFire and self.fireMaterial then
        
            self._renderModel:RemoveMaterial(self.fireMaterial)
            Client.DestroyRenderMaterial(self.fireMaterial)
            self.fireMaterial = nil
            
        end
        
    end
    
    if self:isa("Player") and self:GetIsLocalPlayer() then
    
        local viewModelEntity = self:GetViewModelEntity()
        if viewModelEntity then
        
            local viewModel = self:GetViewModelEntity():GetRenderModel()
            if viewModel and (self.isOnFire and not self.viewFireMaterial) then
            
                self.viewFireMaterial = Client.CreateRenderMaterial()
                self.viewFireMaterial:SetMaterial("cinematics/vfx_materials/burning_view.material")
                viewModel:AddMaterial(self.viewFireMaterial)
                
            elseif viewModel and (not self.isOnFire and self.viewFireMaterial) then
            
                viewModel:RemoveMaterial(self.viewFireMaterial)
                Client.DestroyRenderMaterial(self.viewFireMaterial)
                self.viewFireMaterial = nil
                
            end
            
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    if Client then
        UpdateFireMaterial(self)
        self:_UpdateClientFireEffects()
    end

    if not self:GetIsOnFire() then
        return
    end
    
    if Server then
    
        // stacks are applied at ComputeDamageOverride
        local damageOverTime = kBurnDamagePerStackPerSecond * deltaTime
        if self.GetIsFlameAble and self:GetIsFlameAble() then
            damageOverTime = damageOverTime * kFlameableMultiplier
        end
        
        local attacker = nil
        if self.fireAttackerId ~= Entity.invalidId then
            attacker = Shared.GetEntity(self.fireAttackerId)
        end

        local doer = nil
        if self.fireDoerId ~= Entity.invalidId then
            doer = Shared.GetEntity(self.fireDoerId)
        end
        
        self:DeductHealth(damageOverTime, attacker, doer)
        
        // See if we put ourselves out
        if Shared.GetTime() - self.timeBurnInit > kFlamethrowerBurnDuration then
            self:SetGameEffectMask(kGameEffect.OnFire, false)
        end
        
    end
    
end

function FireMixin:ComputeDamageOverrideMixin(attacker, damage, damageType, time) 
    
    if self:GetIsOnFire() and damageType == kDamageType.Flame then
        damage = damage + damage * self.numStacks * kFlameDamageStackWeight
    end
    
    return damage
    
end

function FireMixin:OnUpdate(deltaTime)   
    SharedUpdate(self, deltaTime)
end

function FireMixin:OnProcessMove(input)   
    SharedUpdate(self, input.time)
end

if Client then
    
    function FireMixin:_UpdateClientFireEffects()

        // Play on-fire cinematic every so often if we're on fire
        if self:GetGameEffectMask(kGameEffect.OnFire) and self:GetIsAlive() and self:GetIsVisible() then
        
            // If we haven't played effect for a bit
            local time = Shared.GetTime()
            
            if not self.timeOfLastFireEffect or (time > (self.timeOfLastFireEffect + .5)) then
            
                local firstPerson = (Client.GetLocalPlayer() == self)
                local cinematicName = GetOnFireCinematic(self, firstPerson)
                
                if firstPerson then
                    local viewModel = self:GetViewModelEntity()
                    if viewModel then
                        Shared.CreateAttachedEffect(self, cinematicName, viewModel, Coords.GetTranslation(Vector(0, 0, 0)), "", true, false)
                    end
                else
                    Shared.CreateEffect(self, cinematicName, self, self:GetAngles():GetCoords())
                end
                
                self.timeOfLastFireEffect = time
                
            end
            
        end
        
    end

end

function FireMixin:OnEntityChange(entityId, newEntityId)

    if entityId == self.fireAttackerId then
        self.fireAttackerId = newEntityId or Entity.invalidId
    end
    
    if entityId == self.fireDoerId then
        self.fireDoerId = newEntityId or Entity.invalidId
    end
    
end

function FireMixin:OnGameEffectMaskChanged(effect, state)

    if effect == kGameEffect.OnFire and state then
        self:TriggerEffects("fire_start")
    elseif effect == kGameEffect.OnFire and not state then
    
        self.fireAttackerId = Entity.invalidId
        self.fireDoerId = Entity.invalidId
        
        self:TriggerEffects("fire_stop")
        
        self.timeLastStackAdded         = 0
        self.numStacks                  = 0
        self.timeBurnInit               = 0 
        
        self.isOnFire = false
        
    end
    
end

function FireMixin:OnUpdateAnimationInput(modelMixin)
    PROFILE("FireMixin:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("onfire", self:GetIsOnFire())
end