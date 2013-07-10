// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MAC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable flying robot marine commander can control. Used to build structures
// and has other special abilities. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/Marine/EMPBlast.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/AttackOrderMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CorrodeMixin.lua")

class 'MAC' (ScriptActor)

MAC.kMapName = "mac"

MAC.kModelName = PrecacheAsset("models/marine/mac/mac.model")
MAC.kAnimationGraph = PrecacheAsset("models/marine/mac/mac.animation_graph")

MAC.kConfirmSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/confirm")
MAC.kConfirm2DSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/confirm_2d")
MAC.kStartConstructionSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/constructing")
MAC.kStartConstruction2DSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/constructing_2d")
MAC.kStartWeldSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/weld_start")
MAC.kHelpingSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/help_build")
MAC.kPassbyMACSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/passby_mac")
MAC.kPassbyDrifterSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/passby_driffter")

MAC.kUsedSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/use")

// Animations
MAC.kAnimAttack = "attack"

local kJetsCinematic = PrecacheAsset("cinematics/marine/mac/jet.cinematic")
local kJetsSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/thrusters")

local kRightJetNode = "fxnode_jet1"
local kLeftJetNode = "fxnode_jet2"
MAC.kLightNode = "fxnode_light"
MAC.kWelderNode = "fxnode_welder"

// Balance
local kConstructRate = 0.4
local kWeldRate = 0.5
local kOrderScanRadius = 10
MAC.kRepairHealthPerSecond = 50
MAC.kHealth = kMACHealth
MAC.kArmor = kMACArmor
MAC.kMoveSpeed = 4.5
MAC.kHoverHeight = .5
MAC.kStartDistance = 3
MAC.kWeldDistance = 2
MAC.kBuildDistance = 2     // Distance at which bot can start building a structure. 
MAC.kSpeedUpgradePercent = (1 + kMACSpeedAmount)

MAC.kCapsuleHeight = .2
MAC.kCapsuleRadius = .5

// Greetings
MAC.kGreetingUpdateInterval = 1
MAC.kGreetingInterval = 10
MAC.kGreetingDistance = 5
MAC.kUseTime = 2.0

