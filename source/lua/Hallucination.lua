// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hallucination.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")

Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/hallucination.surface_shader")

class 'Hallucination' (ScriptActor)

Hallucination.kMapName = "hallucination"

Hallucination.kSpotRange = 15
Hallucination.kTurnSpeed  = 4 * math.pi
Hallucination.kDefaultMaxSpeed = 1
Hallucination.kDefaultInitialEnergy = 50
Hallucination.kDefaultMaxEnergy = 200

local networkVars =
{
    assignedTechId = "enum kTechId",
    moving = "boolean",
    attacking = "boolean",
    hallucinationIsVisible = "boolean",
}

AddMixinNetworkVars(EnergyMixin, networkVars)
AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

local gTechIdAttacking = nil
local function GetTechIdAttacks(techId)
    
    if not gTechIdAttacking then
        gTechIdAttacking = {}
        gTechIdAttacking[kTechId.Skulk] = true
        gTechIdAttacking[kTechId.Gorge] = true
        gTechIdAttacking[kTechId.Lerk] = true
        gTechIdAttacking[kTechId.Fade] = true
        gTechIdAttacking[kTechId.Onos] = true
    end
    
    return gTechIdAttacking[techId]
    
end

local ghallucinateIdToTechId = nil
function GetTechIdToEmulate(techId)

    if not ghallucinateIdToTechId then
    
        ghallucinateIdToTechId = {}
        ghallucinateIdToTechId[kTechId.HallucinateDrifter] = kTechId.Drifter
        ghallucinateIdToTechId[kTechId.HallucinateSkulk] = kTechId.Skulk
        ghallucinateIdToTechId[kTechId.HallucinateGorge] = kTechId.Gorge
        ghallucinateIdToTechId[kTechId.HallucinateLerk] = kTechId.Lerk
        ghallucinateIdToTechId[kTechId.HallucinateFade] = kTechId.Fade
        ghallucinateIdToTechId[kTechId.HallucinateOnos] = kTechId.Onos
        
        ghallucinateIdToTechId[kTechId.HallucinateHive] = kTechId.Hive
        ghallucinateIdToTechId[kTechId.HallucinateWhip] = kTechId.Whip
        ghallucinateIdToTechId[kTechId.HallucinateShade] = kTechId.Shade
        ghallucinateIdToTechId[kTechId.HallucinateCrag] = kTechId.Crag
        ghallucinateIdToTechId[kTechId.HallucinateShift] = kTechId.Shift
        ghallucinateIdToTechId[kTechId.HallucinateHarvester] = kTechId.Harvester
        ghallucinateIdToTechId[kTechId.HallucinateHydra] = kTechId.Hydra
    
    end
    
    return ghallucinateIdToTechId[techId]

end

local gHallucinationMenu = nil
local function GetHallucinationMenu(assignedTechId, menuTechId)

    if not gHallucinationMenu then
    
        gHallucinationMenu = {}
        
        local rootMenu = {}
        rootMenu[kTechId.Gorge] = { kTechId.Attack, kTechId.Move, kTechId.Stop, kTechId.HallucinateHydra }
        rootMenu[kTechId.Drifter] = { kTechId.Attack, kTechId.Move, kTechId.Stop }
        rootMenu[kTechId.Skulk] = { kTechId.Attack, kTechId.Move, kTechId.Stop }
        rootMenu[kTechId.Lerk] = { kTechId.Attack, kTechId.Move, kTechId.Stop }
        rootMenu[kTechId.Fade] = { kTechId.Attack, kTechId.Move, kTechId.Stop }
        rootMenu[kTechId.Onos] = { kTechId.Attack, kTechId.Move, kTechId.Stop }
        
        gHallucinationMenu[kTechId.RootMenu] = rootMenu
        
        gHallucinationMenu[kTechId.BuildMenu] = buildMenu
    
    end
    
    local menuEntry = gHallucinationMenu[menuTechId]
    if menuEntry then
        local classMenu = menuEntry[assignedTechId]
        return ConditionalValue(classMenu, classMenu, {})
    end
    
    return {}

end

