// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Drifter.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable glowing insect that the alien commander can control.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/AttackOrderMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Drifter' (ScriptActor)

Drifter.kMapName = "drifter"

Drifter.kModelName = PrecacheAsset("models/alien/drifter/drifter.model")
Drifter.kAnimationGraph = PrecacheAsset("models/alien/drifter/drifter.animation_graph")

Drifter.kOrdered2DSoundName = PrecacheAsset("sound/NS2.fev/alien/drifter/ordered_2d")
Drifter.kOrdered3DSoundName = PrecacheAsset("sound/NS2.fev/alien/drifter/ordered")

local kDrifterMorphing = PrecacheAsset("sound/NS2.fev/alien/commander/drop_structure")

Drifter.kMoveSpeed = 7
Drifter.kHealth = kDrifterHealth
Drifter.kArmor = kDrifterArmor
            
Drifter.kCapsuleHeight = .05
Drifter.kCapsuleRadius = .5
Drifter.kStartDistance = 5
Drifter.kHoverHeight = 1.2

Drifter.kEnzymeRange = 22

Drifter.kFov = 360

Drifter.kTurnSpeed = 8 * math.pi

// Control detection of drifters from enemy team units.
local kDetectInterval = 0.5
local kDetectRange = 1.5

local kTrailCinematicNames =
{
    PrecacheAsset("cinematics/alien/drifter/trail1.cinematic"),
    PrecacheAsset("cinematics/alien/drifter/trail2.cinematic"),
    PrecacheAsset("cinematics/alien/drifter/trail3.cinematic"),
}

local kTrailFadeOutCinematicNames =
{
    PrecacheAsset("cinematics/alien/drifter/trail_fadeout.cinematic"),
}

local networkVars =
{
    // 0-1 scalar used to set move_speed model parameter according to how fast we recently moved
    moveSpeed = "float",
    moveSpeedParam = "compensated float",
    camouflaged = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(AttackOrderMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Drifter:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, FireMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, AttackOrderMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, CombatMixin)
    
    self:SetUpdates(true)
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
    if Client then
        InitMixin(self, UnitStatusMixin)
    end
    
end

function Drifter:OnInitialized()

    self.moveSpeed = 0
    self.moveSpeedParam = 0
    self.moveYaw = 0
    
    self:SetModel(Drifter.kModelName, Drifter.kAnimationGraph)
    
    ScriptActor.OnInitialized(self)
    
    if Server then
    
        self:SetUpdates(true)
        self:UpdateIncludeRelevancyMask()
        
        InitMixin(self, RepositioningMixin)
        InitMixin(self, SleeperMixin)
        InitMixin(self, MobileTargetMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        self.trailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)
        self.trailCinematic:SetCinematicNames(kTrailCinematicNames)
        self.trailCinematic:SetFadeOutCinematicNames(kTrailFadeOutCinematicNames)
        self.trailCinematic:AttachTo(self, TRAIL_ALIGN_MOVE,  Vector(0, 0.3, -0.9))
        self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.trailCinematic:SetOptions( {
                numSegments = 8,
                collidesWithWorld = false,
                visibilityChangeDuration = 1.2,
                fadeOutCinematics = true,
                stretchTrail = false,
                trailLength = 3.5,
                minHardening = 0.1,
                maxHardening = 0.3,
                hardeningModifier = 0,
                trailWeight = 0.0
            } )
    
    end
    
end

function Drifter:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Client then
    
        if self.trailCinematic then
            Client.DestroyTrailCinematic(self.trailCinematic)
        end    
        
    end
    
end

function Drifter:GetTurnSpeedOverride()
    return Drifter.kTurnSpeed
end

function Drifter:GetCanSleep()
    return self:GetCurrentOrder() == nil
end

function Drifter:GetExtentsOverride()
    return Vector(Drifter.kCapsuleRadius, Drifter.kCapsuleHeight / 2, Drifter.kCapsuleRadius)
end

function Drifter:GetIsFlying()
    return true
end

function Drifter:GetHoverHeight()    
    return Drifter.kHoverHeight
end

function Drifter:GetDeathIconIndex()
    return kDeathMessageIcon.None
end

local function PlayOrderedSounds(self)

    StartSoundEffectOnEntity(Drifter.kOrdered3DSoundName, self)
    
    local owner = self:GetOwner()
    if owner then
        Server.PlayPrivateSound(owner, Drifter.kOrdered2DSoundName, owner, 1.0, Vector(0, 0, 0))
    end
    
end

function Drifter:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if order:GetParam() ~= nil then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // If target is enemy, attack it
    if order:GetType() == kTechId.Default then
    
        if orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetAreEnemies(self, orderTarget) and orderTarget:GetIsAlive() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
            order:SetType(kTechId.Attack)
        else
            order:SetType(kTechId.Move)
        end
        
    end
    
    PlayOrderedSounds(self)
    
end

function Drifter:ResetOrders(resetOrigin, clearOrders)

    if resetOrigin then
    
        if self.oldLocation ~= nil then
            self:SetOrigin(self.oldLocation)
        else
            self:SetOrigin(self:GetOrigin() + Vector(0, self:GetHoverHeight(), 0))
        end
        
    end
    
    self:SetIgnoreOrders(false)
    
    if clearOrders then
        self:ClearOrders()
    end
    
    self.oldLocation = nil
    
end

// for marquee selection
function Drifter:GetIsMoveable()
    return true
end

function Drifter:ProcessMoveOrder(moveSpeed, deltaTime)

    local currentOrder = self:GetCurrentOrder()
    
    if currentOrder ~= nil then
    
        local hoverAdjustedLocation = currentOrder:GetLocation()
        
        if self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, moveSpeed, deltaTime) then
            self:CompletedCurrentOrder()
        end
        
    end
    