MAC.kTurnSpeed = 3 * math.pi // a mac is nimble
local networkVars =
{
    welding = "boolean",
    constructing = "boolean",
    moving = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(AttackOrderMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)

function MAC:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, BuildingMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, AttackOrderMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, CorrodeMixin)
    
    if Server then
    
        InitMixin(self, RepositioningMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetUpdates(true)
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
end

function MAC:OnInitialized()
    
    ScriptActor.OnInitialized(self)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    if Server then
    
        self:UpdateIncludeRelevancyMask()
        
        InitMixin(self, SleeperMixin)
        InitMixin(self, MobileTargetMixin)
        
        self.jetsSound = Server.CreateEntity(SoundEffect.kMapName)
        self.jetsSound:SetAsset(kJetsSound)
        self.jetsSound:SetParent(self)

    elseif Client then
        InitMixin(self, UnitStatusMixin)      

        // Setup movement effects
        self.jetsCinematics = {}
        for index,attachPoint in ipairs({ kLeftJetNode, kRightJetNode }) do
            self.jetsCinematics[index] = Client.CreateCinematic(RenderScene.Zone_Default)
            self.jetsCinematics[index]:SetCinematic(kJetsCinematic)
            self.jetsCinematics[index]:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.jetsCinematics[index]:SetParent(self)
            self.jetsCinematics[index]:SetCoords(Coords.GetIdentity())
            self.jetsCinematics[index]:SetAttachPoint(self:GetAttachPointIndex(attachPoint))
            self.jetsCinematics[index]:SetIsActive(false)
        end

    end
    
    self.timeOfLastGreeting = 0
    self.timeOfLastGreetingCheck = 0
    self.timeOfLastChatterSound = 0
    self.timeOfLastWeld = 0
    self.timeOfLastConstruct = 0
    self.moving = false
    
    self:SetModel(MAC.kModelName, MAC.kAnimationGraph)
    
end

function MAC:OnEntityChange(oldId)

    if oldId == self.secondaryTargetId then
        self.secondaryOrderType = nil
        self.secondaryTargetId = nil
    end

end

local function GetAutomaticOrder(self)

    local target = nil
    local orderType = nil

    if self.timeOfLastFindSomethingTime == nil or Shared.GetTime() > self.timeOfLastFindSomethingTime + 1 then

        local currentOrder = self:GetCurrentOrder()
        local primaryTarget = nil
        if currentOrder and currentOrder:GetType() == kTechId.FollowAndWeld then
            primaryTarget = Shared.GetEntity(currentOrder:GetParam())
        end

        if primaryTarget and (HasMixin(primaryTarget, "Weldable") and primaryTarget:GetWeldPercentage() < 0.95) then
            
            target = primaryTarget
            orderType = kTechId.Weld
                    
        else

            // If there's a friendly entity nearby that needs constructing, constuct it.
            local constructables = GetEntitiesWithMixinForTeamWithinRange("Construct", self:GetTeamNumber(), self:GetOrigin(), kOrderScanRadius)
            for c = 1, #constructables do
            
                local constructable = constructables[c]
                if constructable:GetCanConstruct(self) then
                
                    target = constructable
                    orderType = kTechId.Construct
                    break
                    
                end
                
            end
            
            if not target then
            
                // Look for entities to heal with weld.
                local weldables = GetEntitiesWithMixinForTeamWithinRange("Weldable", self:GetTeamNumber(), self:GetOrigin(), kOrderScanRadius)
                for w = 1, #weldables do
                
                    local weldable = weldables[w]
                    // There are cases where the weldable's weld percentage is very close to
                    // 100% but not exactly 100%. This second check prevents the MAC from being so pedantic.
                    if weldable:GetCanBeWelded(self) and weldable:GetWeldPercentage() < 0.95 then
                    
                        target = weldable
                        orderType = kTechId.Weld
                        break

                    end
                    
                end
            
            end
        
        end

        self.timeOfLastFindSomethingTime = Shared.GetTime()

    end
    
    return target, orderType

end

function MAC:GetTurnSpeedOverride()
    return MAC.kTurnSpeed
end

function MAC:GetCanSleep()
    return self:GetCurrentOrder() == nil
end

function MAC:GetMinimumAwakeTime()
    return 5
end

function MAC:GetExtentsOverride()
    return Vector(MAC.kCapsuleRadius, MAC.kCapsuleHeight / 2, MAC.kCapsuleRadius)
end

function MAC:GetFov()
    return 120
end

function MAC:GetIsFlying()
    return true
end

function MAC:GetReceivesStructuralDamage()
    return true
end

function MAC:OnUse(player, elapsedTime, useSuccessTable)

    // Play flavor sounds when using MAC.
    if Server then
    
        local time = Shared.GetTime()
        
        if self.timeOfLastUse == nil or (time > (self.timeOfLastUse + MAC.kUseTime)) then
        
            Server.PlayPrivateSound(player, MAC.kUsedSoundName, self, 1.0, Vector(0, 0, 0))
            self.timeOfLastUse = time
            
        end
        
    end
    
end

function MAC:GetHoverHeight()
    return MAC.kHoverHeight
end

function MAC:OnOverrideOrder(order)

    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    local isSelfOrder = orderTarget == self
    
    // Default orders to unbuilt friendly structures should be construct orders
    if order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber()) and not isSelfOrder then
    
        order:SetType(kTechId.Construct)

    elseif order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber()) and not isSelfOrder then
    
        order:SetType(kTechId.FollowAndWeld)
        
    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
    
        order:SetType(kTechId.Attack)

    elseif (order:GetType() == kTechId.Default or order:GetType() == kTechId.Move) and (order:GetParam() ~= nil) then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.Move)
        
    end
    
end

function MAC:GetIsOrderHelpingOtherMAC(order)

    if order:GetType() == kTechId.Construct then
    
        // Look for friendly nearby MACs
        local macs = GetEntitiesForTeamWithinRange("MAC", self:GetTeamNumber(), self:GetOrigin(), 3)
        for index, mac in ipairs(macs) do
        
            if mac ~= self then
            
                local otherMacOrder = mac:GetCurrentOrder()
                if otherMacOrder ~= nil and otherMacOrder:GetType() == order:GetType() and otherMacOrder:GetParam() == order:GetParam() then
                    return true
                end
                
            end
            
        end
        
    end
    
    return false
    
end

