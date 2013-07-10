// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\PoisonDart.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SporesMixin.lua")

class 'PoisonDart' (Ability)

PoisonDart.kMapName = "poisondart"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")

local kSpread = Math.Radians(1)
local kZoomedFov = 40
local kFOVPerSecond = 30
local kZoomVelocity = 2

PoisonDart.networkVars =
{
    firingPrimary = "boolean",
    lastPrimaryAttackTime = "time",
    zooming = "boolean",
    timeZoomStateChanged = "time"
}

PrepareClassForMixin(PoisonDart, SporesMixin)

function PoisonDart:OnCreate()

    Ability.OnCreate(self)
    
    self.firingPrimary = false
    self.lastPrimaryAttackTime = 0
    self.zooming = false
    self.timeZoomStateChanged = 0
    
    InitMixin(self, SporesMixin)
    
end

function PoisonDart:GetAnimationGraphName()
    return kAnimationGraph
end

function PoisonDart:GetEnergyCost(player)
    return kDartEnergyCost
end

function PoisonDart:GetIconOffsetY(secondary)
    return kAbilityOffset.PoisonDart
end

function PoisonDart:GetPrimaryAttackRequiresPress()
    return true
end

function PoisonDart:GetDeathIconIndex()
    return kDeathMessageIcon.PoisonDart
end

function PoisonDart:GetHUDSlot()
    return 3
end

local function FireDart(self)

    local player = self:GetParent()
    
    if player then
    
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        
        local startPoint = player:GetEyePos()
            
        // Filter ourself out of the trace so that we don't hit ourselves.
        local filter = EntityFilterTwo(player, self)
           
        if Client then
            DbgTracer.MarkClientFire(player, startPoint)
        end
        
        // Calculate spread for each shot, in case they differ    
        local randomAngle  = NetworkRandom() * math.pi * 2
        local randomRadius = NetworkRandom() * NetworkRandom() * math.tan(kSpread)
        local spreadDirection = (viewCoords.xAxis * math.cos(randomAngle) + viewCoords.yAxis * math.sin(randomAngle))
        local fireDirection = viewCoords.zAxis + spreadDirection * randomRadius
        fireDirection:Normalize()
       
        local endPoint = startPoint + fireDirection * 10000     
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        
        if Server then
            Server.dbgTracer:TraceBullet(player, startPoint, trace)  
        end
        
        if trace.fraction < 1 and trace.entity then
        
            if Server and HasMixin(trace.entity, "Live") then
            
                local direction = (trace.endPoint - startPoint):GetUnit()
                local prevHealthScalar = trace.entity:GetHealthScalar()
                self:DoDamage(kPoisonDartDirectDamage, trace.entity, trace.endPoint, direction)
                
                if prevHealthScalar ~= trace.entity:GetHealthScalar() then
                
                    local dotMarker = CreateEntity(DotMarker.kMapName, trace.entity:GetOrigin(), self:GetTeamNumber())
                    dotMarker:SetDamageType(kPoisonDartDamageType)
                    dotMarker:SetLifeTime(kPoisonDartMaxLifeTime)
                    dotMarker:SetDamage(kPoisonDartDamage)
                    dotMarker:SetRadius(0)
                    dotMarker:SetDamageIntervall(0.3)
                    dotMarker:SetDotMarkerType(DotMarker.kType.SingleTarget)
                    dotMarker:SetTargetEffectName("poison_dart_trail")
                    dotMarker:SetDeathIconIndex(kDeathMessageIcon.PoisonDart)
                    dotMarker:SetOwner(self:GetParent())
                    dotMarker:SetAttachToTarget(trace.entity, trace.endPoint)
                    
                    dotMarker:SetDestroyCondition(                
                        function (self, target)
                            return target:GetHealthScalar() >= 1 or not target:GetIsAlive()
                        end                 
                    )
                
                end
                
            end
                
        end
        
        // Play hit effects on ground, on target or in the air if it missed
        local impactPoint = trace.endPoint
        local surfaceName = trace.surface
        local tableparams = {}
        tableparams[kEffectFilterSilenceUpgrade] = GetHasSilenceUpgrade(player)
        
    end
    
end

function PoisonDart:OnPrimaryAttack(player)
    
    if not player:GetPrimaryAttackLastFrame() and (Shared.GetTime() - self.lastPrimaryAttackTime) > kDartFireDelay then
    
        if player:GetEnergy() >= self:GetEnergyCost(player) then
            self:PerformPrimaryAttack(player)
        end

    end
    
end

function PoisonDart:PerformPrimaryAttack(player)
    
    self.firingPrimary = true
    
end

function PoisonDart:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.firingPrimary = false

end

function PoisonDart:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    local player = self:GetParent()
    
    // Player may be nil when the spikes are first created.
    if player ~= nil then
        tableParams[kEffectFilterFrom] = player:GetHasUpgrade(kTechId.Piercing)
    end
    
end

function PoisonDart:OnTag(tagName)

    if self.firingPrimary then 

        if tagName == "start" then
    
            FireDart(self)
            
            self:GetParent():DeductAbilityEnergy(self:GetEnergyCost())
            self:TriggerEffects("spikes_alt_attack")
            self.lastPrimaryAttackTime = Shared.GetTime()
            
        elseif tagName == "end" then
            self.firingPrimary = false
        end    
        
    end

end

function PoisonDart:OnUpdateAnimationInput(modelMixin)

    PROFILE("PoisonDart:OnUpdateAnimationInput")

    if not self:GetIsSecondaryBlocking() then
        
        local activityString = "none"
        if self.firingPrimary then
            activityString = "secondary"
        end
        
        if self.firingPrimary or self.lastSecondaryAttackStartTime + 3 < Shared.GetTime() then
            modelMixin:SetAnimationInput("ability", "spikes")
        end    
        
        modelMixin:SetAnimationInput("activity", activityString)
    
    end
    
end

local function UpdateZoomMode(self, player)

    if not self.timeLastZoomCheck or self.timeLastZoomCheck + 0.1 < Shared.GetTime() then
    
        local newZoomState = player:GetVelocity():GetLength() < kZoomVelocity
        
        if self.zooming ~= newZoomState then
            self.zooming = newZoomState
            self.timeZoomStateChanged = Shared.GetTime()
        end
        
        self.timeLastZoomCheck = Shared.GetTime()
    
    end

end

function PoisonDart:ProcessMoveOnWeapon(player, input)

    UpdateZoomMode(self, player)
    
    local timeScalar = Clamp( (Shared.GetTime() - self.timeZoomStateChanged) / 0.2, 0, 1)

    if self.zooming then
        player:SetFov(kLerkFov + timeScalar * (kZoomedFov - kLerkFov))
    else
        player:SetFov(kZoomedFov + timeScalar * (kLerkFov - kZoomedFov))        
    end

end

function PoisonDart:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.zooming = false

end

function PoisonDart:OnHolster(player)

    Ability.OnDraw(self, player)

    self.zooming = false
    if player then    
        player:SetFov(kLerkFov)    
    end

end

Shared.LinkClassToMap("PoisonDart", PoisonDart.kMapName, PoisonDart.networkVars)