end

function Drifter:GetEngagementPointOverride()
    return self:GetOrigin()
end

function Drifter:ProcessEnzymeOrder(moveSpeed, deltaTime)

    local currentOrder = self:GetCurrentOrder()
    
    if currentOrder ~= nil then
    
        local targetPos = currentOrder:GetLocation()
        
        // check if we can reach the destinaiton
        if self:GetIsInEnzymeRange(targetPos) then
        
            self:SpawnEnzymeAt(targetPos)
            self:CompletedCurrentOrder()
            self:TriggerUncloak()
            
        else
        
            // move to target otherwise
            if self:MoveToTarget(PhysicsMask.AIMovement, targetPos, moveSpeed, deltaTime) then
                self:ClearOrders()
            end
            
        end
        
    end
    
end

local function UpdateTasks(self, deltaTime)

    if not self:GetIsAlive() then
        return
    end
    
    local currentOrder = self:GetCurrentOrder()
    if currentOrder ~= nil  then
    
        local drifterMoveSpeed = GetDevScalar(Drifter.kMoveSpeed, 8)
        
        local currentOrigin = Vector(self:GetOrigin())
        
        if currentOrder:GetType() == kTechId.Move then
            self:ProcessMoveOrder(drifterMoveSpeed, deltaTime)
        elseif currentOrder:GetType() == kTechId.EnzymeCloud then
            self:ProcessEnzymeOrder(drifterMoveSpeed, deltaTime)    
        elseif currentOrder:GetType() == kTechId.Attack then
            self:ProcessAttackOrder(5, drifterMoveSpeed, deltaTime)
        end
        
        // Check difference in location to set moveSpeed
        local distanceMoved = (self:GetOrigin() - currentOrigin):GetLength()
        
        self.moveSpeed = (distanceMoved / drifterMoveSpeed) / deltaTime
        
    end
    
end

local function UpdateMoveYaw(self, deltaTime)

    local currentYaw = self:GetAngles().yaw
    
    if not self.lastYaw then
        self.lastYaw = currentYaw
    end
    
    if not self.moveYaw then
        self.moveYaw = 90
    end
    
    if self.lastYaw < currentYaw then
        self.moveYaw = math.max(0, self.moveYaw - 400 * deltaTime)
    elseif self.lastYaw > currentYaw then
        self.moveYaw = math.min(180, self.moveYaw + 400 * deltaTime)
    else
    
        if self.moveYaw < 90 then
            self.moveYaw = math.min(90, self.moveYaw + 200 * deltaTime)
        elseif self.moveYaw > 90 then
            self.moveYaw = math.max(90, self.moveYaw - 200 * deltaTime)   
        end
        
        self.lastYaw = currentYaw
        
    end

end

function Drifter:GetFov()
    return Drifter.kFov
end

function Drifter:GetIsCamouflaged()
    return self.camouflaged
end

function Drifter:OnCapsuleTraceHit(entity)

    if GetAreEnemies(self, entity) then
        self.timeLastCombatAction = Shared.GetTime()
    end 
    
end

function Drifter:OnUpdatePoseParameters()

    PROFILE("Drifter:OnUpdatePoseParameters")
    
    self:SetPoseParam("move_speed", self.moveSpeedParam)
    self:SetPoseParam("move_yaw", 90)
    
end 

local function ScanForNearbyEnemy(self)

    // Check for nearby enemy units. Uncloak if we find any.
    self.lastDetectedTime = self.lastDetectedTime or 0
    if self.lastDetectedTime + kDetectInterval < Shared.GetTime() then
    
        if #GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kDetectRange) > 0 then
        
            self:TriggerUncloak()
            
        end
        self.lastDetectedTime = Shared.GetTime()
        
    end
    
end

function Drifter:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    // Blend smoothly towards target value
    self.moveSpeedParam = Clamp(Slerp(self.moveSpeedParam, self.moveSpeed, deltaTime), 0, 1)
    //UpdateMoveYaw(self, deltaTime)
    
    if Server then
    
        UpdateTasks(self, deltaTime)
        
        ScanForNearbyEnemy(self)
        
        self.camouflaged = not self:GetHasOrder() and not self:GetIsInCombat()
        
    elseif Client then
        self.trailCinematic:SetIsVisible(self:GetIsMoving() and self:GetIsVisible())
    end
    