function MAC:OnOrderChanged()

    local order = self:GetCurrentOrder()    
    if order then
    
        local owner = self:GetOwner()
        
        if not owner then
            local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
            if commanders and commanders[1] then
                owner = commanders[1]
            end    
        end

        // Look for nearby MAC doing the same thing
        if self:GetIsOrderHelpingOtherMAC(order) then
            self:PlayChatSound(MAC.kHelpingSoundName)            
        elseif order:GetType() == kTechId.Construct then
        
            self:PlayChatSound(MAC.kStartConstructionSoundName)
            
            if owner then
                Server.PlayPrivateSound(owner, MAC.kStartConstruction2DSoundName, owner, 1.0, Vector(0, 0, 0))
            end
            
        elseif order:GetType() == kTechId.Weld then 
       
            self:PlayChatSound(MAC.kStartWeldSound) 

            if owner then
                Server.PlayPrivateSound(owner, MAC.kStartWeldSound, owner, 1.0, Vector(0, 0, 0))
            end
           
        else
        
            self:PlayChatSound(MAC.kConfirmSoundName)
            
            if owner then
                Server.PlayPrivateSound(owner, MAC.kConfirm2DSoundName, owner, 1.0, Vector(0, 0, 0))
            end
            
        end

    end

end

function MAC:OnDestroyCurrentOrder(currentOrder)
    
    local orderTarget = nil
    if currentOrder:GetParam() ~= nil then
        orderTarget = Shared.GetEntity(currentOrder:GetParam())
    end
    
    if currentOrder:GetType() == kTechId.Weld and GetOrderTargetIsWeldTarget(currentOrder, self:GetTeamNumber()) and orderTarget.OnWeldCanceled then
        orderTarget:OnWeldCanceled(self)
    end

end

function MAC:GetMoveSpeed()

    local moveSpeed = GetDevScalar(MAC.kMoveSpeed, 8)
    local techNode = self:GetTeam():GetTechTree():GetTechNode(kTechId.MACSpeedTech)

    if techNode and techNode:GetResearched() then
        moveSpeed = moveSpeed * MAC.kSpeedUpgradePercent
    end

    return moveSpeed
    
end

function MAC:ProcessWeldOrder(deltaTime, orderTarget, orderLocation)

    local time = Shared.GetTime()
    local canBeWeldedNow = false
    local orderStatus = kOrderStatus.InProgress

    if self.timeOfLastWeld == 0 or time > self.timeOfLastWeld + kWeldRate then
    
        // Not allowed to weld after taking damage recently.
        if Shared.GetTime() - self:GetTimeLastDamageTaken() <= 1.0 then
        
            TEST_EVENT("MAC cannot weld after taking damage")
            return kOrderStatus.InProgress
            
        end
    
        // It is possible for the target to not be weldable at this point.
        // This can happen if a damaged Marine becomes Commander for example.
        // The Commander is not Weldable but the Order correctly updated to the
        // new entity Id of the Commander. In this case, the order will simply be completed.
        if orderTarget and HasMixin(orderTarget, "Weldable") then

            local toTarget = (orderLocation - Vector(self:GetOrigin()))
            local distanceToTarget = toTarget:GetLength()
            canBeWeldedNow = orderTarget:GetCanBeWelded(self)
            
            local obstacleSize = 0
            if HasMixin(orderTarget, "Extents") then
                obstacleSize = orderTarget:GetExtents():GetLengthXZ()
            end
            
            if not canBeWeldedNow then
                orderStatus = kOrderStatus.Completed
            else
            
                // If we're close enough to weld, weld
                if distanceToTarget - obstacleSize < MAC.kWeldDistance and not GetIsVortexed(self) then
 
                    orderTarget:OnWeld(self, kWeldRate)
                    self.timeOfLastWeld = time
                    self.moving = false
                    
                else
                
                    // otherwise move towards it
                    local hoverAdjustedLocation = GetHoverAt(self, orderTarget:GetOrigin())
                    local doneMoving = self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
                    self.moving = not doneMoving
                    
                end
                
            end    
            
        else
            orderStatus = kOrderStatus.Cancelled
        end
        
    end
    
    // Continuously turn towards the target. But don't mess with path finding movement if it was done.
    if not self.moving and orderPosition then
        local toOrder = (orderPosition - Vector(self:GetOrigin()))
        self:SmoothTurn(deltaTime, GetNormalizedVector(toOrder), 0)
    end
    
    return orderStatus
    
end

