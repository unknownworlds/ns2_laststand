// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\Railgun.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/BulletsMixin.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponSlotMixin.lua")
Script.Load("lua/TechMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'Railgun' (Entity)

Railgun.kMapName = "railgun"

local kChargeTime = 2
// The Railgun will automatically shoot if it is charged for too long.
local kChargeForceShootTime = 3
local kRailgunRange = 400
local kRailgunSpread = Math.Radians(0)
local kBulletSize = 0.12

local kChargeSound = PrecacheAsset("sound/NS2.fev/marine/heavy/railgun_charge")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/alien_frag.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/decals/railgun_hole.surface_shader")

local networkVars =
{
    timeChargeStarted = "time",
    railgunAttacking = "boolean",
    lockCharging = "boolean",
    timeOfLastShot = "time"
}

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ExoWeaponSlotMixin, networkVars)

function Railgun:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, TechMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, BulletsMixin)
    InitMixin(self, ExoWeaponSlotMixin)
    
    self.timeChargeStarted = 0
    self.railgunAttacking = false
    self.lockCharging = false
    self.timeOfLastShot = 0
    
    if Client then
    
        InitMixin(self, ClientWeaponEffectsMixin)
        self.chargeSound = Client.CreateSoundEffect(Shared.GetSoundIndex(kChargeSound))
        self.chargeSound:SetParent(self:GetId())
        
    end

end

function Railgun:OnDestroy()

    Entity.OnDestroy(self)
    
    if self.chargeSound then
    
        Client.DestroySoundEffect(self.chargeSound)
        self.chargeSound = nil
        
    end
    
    if self.chargeDisplayUI then
    
        Client.DestroyGUIView(self.chargeDisplayUI)
        self.chargeDisplayUI = nil
        
    end
    
end

function Railgun:OnPrimaryAttack(player)

    if not self.lockCharging then
    
        if not self.railgunAttacking then
            self.timeChargeStarted = Shared.GetTime()
        end
        self.railgunAttacking = true
        
    end
    
end

function Railgun:GetWeight()
    return kRailgunWeight
end

function Railgun:OnPrimaryAttackEnd(player)
    self.railgunAttacking = false
end

function Railgun:GetBarrelPoint()

    local player = self:GetParent()
    if player then
    
        if player:GetIsLocalPlayer() then
        
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            if self:GetIsLeftSlot() then
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * 0.65 + viewCoords.yAxis * -0.19
            else
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.65 + viewCoords.yAxis * -0.19
            end    
        
        else
    
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            if self:GetIsLeftSlot() then
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * 0.35 + viewCoords.yAxis * -0.15
            else
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.35 + viewCoords.yAxis * -0.15
            end
            
        end    
        
    end
    
    return self:GetOrigin()
    
end

function Railgun:GetTracerEffectName()
    return kRailgunTracerEffectName
end

function Railgun:GetTracerResidueEffectName()
    return kRailgunTracerResidueEffectName
end

function Railgun:GetTracerEffectFrequency()
    return 1
end

function Railgun:GetDeathIconIndex()
    return kDeathMessageIcon.Railgun
end

function Railgun:GetChargeAmount()
    return self.railgunAttacking and math.min(1, (Shared.GetTime() - self.timeChargeStarted) / kChargeTime) or 0
end

local function TriggerSteamEffect(self, player)

    if self:GetIsLeftSlot() then
        player:TriggerEffects("railgun_steam_left")
    elseif self:GetIsRightSlot() then
        player:TriggerEffects("railgun_steam_right")
    end
    
end