end

function Drifter:GetCanCloakOverride()
    return not self:GetHasOrder()
end

if Client then

    function Drifter:GetIsMoving()
    
        if self.lastTimeChecked ~= Shared.GetTime() then
        
            if not self.lastPositionClient then
                self.lastPositionClient = self:GetOrigin()
            end
            
            self.movingThisFrame = (self:GetOrigin() - self.lastPositionClient):GetLength() ~= 0
            
            self.lastTimeChecked = Shared.GetTime()
            self.lastPositionClient = self:GetOrigin()
            
        end
        
        return self.movingThisFrame
        
    end
    
end

function Drifter:GetTechButtons(techId)

    if techId == kTechId.RootMenu then
        return { kTechId.Attack, kTechId.Stop, kTechId.DrifterCamouflage, kTechId.None,
                 kTechId.EnzymeCloud }
    end
    
    return nil
    
end

function Drifter:GetActivationTechAllowed(techId)
    return true
end

function Drifter:SpawnEnzymeAt(position)

    local team = self:GetTeam()
    local cost = GetCostForTech(kTechId.EnzymeCloud)
    
    if cost <= team:GetTeamResources() then

        self:TriggerEffects("drifter_shoot_enzyme", {effecthostcoords = Coords.GetLookIn(self:GetOrigin(), GetNormalizedVectorXZ( position - self:GetOrigin())) } )
        local enzymeCloud = CreateEntity(EnzymeCloud.kMapName, position, self:GetTeamNumber())
        team:AddTeamResources(-cost)
    
    end

end

function Drifter:GetDamagedAlertId()
    return kTechId.AlienAlertLifeformUnderAttack
end

function Drifter:GetIsInEnzymeRange(targetPos)

    PROFILE("Drifter:GetIsInEnzymeRange")
    
    local origin = self:GetOrigin()
    
    if (targetPos - origin):GetLength() < Drifter.kEnzymeRange then
    
        local trace = Shared.TraceRay(origin, targetPos, CollisionRep.LOS, PhysicsMask.Bullets, EntityFilterAll())            
        return trace.fraction == 1
    
    end
    
    return false

end

function Drifter:OverrideVisionRadius()
    return kPlayerLOSDistance
end

function Drifter:PerformActivation(techId, position, normal, commander)

    local success = false
    local keepProcessing = true
    
    if techId == kTechId.EnzymeCloud then
    
        local team = self:GetTeam()
        local cost = GetCostForTech(kTechId.EnzymeCloud)
        if cost <= team:GetTeamResources() then
        
            self:GiveOrder(techId, nil, position + Vector(0, 0.2, 0), nil, true, true)
            // Only 1 Drifter will process this activation.
            keepProcessing = false
            
        end
        
        // return false, team res will be drained once we reached the destination and created the enzyme entity
        success = false
        
    else
        return ScriptActor.PerformActivation(self, techId, position, normal, commander)
    end
    
    return success, keepProcessing
    
end

function Drifter:GetMeleeAttackDamage()
    return kDrifterAttackDamage
end

function Drifter:GetMeleeAttackInterval()
    return kDrifterAttackFireDelay
end

function Drifter:GetMeleeAttackOrigin()
    return self:GetOrigin()
end

function Drifter:OnOverrideDoorInteraction(inEntity)
    return true, 4
end

function Drifter:UpdateIncludeRelevancyMask()
    SetAlwaysRelevantToCommander(self, true)
end

function Drifter:OnDestroyCurrentOrder(order)

    
    
end

local function GetOrderMovesDrifter(orderType)

    return orderType == kTechId.Move or
           orderType == kTechId.Attack or
           orderType == kTechId.Construct or
           orderType == kTechId.Weld

end

function Drifter:OnUpdateAnimationInput(modelMixin)

    PROFILE("Drifter:OnUpdateAnimationInput")
    
    local move = "idle"
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if GetOrderMovesDrifter(currentOrder:GetType()) then
            move = "run"
        end
        
    end
    modelMixin:SetAnimationInput("move",  move)
    
    local activity = "none"
    if Shared.GetTime() - self:GetTimeOfLastAttackOrder() < 0.5 then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity", activity)
    
end

if Server then

    function Drifter:GetCanReposition()
        return true
    end
    
    function Drifter:OverrideRepositioningSpeed()
        return Drifter.kMoveSpeed * 0.3
    end    
    
    function Drifter:OverrideRepositioningDistance()
        return 0.8
    end    
    
    function Drifter:OverrideGetRepositioningTime()
        return 0.5
    end
    
end

function Drifter:GetShowHitIndicator()
    return false
end

function Drifter:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

Shared.LinkClassToMap("Drifter", Drifter.kMapName, networkVars, true)