function MAC:ProcessMove(deltaTime, target, targetPosition)

    local hoverAdjustedLocation = GetHoverAt(self, targetPosition)
    local orderStatus = kOrderStatus.None

    if self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime) then

        orderStatus = kOrderStatus.Completed
        self.moving = false

    else
        orderStatus = kOrderStatus.InProgress
        self.moving = true
    end
    
    return orderStatus
    
end

function MAC:PlayChatSound(soundName)

    if self.timeOfLastChatterSound == 0 or (Shared.GetTime() > self.timeOfLastChatterSound + 2) then
        self:PlaySound(soundName)
        self.timeOfLastChatterSound = Shared.GetTime()
    end
    
end

// Look for other MACs and Drifters to greet as we fly by 
function MAC:UpdateGreetings()

    local time = Shared.GetTime()
    if self.timeOfLastGreetingCheck == 0 or (time > (self.timeOfLastGreetingCheck + MAC.kGreetingUpdateInterval)) then
    
        if self.timeOfLastGreeting == 0 or (time > (self.timeOfLastGreeting + MAC.kGreetingInterval)) then
        
            local ents = GetEntitiesMatchAnyTypes({"MAC", "Drifter"})
            for index, ent in ipairs(ents) do
            
                if (ent ~= self) and (self:GetOrigin() - ent:GetOrigin()):GetLength() < MAC.kGreetingDistance then
                
                    if GetCanSeeEntity(self, ent) then
                        if ent:isa("MAC") then
                            self:PlayChatSound(MAC.kPassbyMACSoundName)
                        elseif ent:isa("Drifter") then
                            self:PlayChatSound(MAC.kPassbyDrifterSoundName)
                        end
                        
                        self.timeOfLastGreeting = time
                        break
                        
                    end
                    
                end                    
                    
            end                
                            
        end
        
        self.timeOfLastGreetingCheck = time
        
    end

end

function MAC:GetCanBeWeldedOverride()
    return self.lastTakenDamageTime + 1 < Shared.GetTime()
end

function MAC:GetEngagementPointOverride()
    return self:GetOrigin()
end

local function GetCanConstructTarget(self, target)
    return target ~= nil and HasMixin(target, "Construct") and GetAreFriends(self, target)
end

function MAC:ProcessConstruct(deltaTime, orderTarget, orderLocation)

    local time = Shared.GetTime()
    
    local toTarget = (orderLocation - self:GetOrigin())
    local distToTarget = toTarget:GetLengthXZ()
    local orderStatus = kOrderStatus.InProgress
    local canConstructTarget = GetCanConstructTarget(self, orderTarget)   
    
    if self.timeOfLastConstruct == 0 or (time > (self.timeOfLastConstruct + kConstructRate)) then

        if canConstructTarget then
        
            local engagementDist = GetEngagementDistance(orderTarget:GetId()) 
            if distToTarget < engagementDist then
        
                if orderTarget:GetIsBuilt() then   
                    orderStatus = kOrderStatus.Completed
                else
            
                    // Otherwise, add build time to structure
                    if not self:GetIsVortexed() and not GetIsVortexed(orderTarget) then
                        orderTarget:Construct(kConstructRate * kMACConstructEfficacy, self)
                        self.timeOfLastConstruct = time
                    end
                
                end
                
            else
            
                local hoverAdjustedLocation = GetHoverAt(self, orderLocation)
                local doneMoving = self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
                self.moving = not doneMoving

            end    
        
        
        else
            orderStatus = kOrderStatus.Cancelled
        end

        
    end
    
    // Continuously turn towards the target. But don't mess with path finding movement if it was done.
    if not self.moving and toTarget then
        self:SmoothTurn(deltaTime, GetNormalizedVector(toTarget), 0)
    end
    
    return orderStatus
    
end

local function FindSomethingToDo(self)

    local target, orderType = GetAutomaticOrder(self)
    if target and orderType then
        return self:GiveOrder(orderType, target:GetId(), target:GetOrigin(), nil, false, false) ~= kTechId.None    
    end
    
    return false
    
end

// for marquee selection
function MAC:GetIsMoveable()
    return true
end