local kRailgunBulletExtents = Vector(kBulletSize, kBulletSize, kBulletSize)
local function ExecuteShot(self, startPoint, endPoint, player)

    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAllButIsa("Tunnel"))
    local hitPointOffset = trace.normal * 0.3
    local direction = (endPoint - startPoint):GetUnit()
    local damage = kRailgunDamage + math.min(1, (Shared.GetTime() - self.timeChargeStarted) / kChargeTime) * kRailgunChargeDamage
    
    if trace.fraction < 1 then
    
        // do a max of 10 capsule traces, should be sufficient
        local hitEntities = {}
        for i = 1, 20 do
        
            local capsuleTrace = Shared.TraceBox(kRailgunBulletExtents, startPoint, trace.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
            if capsuleTrace.entity then
            
                if not table.find(hitEntities, capsuleTrace.entity) then
                
                    table.insert(hitEntities, capsuleTrace.entity)
                    self:DoDamage(damage, capsuleTrace.entity, capsuleTrace.endPoint + hitPointOffset, direction, capsuleTrace.surface, false, false)
                
                end
                
            end    
                
            if (capsuleTrace.endPoint - trace.endPoint):GetLength() <= kRailgunBulletExtents.x then
                break
            end
            
            // use new start point
            startPoint = Vector(capsuleTrace.endPoint) + direction * kRailgunBulletExtents.x * 3
        
        end
        
        // for tracer
        local effectFrequency = self:GetTracerEffectFrequency()
        local showTracer = ConditionalValue(GetIsVortexed(player), false, math.random() < effectFrequency)
        self:DoDamage(0, nil, trace.endPoint + hitPointOffset, direction, trace.surface, false, showTracer)
        
        if Client and showTracer then
            TriggerFirstPersonTracer(self, trace.endPoint)
        end
    
    end
    
end

local function Shoot(self, leftSide)

    local player = self:GetParent()
    
    // We can get a shoot tag even when the clip is empty if the frame rate is low
    // and the animation loops before we have time to change the state.
    if player then
    
        player:TriggerEffects("railgun_attack")
        
        local viewAngles = player:GetViewAngles()
        local shootCoords = viewAngles:GetCoords()
        
        local startPoint = player:GetEyePos()
        
        local spreadDirection = CalculateSpread(shootCoords, kRailgunSpread, NetworkRandom)
        
        local endPoint = startPoint + spreadDirection * kRailgunRange
        ExecuteShot(self, startPoint, endPoint, player)
        
        if Client then
            TriggerSteamEffect(self, player)
        end
        
        self.timeOfLastShot = Shared.GetTime()
        
        self.lockCharging = true
        
    end
    
end

if Server then

    function Railgun:OnParentKilled(attacker, doer, point, direction)
    end
    
    /**
     * The Railgun explodes players. We must bypass the ragdoll here.
     */
    function Railgun:OnDamageDone(doer, target)
    
        if doer == self then
        
            if target:isa("Player") and not target:GetIsAlive() then
                target:SetBypassRagdoll(true)
            end
            
        end
        
    end
    
end

function Railgun:ProcessMoveOnWeapon(player, input)

    if self.railgunAttacking then
    
        if (Shared.GetTime() - self.timeChargeStarted) >= kChargeForceShootTime then
            self.railgunAttacking = false
        end
        
    end
    
end

function Railgun:OnUpdateRender()

    PROFILE("Railgun:OnUpdateRender")
    
    local chargeAmount = self:GetChargeAmount()
    local parent = self:GetParent()
    if parent and parent:GetIsLocalPlayer() then
    
        local viewModel = parent:GetViewModelEntity()
        if viewModel and viewModel:GetRenderModel() then
        
            viewModel:InstanceMaterials()
            local renderModel = viewModel:GetRenderModel()
            renderModel:SetMaterialParameter("chargeAmount" .. self:GetExoWeaponSlotName(), chargeAmount)
            renderModel:SetMaterialParameter("timeSinceLastShot" .. self:GetExoWeaponSlotName(), Shared.GetTime() - self.timeOfLastShot)
            
        end
        
        local chargeDisplayUI = self.chargeDisplayUI
        if not chargeDisplayUI then
        
            chargeDisplayUI = Client.CreateGUIView(246, 256)
            chargeDisplayUI:Load("lua/GUI" .. self:GetExoWeaponSlotName():gsub("^%l", string.upper) .. "RailgunDisplay.lua")
            chargeDisplayUI:SetTargetTexture("*exo_railgun_" .. self:GetExoWeaponSlotName())
            self.chargeDisplayUI = chargeDisplayUI
            
        end
        
        chargeDisplayUI:SetGlobal("chargeAmount" .. self:GetExoWeaponSlotName(), chargeAmount)
        chargeDisplayUI:SetGlobal("timeSinceLastShot" .. self:GetExoWeaponSlotName(), Shared.GetTime() - self.timeOfLastShot)
        
    else
    
        if self.chargeDisplayUI then
        
            Client.DestroyGUIView(self.chargeDisplayUI)
            self.chargeDisplayUI = nil
            
        end
        
    end
    
    if self.chargeSound then
    
        local playing = self.chargeSound:GetIsPlaying()
        if not playing and chargeAmount > 0 then
            self.chargeSound:Start()
        elseif playing and chargeAmount <= 0 then
            self.chargeSound:Stop()
        end
        
        self.chargeSound:SetParameter("charge", chargeAmount, 1)
        
    end
    
end

function Railgun:OnTag(tagName)

    PROFILE("Railgun:OnTag")
    
    if self:GetIsLeftSlot() then
    
        if tagName == "l_shoot" then
            Shoot(self, true)
        elseif tagName == "l_shoot_end" then
            self.lockCharging = false
        end
        
    elseif not self:GetIsLeftSlot() then
    
        if tagName == "r_shoot" then
            Shoot(self, false)
        elseif tagName == "r_shoot_end" then
            self.lockCharging = false
        end
        
    end
    
end

function Railgun:OnUpdateAnimationInput(modelMixin)

    local activity = "none"
    if self.railgunAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity_" .. self:GetExoWeaponSlotName(), activity)
    
end

function Railgun:UpdateViewModelPoseParameters(viewModel)

    local chargeParam = "charge_" .. (self:GetIsLeftSlot() and "l" or "r")
    local chargeAmount = self:GetChargeAmount()
    viewModel:SetPoseParam(chargeParam, chargeAmount)
    
end

if Client then

    local kRailgunMuzzleEffectRate = 0.5
    local kAttachPoints = { [ExoWeaponHolder.kSlotNames.Left] = "fxnode_l_railgun_muzzle", [ExoWeaponHolder.kSlotNames.Right] = "fxnode_r_railgun_muzzle" }
    local kMuzzleEffectName = PrecacheAsset("cinematics/marine/railgun/muzzle_flash.cinematic")
    
    function Railgun:GetIsActive()
        return true
    end
    
    function Railgun:GetPrimaryEffectRate()
        return kRailgunMuzzleEffectRate
    end
    
    function Railgun:GetPrimaryAttacking()
        return (Shared.GetTime() - self.timeOfLastShot) <= kRailgunMuzzleEffectRate
    end
    
    function Railgun:GetSecondaryAttacking()
        return false
    end
    
    function Railgun:OnClientPrimaryAttacking()
    
        local parent = self:GetParent()
        
        if parent then
            CreateMuzzleCinematic(self, kMuzzleEffectName, kMuzzleEffectName, kAttachPoints[self:GetExoWeaponSlot()] , parent)
        end
        
    end
    
    function Railgun:OnProcessMove(input)
    
        Entity.OnProcessMove(self, input)
        
        local player = self:GetParent()
        
        if player then
    
            // trace and highlight first target
            local filter = EntityFilterAllButMixin("RailgunTarget")
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * kRailgunRange
            local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAllButIsa("Tunnel"))
            local direction = (endPoint - startPoint):GetUnit()
            
            self.railgunTargetId = nil
            
            if trace.fraction < 1 then

                for i = 1, 20 do
                
                    local capsuleTrace = Shared.TraceBox(kRailgunBulletExtents, startPoint, trace.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
                    if capsuleTrace.entity then
                    
                        capsuleTrace.entity:SetRailgunTarget()
                        self.railgunTargetId = capsuleTrace.entity:GetId()
                        break
                        
                    end    
                
                end
            
            end
        
        end
    
    end
    
    function Railgun:GetTargetId()
        return self.railgunTargetId
    end
    
end

Shared.LinkClassToMap("Railgun", Railgun.kMapName, networkVars)