local gTechIdRangedAttack = nil
local function GetHallucinationAttacksRanged(techId)

    if not gTechIdRangedAttack then
        gTechIdRangedAttack = {}
        gTechIdRangedAttack[kTechId.Gorge] = true
        gTechIdRangedAttack[kTechId.Lerk] = true
        gTechIdRangedAttack[kTechId.Hydra] = true
    end

    return gTechIdRangedAttack[techid]    

end

local gTechIdCanMove = nil
local function GetHallucinationCanMove(techId)

    if not gTechIdCanMove then
        gTechIdCanMove = {}
        gTechIdCanMove[kTechId.Skulk] = true
        gTechIdCanMove[kTechId.Gorge] = true
        gTechIdCanMove[kTechId.Lerk] = true
        gTechIdCanMove[kTechId.Fade] = true
        gTechIdCanMove[kTechId.Onos] = true
        
        gTechIdCanMove[kTechId.Drifter] = true
        gTechIdCanMove[kTechId.Whip] = true
    end 
       
    return gTechIdCanMove[techId]

end

local gTechIdCanBuild = nil
local function GetHallucinationCanBuild(techId)

    if not gTechIdCanBuild then
        gTechIdCanBuild = {}
        gTechIdCanBuild[kTechId.Gorge] = true
    end 
       
    return gTechIdCanBuild[techId]

end

local function GetEmulatedClassName(techId)
    return EnumToString(kTechId, techId)
end

// model graphs should already be precached elsewhere
local gTechIdAnimationGraph = nil
local function GetAnimationGraph(techId)

    if not gTechIdAnimationGraph then
        gTechIdAnimationGraph = {}
        gTechIdAnimationGraph[kTechId.Skulk] = "models/alien/skulk/skulk.animation_graph"
        gTechIdAnimationGraph[kTechId.Gorge] = "models/alien/gorge/gorge.animation_graph"
        gTechIdAnimationGraph[kTechId.Lerk] = "models/alien/lerk/lerk.animation_graph"
        gTechIdAnimationGraph[kTechId.Fade] = "models/alien/fade/fade.animation_graph"         
        gTechIdAnimationGraph[kTechId.Onos] = "models/alien/onos/onos.animation_graph"
        gTechIdAnimationGraph[kTechId.Drifter] = "models/alien/drifter/drifter.animation_graph"  
        
        gTechIdAnimationGraph[kTechId.Hive] = "models/alien/hive/hive.animation_graph"
        gTechIdAnimationGraph[kTechId.Whip] = "models/alien/whip/whip.animation_graph"
        gTechIdAnimationGraph[kTechId.Shade] = "models/alien/shade/shade.animation_graph"
        gTechIdAnimationGraph[kTechId.Crag] = "models/alien/crag/crag.animation_graph"
        gTechIdAnimationGraph[kTechId.Shift] = "models/alien/shift/shift.animation_graph"
        gTechIdAnimationGraph[kTechId.Harvester] = "models/alien/harvester/harvester.animation_graph"
        gTechIdAnimationGraph[kTechId.Hydra] = "models/alien/hydra/hydra.animation_graph"
        
    end
    
    return gTechIdAnimationGraph[techId]

end

local gTechIdMaxMovementSpeed = nil
local function GetMaxMovementSpeed(techId)

    if not gTechIdMaxMovementSpeed then
        gTechIdMaxMovementSpeed = {}
        gTechIdMaxMovementSpeed[kTechId.Skulk] = 8
        gTechIdMaxMovementSpeed[kTechId.Gorge] = 5.1
        gTechIdMaxMovementSpeed[kTechId.Lerk] = 9
        gTechIdMaxMovementSpeed[kTechId.Fade] = 7
        gTechIdMaxMovementSpeed[kTechId.Onos] = 7
        
        gTechIdMaxMovementSpeed[kTechId.Drifter] = 5
        gTechIdMaxMovementSpeed[kTechId.Whip] = 4
    
    end
    
    local moveSpeed = gTechIdMaxMovementSpeed[techId]
    
    return ConditionalValue(moveSpeed == nil, Hallucination.kDefaultMaxSpeed, moveSpeed)

end

local gTechIdMoveState = nil
local function GetMoveName(techId)

    if not gTechIdMoveState then
        gTechIdMoveState = {}
        gTechIdMoveState[kTechId.Lerk] = "fly"
    
    end
    
    local moveState = gTechIdMoveState[techId]
    
    return ConditionalValue(moveState == nil, "run", moveState)