function MAC:ProcessFollowAndWeldOrder(deltaTime, orderTarget, targetPosition)

    local currentOrder = self:GetCurrentOrder()
    local orderStatus = kOrderStatus.InProgress
    
    if orderTarget and orderTarget:GetIsAlive() then
        
        local distance = (self:GetOrigin() - targetPosition):GetLengthXZ()
        local target, orderType = GetAutomaticOrder(self)
        
        if target and orderType then
        
            self.secondaryOrderType = orderType
            self.secondaryTargetId = target:GetId()
            
        end
        
        target = target ~= nil and target or ( self.secondaryTargetId ~= nil and Shared.GetEntity(self.secondaryTargetId) )
        orderType = orderType ~= nil and orderType or self. secondaryOrderType
        
        local triggerMoveDistance = (self.welding or self.constructing or orderType) and 15 or 6
        
        if distance > triggerMoveDistance or self.moveToPrimary then
        
            if self:ProcessMove(deltaTime, target, targetPosition) == kOrderStatus.InProgress and (self:GetOrigin() - targetPosition):GetLengthXZ() > 3 then
                self.moveToPrimary = true
                self.secondaryTarget = nil
                self.secondaryOrderType = nil
            else
                self.moveToPrimary = false
            end
            
        else
            self.moving = false
        end
        
        // when we attempt to follow the primary target, dont interrupt with auto orders
        if not self.moveToPrimary then
        
            if target and orderType then
            
                local secondaryOrderStatus = nil
            
                if orderType == kTechId.Weld then            
                    secondaryOrderStatus = self:ProcessWeldOrder(deltaTime, target, target:GetOrigin())        
                elseif orderType == kTechId.Construct then
                    secondaryOrderStatus = self:ProcessConstruct(deltaTime, target, target:GetOrigin())
                end
                
                if secondaryOrderStatus == kOrderStatus.Completed or secondaryOrderStatus == kOrderStatus.Cancelled then
                
                    self.secondaryTarget = nil
                    self.secondaryOrderType = nil
                    
                end
            
            end
        
        end
        
    else
        self.moveToPrimary = false
        orderStatus = kOrderStatus.Cancelled
    end
    
    return orderStatus

end

local function UpdateOrders(self, deltaTime)

    local currentOrder = self:GetCurrentOrder()
    if currentOrder ~= nil then
    
        local orderStatus = kOrderStatus.None        
        local orderTarget = Shared.GetEntity(currentOrder:GetParam())
        local orderLocation = currentOrder:GetLocation()
    
        if currentOrder:GetType() == kTechId.FollowAndWeld then
            orderStatus = self:ProcessFollowAndWeldOrder(deltaTime, orderTarget, orderLocation)    
        elseif currentOrder:GetType() == kTechId.Move then
        
            orderStatus = self:ProcessMove(deltaTime, orderTarget, orderLocation)
            self:UpdateGreetings()
            
        elseif currentOrder:GetType() == kTechId.Attack then
            orderStatus = self:ProcessAttackOrder(1, GetDevScalar(MAC.kMoveSpeed, 8), deltaTime, orderTarget, orderLocation)
        elseif currentOrder:GetType() == kTechId.Weld then
            orderStatus = self:ProcessWeldOrder(deltaTime, orderTarget, orderLocation)
        elseif currentOrder:GetType() == kTechId.Build or currentOrder:GetType() == kTechId.Construct then
            orderStatus = self:ProcessConstruct(deltaTime, orderTarget, orderLocation)
        end
        
        if orderStatus == kOrderStatus.Cancelled then
            self:ClearCurrentOrder()
        elseif orderStatus == kOrderStatus.Completed then
            self:CompletedCurrentOrder()
        end
        
    end
    
end

function MAC:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server and self:GetIsAlive() then

        // assume we're not moving initially
        self.moving = false
    
        if not self:GetHasOrder() then
            FindSomethingToDo(self)
        else
            UpdateOrders(self, deltaTime)
        end
        
        self.constructing = Shared.GetTime() - self.timeOfLastConstruct < 0.5
        self.welding = Shared.GetTime() - self.timeOfLastWeld < 0.5

        if self.moving and not self.jetsSound:GetIsPlaying() then
            self.jetsSound:Start()
        elseif not self.moving and self.jetsSound:GetIsPlaying() then
            self.jetsSound:Stop()
        end
        
    // client side build / weld effects
    elseif Client and self:GetIsAlive() then
    
        if self.constructing then
        
            if not self.timeLastConstructEffect or self.timeLastConstructEffect + kConstructRate < Shared.GetTime()  then
            
                self:TriggerEffects("mac_construct")
                self.timeLastConstructEffect = Shared.GetTime()
                
            end
            
        end
        
        if self.welding then
        
            if not self.timeLastWeldEffect or self.timeLastWeldEffect + kWeldRate < Shared.GetTime()  then
            
                self:TriggerEffects("mac_weld")
                self.timeLastWeldEffect = Shared.GetTime()
                
            end
            
        end
        
        if self:GetHasOrder() ~= self.clientHasOrder then
        
            self.clientHasOrder = self:GetHasOrder()
            
            if self.clientHasOrder then
                self:TriggerEffects("mac_set_order")
            end
            
        end

        if self.jetsCinematics then

            for id,cinematic in ipairs(self.jetsCinematics) do
                self.jetsCinematics[id]:SetIsActive(self.moving and self:GetIsVisible())
            end

        end

    end
    
end

function MAC:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.MACEMP then
    
        local empBlast = CreateEntity(EMPBlast.kMapName, self:GetOrigin(), self:GetTeamNumber())
        return empBlast ~= nil, false
    
    end
    
    return ScriptActor.PerformActivation(self, techId, position, normal, commander)
    
end

function MAC:GetMeleeAttackOrigin()
    return self:GetAttachPointOrigin("fxnode_welder")
end

function MAC:GetMeleeAttackDamage()
    return kMACAttackDamage
end

function MAC:GetMeleeAttackInterval()
    return kMACAttackFireDelay 
end

function MAC:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then return 
            {   kTechId.Attack, kTechId.Stop, kTechId.Welding, kTechId.None,
                kTechId.MACEMP, kTechId.None, kTechId.None, kTechId.None }

    else return nil end
    
end

function MAC:OnOverrideDoorInteraction(inEntity)
    // MACs will not open the door if they are currently
    // welding it shut
    if self:GetHasOrder() then
        local order = self:GetCurrentOrder()
        local targetId = order:GetParam()
        local target = Shared.GetEntity(targetId)
        if (target ~= nil) then
            if (target == inEntity) then
               return false, 0
            end
        end
    end
    return true, 4
end

function MAC:UpdateIncludeRelevancyMask()
    SetAlwaysRelevantToCommander(self, true)
end

if Server then
	
	function MAC:GetCanReposition()
	    return true
	end
	
	function MAC:OverrideRepositioningSpeed()
	    return MAC.kMoveSpeed *.4
	end	
	
	function MAC:OverrideRepositioningDistance()
	    return 0.8
	end	

    function MAC:OverrideGetRepositioningTime()
	    return .5
	end

end

local function GetOrderMovesMAC(orderType)

    return orderType == kTechId.Move or
           orderType == kTechId.Attack or
           orderType == kTechId.Build or
           orderType == kTechId.Construct or
           orderType == kTechId.Weld

end

function MAC:OnUpdateAnimationInput(modelMixin)

    PROFILE("MAC:OnUpdateAnimationInput")
    
    local move = "idle"
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if GetOrderMovesMAC(currentOrder:GetType()) then
            move = "run"
        end
    
    end
    modelMixin:SetAnimationInput("move",  move)
    
    local currentTime = Shared.GetTime()
    local activity = "none"
    if currentTime - self:GetTimeOfLastAttackOrder() < 0.5 then
        activity = "primary"
    elseif self.constructing or self.welding then
        activity = "build"
    end
    modelMixin:SetAnimationInput("activity", activity)

end

function MAC:GetShowHitIndicator()
    return false
end

local kMACHealthbarOffset = Vector(0, 1.4, 0)
function MAC:GetHealthbarOffset()
    return kMACHealthbarOffset
end 

function MAC:OnDestroy()

    Entity.OnDestroy(self)

    if Client then

        for id,cinematic in ipairs(self.jetsCinematics) do

            Client.DestroyCinematic(cinematic)
            self.jetsCinematics[id] = nil

        end

    end
    
end

Shared.LinkClassToMap("MAC", MAC.kMapName, networkVars, true)

if Server then

    local function OnCommandFollowAndWeld(client)

        if client ~= nil and Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            for _, mac in ipairs(GetEntitiesForTeamWithinRange("MAC", player:GetTeamNumber(), player:GetOrigin(), 10)) do
                mac:GiveOrder(kTechId.FollowAndWeld, player:GetId(), player:GetOrigin(), nil, false, false)
            end
            
        end

    end

    Event.Hook("Console_followandweld", OnCommandFollowAndWeld)

end