end

local function SetAssignedAttributes(self, hallucinationTechId)

    local model = LookupTechData(self.assignedTechId, kTechDataModel, Skulk.kModelName)
    local health = math.min(LookupTechData(self.assignedTechId, kTechDataMaxHealth, kSkulkHealth) * kHallucinationHealthFraction, kHallucinationMaxHealth)
    local armor = LookupTechData(self.assignedTechId, kTechDataMaxArmor, kSkulkArmor) * kHallucinationArmorFraction
    
    // using the energy values defined for the Hallucination instead from the real unit
    self.energy = LookupTechData(hallucinationTechId, kTechDataInitialEnergy, Hallucination.kDefaultInitialEnergy)
    self.maxEnergy = LookupTechData(hallucinationTechId, kTechDataMaxEnergy, Hallucination.kDefaultMaxEnergy)

    self.maxSpeed = GetMaxMovementSpeed(self.assignedTechId)    
    self:SetModel(model, GetAnimationGraph(self.assignedTechId))
    self:SetMaxHealth(health)
    self:SetHealth(health)
    self:SetMaxArmor(armor)
    self:SetArmor(armor)
    
    if self.assignedTechId == kTechId.Hive then
    
        local attachedTechPoint = self:GetAttached()
        if attachedTechPoint then
            attachedTechPoint:SetIsSmashed(true)
        end
    
    end
    
end

function Hallucination:OnCreate()
    
    ScriptActor.OnCreate(self)
    
    InitMixin(self, EnergyMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    
    if Server then
    
        self.hallucinationIsVisible = true
        self.attacking = false
        self.moving = false
        self.assignedTechId = kTechId.Skulk

        InitMixin(self, SleeperMixin)
        
    end

end

function Hallucination:OnInitialized()
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        SetAssignedAttributes(self, kTechId.HallucinateSkulk)

        InitMixin(self, RepositioningMixin)

        self:SetPhysicsType(PhysicsType.Kinematic)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, MobileTargetMixin)
    
    end
    
    self:SetUpdates(true)
    
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
end

function Hallucination:GetCanUpdateEnergy()
    return true
end

function Hallucination:OverrideGetEnergyUpdateRate()
    return -kEnergyUpdateRate
end

function Hallucination:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    
    if Client then
    
        if self.hallucinationMaterial then
        
            Client.DestroyRenderMaterial(self.hallucinationMaterial)
            self.hallucinationMaterial = nil
            
        end
    
    end

end

function Hallucination:GetIsFlying()
    return self.assignedTechId == kTechId.Drifter
end

function Hallucination:SetEmulation(hallucinationTechId)

    self.assignedTechId = GetTechIdToEmulate(hallucinationTechId)
    SetAssignedAttributes(self, hallucinationTechId)

end

function Hallucination:GetMaxSpeed()
    if self.assignedTechId == kTechId.Fade and not self.hallucinationIsVisible then
        return self.maxSpeed * 2
    end

    return self.maxSpeed
end

/*
function Hallucination:GetSurfaceOverride()
    return "hallucination"
end
*/

function Hallucination:GetCanReposition()
    return GetHallucinationCanMove(self.assignedTechId)
end
 
function Hallucination:OverrideGetRepositioningTime()
    return 0.4
end    

function Hallucination:OverrideRepositioningSpeed()
    return self.maxSpeed * 0.8
end

function Hallucination:OverrideRepositioningDistance()
    if self.assignedTechId == kTechId.Onos then
        return 4
    end
    
    return 1.5
end

function Hallucination:GetCanSleep()
    return self:GetCurrentOrder() == nil    
end

function Hallucination:GetTurnSpeedOverride()
    return Hallucination.kTurnSpeed
end

function Hallucination:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        self:UpdateServer(deltaTime)
    elseif Client then
        self:UpdateClient(deltaTime)
    end    
    
    self.moveSpeed = 1
    
    self:SetPoseParam("move_yaw", 90)
    self:SetPoseParam("move_speed", self.moveSpeed)

end

function Hallucination:OnOverrideDoorInteraction(inEntity)   
    return true, 4
end

function Hallucination:GetIsMoving()
    return self.moving
end

function Hallucination:GetTechButtons(techId)

    return GetHallucinationMenu(self.assignedTechId, techId)
    
end

local function OnUpdateAnimationInputCustom(self, techId, modelMixin, moveState)

    if techId == kTechId.Lerk then
        modelMixin:SetAnimationInput("flapping", self:GetIsMoving())
    elseif techId == kTechId.Fade and not self.hallucinationIsVisible then
        modelMixin:SetAnimationInput("move", "blink")
    end

end

function Hallucination:OnUpdateAnimationInput(modelMixin)

    local moveState = "idle"
    
    if self:GetIsMoving() then
        moveState = GetMoveName(self.assignedTechId)
    end

    modelMixin:SetAnimationInput("built", true)

    modelMixin:SetAnimationInput("move", moveState) 
    OnUpdateAnimationInputCustom(self, self.assignedTechId, modelMixin, moveState)

end

function Hallucination:OnUpdatePoseParameters()
    self:SetPoseParam("grow", 1)    
end

if Server then

    function Hallucination:UpdateServer(deltaTime)
    
        if self.timeInvisible and not self.hallucinationIsVisible then
            self.timeInvisible = math.max(self.timeInvisible - deltaTime, 0)
            
            if self.timeInvisible == 0 then
            
                self.hallucinationIsVisible = true
            
            end
            
        end
            
        self:UpdateOrders(deltaTime)
        
        if self:GetEnergy() <= 0 then
            self:Kill()
        end
    
    end
    
    function Hallucination:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        self:TriggerEffects("death_hallucination")
        DestroyEntity(self)
        
    end
    
    function Hallucination:OnScan()
        self:Kill()
    end
    
    function Hallucination:GetHoverHeight()
    
        if self.assignedTechId == kTechId.Lerk or self.assignedTechId == kTechId.Drifter then
            return 1.5   
        else
            return 0
        end    
        
    end
    
    local function PerformSpecialMovement(self)
        
        if self.assignedTechId == kTechId.Fade then
            
            // blink every now and then
            if not self.nextTimeToBlink then
                self.nextTimeToBlink = Shared.GetTime()
            end    
            
            local distToTarget = (self:GetCurrentOrder():GetLocation() - self:GetOrigin()):GetLengthXZ()
            if self.nextTimeToBlink <= Shared.GetTime() and distToTarget > 17 then // 17 seems to be a good value as minimum distance to trigger blink

                self.hallucinationIsVisible = false
                self.timeInvisible = 0.5 + math.random() * 2
                self.nextTimeToBlink = Shared.GetTime() + 2 + math.random() * 8
            
            end
            
        end
    
    end
    
    function Hallucination:UpdateMoveOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        ASSERT(currentOrder)
        
        self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), self:GetMaxSpeed(), deltaTime)
        
        if self:IsTargetReached(currentOrder:GetLocation(), kAIMoveOrderCompleteDistance) then
            self:CompletedCurrentOrder()
        else
        
            self:SetOrigin(GetHoverAt(self, self:GetOrigin()))
            PerformSpecialMovement(self)
            self.moving = true
            
        end
        
    end
    
    function Hallucination:UpdateAttackOrder(deltaTime)
    
        if not GetTechIdAttacks(self.assignedTechId) then
            self:ClearCurrentOrder()
            return
        end    
        
    end
    
    function Hallucination:UpdateBuildOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        local techId = currentOrder:GetParam()
        local engagementDist = LookupTechData(techId, kTechDataEngagementDistance, 0.35)
        local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
        
        if (distToTarget < engagementDist) then   
        
            local commander = self:GetOwner()
            if (not commander) then
                self:ClearOrders(true, true)
                return
            end
            
            local techIdToEmulate = GetTechIdToEmulate(techId)
            
            local legalBuildPosition = false
            local position = nil
            local attachEntity = nil
            
            local origin = currentOrder:GetLocation()
            local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), CollisionRep.Select, PhysicsMask.CommanderBuild, EntityFilterOne(self))
            legalBuildPosition, position, attachEntity = GetIsBuildLegal(techIdToEmulate, trace.endPoint, 0, 4, self:GetOwner(), self)

            if (not legalBuildPosition) then
                self:ClearOrders()
                return
            end
            
            local createdHallucination = CreateEntity(Hallucination.kMapName, position, self:GetTeamNumber())
            if createdHallucination then
            
                createdHallucination:SetEmulation(techId)
                
                // Drifter hallucinations are destroyed when they construct something
                if self.assignedTechId == kTechId.Drifter then
                    self:Kill()
                else
                
                    local costs = LookupTechData(techId, kTechDataCostKey, 0)
                    self:AddEnergy(-costs)
                    self:TriggerEffects("spit_structure")
                    self:CompletedCurrentOrder()
                
                end
                
            else
            
                self:ClearOrders(true, true)
                return
                
            end
            
        else
            self:UpdateMoveOrder(deltaTime)
        end
        
    end
    
    function Hallucination:UpdateOrders(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()

        if currentOrder then
        
            if currentOrder:GetType() == kTechId.Move and GetHallucinationCanMove(self.assignedTechId) then
                self:UpdateMoveOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Attack then
                self:UpdateAttackOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Build and GetHallucinationCanBuild(self.assignedTechId) then
                self:UpdateBuildOrder(deltaTime)
            else
                self:ClearCurrentOrder()
            end
            
        else

            self.moving = false
            self.attacking = false

        end    
    
    end
    
    function Hallucination:OverrideTechTreeAction(techNode, position, orientation, commander)

        local success = false
        local keepProcessing = true
        
        // Convert build tech actions into build orders (gorge and drifter hallucinations)
        if(techNode:GetIsEnergyBuild()) then
            
            self:GiveOrder(kTechId.Build, techNode:GetTechId(), position, orientation, not commander.queuingOrders, false, commander)

            if self:GetOwner() == nil then
                self:SetOwner(commander)
            end
            
            success = true
            keepProcessing = false
            
        end
        
        return success, keepProcessing
        
    end
    
end

function Hallucination:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.35, 0)
end

function Hallucination:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

if Client then

    function Hallucination:OnUpdateRender()
    
        PROFILE("Hallucination:OnUpdateRender")
    
        local showMaterial = not GetAreEnemies(self, Client.GetLocalPlayer())
    
        local model = self:GetRenderModel()
        if model then

            if showMaterial then
                
                if not self.hallucinationMaterial then
                    self.hallucinationMaterial = AddMaterial(model, "cinematics/vfx_materials/hallucination.material")
                end
                
                self:SetOpacity(0, "hallucination")
            
            else
            
                if self.hallucinationMaterial then
                    RemoveMaterial(model, self.hallucinationMaterial)
                    self.hallucinationMaterial = nil
                end
                
                self:SetOpacity(1, "hallucination")
            
            end
            
        end
    
    end

    function Hallucination:UpdateClient(deltaTime)
    
        if self.clientHallucinationIsVisible == nil then
            self.clientHallucinationIsVisible = self.hallucinationIsVisible
        end    
    
        if self.clientHallucinationIsVisible ~= self.hallucinationIsVisible then
        
            self.clientHallucinationIsVisible = self.hallucinationIsVisible
            if self.hallucinationIsVisible then
                self:OnShow()
            else
                self:OnHide()
            end  
        end
    
        self:SetIsVisible(self.hallucinationIsVisible)
        
        if self:GetIsVisible() and self:GetIsMoving() then
            self:UpdateMoveSound(deltaTime)
        end
    
    end
    
    function Hallucination:UpdateMoveSound(deltaTime)
    
        if not self.timeUntilMoveSound then
            self.timeUntilMoveSound = 0
        end
        
        if self.timeUntilMoveSound == 0 then
        
            local surface = GetSurfaceAndNormalUnderEntity(self)            
            self:TriggerEffects("footstep", {classname = GetEmulatedClassName(self.assignedTechId), surface = surface, left = true, sprinting = false, forward = true, crouch = false})
            self.timeUntilMoveSound = 0.3
            
        else
            self.timeUntilMoveSound = math.max(self.timeUntilMoveSound - deltaTime, 0)     
        end
    
    end
    
    function Hallucination:OnHide()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_out")
        end
    
    end
    
    function Hallucination:OnShow()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_in")
        end
    
    end

end

Shared.LinkClassToMap("Hallucination", Hallucination.kMapName, networkVars)