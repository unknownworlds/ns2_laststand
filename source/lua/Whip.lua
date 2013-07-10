// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Whip.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides attacks nearby players with area of effect ballistic attack.
// Also gives attack/hurt capabilities to the commander. Range should be just shorter than 
// marine sentries.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Whip' (ScriptActor)

Whip.kMapName = "whip"

Whip.kModelName = PrecacheAsset("models/alien/whip/whip.model")
Whip.kAnimationGraph = PrecacheAsset("models/alien/whip/whip.animation_graph")

Whip.kScanThinkInterval = .1
Whip.kROF = 2.0
Whip.kFov = 360
Whip.kTargetCheckTime = .3
Whip.kRange = 6
Whip.kAreaEffectRadius = 3
Whip.kDamage = 50
Whip.kMoveSpeed = 2.5
Whip.kMoveSpeedOnInfestation = 4
Whip.kMaxMoveSpeedParam = 10

Whip.kWhipBallParam = "ball"

// Fury
Whip.kFuryRadius = 6
Whip.kFuryDuration = 6
Whip.kFuryDamageBoost = .1          // 10% extra damage

// Whacking; throwing back grenades that comes into whackRange
// need a little bit extra range to avoid getting hit by grenades going right at it
Whip.kWhackRange = 6.5
// performance; we track grenades that are close enough every tick, but we update the
// grenade list only 3 times per second. Grenades travel 15m/sec, so we grab those
// inside 10m + whackRange and put them onto our list
Whip.kWhackInterrestRange = Whip.kWhackRange + 3

// range inside which a mature whip will select targets. If the target is inside Whip.kRange, it will
// get hit by a standard attack. If its longer, it will get targeted by a bombard.
Whip.kBombardRange = 20

local networkVars =
{
    attackYaw = "integer (0 to 360)",
    
    slapping = "boolean", // true if we have started a slap attack
    whacking = "boolean", // true if we have started a grenade whack attack
    bombarding = "boolean", // true if we have started a bombard attack
    rooted = "boolean",
    moving = "boolean",
    move_speed = "float",
    
    // Set as blocked until current animation finishes
    unblockTime = "time",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(TeleportMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

if Server then

    Script.Load("lua/Whip_Server.lua")
    Script.Load("lua/AiAttacksMixin.lua")
    Script.Load("lua/AiSlapAttackType.lua")
    Script.Load("lua/AiGrenadeWhackAttackType.lua")
    Script.Load("lua/AiBombardAttackType.lua")
    
end

Shared.PrecacheSurfaceShader("models/alien/whip/ball.surface_shader")

function Whip:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, TeleportMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    
    self.attackYaw = 0
    
    self.slapping = false
    self.whacking = false
    self.bombarding = false
    self.rooted = true
    self.moving = false
    self.move_speed = 0
    self.unblockTime = 0
    
    if Server then
        InitMixin(self, InfestationTrackerMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    // to prevent collision with whip bombs
    self:SetPhysicsGroup(PhysicsGroup.WhipGroup)
    
end

function Whip:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, DoorMixin)

    self:SetModel(Whip.kModelName, Whip.kAnimationGraph)
    
    self:SetUpdates(true)
    
    if Server then
    
        InitMixin(self, MobileTargetMixin)
    
        // The AiAttacks create TargetSelectors, so the TargetCacheMixin is required.
        InitMixin(self, TargetCacheMixin)
        
        InitMixin(self, AiAttacksMixin)
        
        // The various attacks are added here.
        self.slapAttack = AiSlapAttackType():Init(self)
        self:AddAiAttackType(self.slapAttack)
        
        self.whackAttack = AiGrenadeWhackAttackType():Init(self)
        self:AddAiAttackType(self.whackAttack)
        
        self.bombardAttack = AiBombardAttackType():Init(self)
        self.bombardAttack.enabled = false // enable when evolved
        self:AddAiAttackType(self.bombardAttack)
        
        self:UpdateAiAttacks()
        
        InitMixin(self, RepositioningMixin)
        InitMixin(self, SleeperMixin)
        InitMixin(self, ControllerMixin)
        
        self:CreateController(PhysicsGroup.WhipGroup)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
end

function Whip:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Server then
        self.movingSound = nil
    end
    
end

function Whip:GetIsMoveable()
    return true
end    

function Whip:GetMaturityRate()
    return kWhipMaturationTime
end

function Whip:GetMatureMaxHealth()
    return kMatureWhipHealth
end 

function Whip:GetMatureMaxArmor()
    return kMatureWhipArmor
end 

function Whip:GetMatureMaxEnergy()
    return kMatureWhipMaxEnergy
end 

function Whip:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Whip:GetCanSleep()
    return false // not self.moving and not self.whackAttack:GetTarget()
end

function Whip:GetMinimumAwakeTime()
    return 10
end

// Used for targeting
function Whip:GetFov()
    return Whip.kFov
end

function Whip:GetDeathIconIndex()
    return kDeathMessageIcon.Whip
end

function Whip:GetTechButtons(techId)

    local techButtons = nil

    techButtons = { kTechId.Attack, kTechId.Stop, kTechId.None, kTechId.None,  
                    kTechId.None,  kTechId.None,  kTechId.None,  kTechId.None, }

    local rootUnroot = self.rooted and kTechId.WhipUnroot or kTechId.WhipRoot
    techButtons[6] = rootUnroot
    
    if not self:GetHasUpgrade(kTechId.WhipBombard) then
        techButtons[5] = kTechId.EvolveBombard
    end
    
    if self.rooted then
        techButtons[3] = kTechId.GrenadeWhack
    end
    
    return techButtons
    
end

function Whip:OverrideHintString(hintString)

    if self:GetHasUpgrade(kTechId.WhipBombard) then
        return "WHIP_BOMBARD_HINT"
    end
    
    return hintString
    
end

function Whip:GetActivationTechAllowed(techId)

    if techId == kTechId.WhipRoot then
        return self:GetIsBuilt() and self:GetGameEffectMask(kGameEffect.OnInfestation)
    elseif techId == kTechId.WhipUnroot then
        return self:GetIsBuilt() and self.rooted == true
    end

    return true
        
end

function Whip:GetReceivesStructuralDamage()
    return true
end

function Whip:OnGiveUpgrade(techId)
    if techId == kTechId.WhipBombard then
        self.bombardAttack.enabled = true
    end
end


function Whip:GetTechAllowed(techId, techNode, player)
    
    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)
    
    if techId == kTechId.Stop then
        allowed = self:GetCurrentOrder() ~= nil
    end
    
    if techId == kTechId.Attack then
        allowed = self:GetIsBuilt() and self.rooted == true
    end
    
    if techId == kTechId.Move then
        allowed = not self.rooted
    end

    return allowed and self:GetIsUnblocked(), canAfford
end

function Whip:OnUpdatePoseParameters()

    self:SetPoseParam("attack_yaw", self.attackYaw)
    self:SetPoseParam("move_speed", self.move_speed)
    
    if self:GetHasUpgrade(kTechId.WhipBombard) then
        self:SetPoseParam(Whip.kWhipBallParam, 1.0)
    else
        self:SetPoseParam(Whip.kWhipBallParam, 0)
    end
    
end

function Whip:GetCanGiveDamageOverride()
    return true
end

function Whip:GetIsRooted()
    return self.rooted
end

function Whip:GetIsUnblocked()
    return self.unblockTime == 0 or (Shared.GetTime() > self.unblockTime)
end

function Whip:OnOverrideDoorInteraction(inEntity)
    // Do not open doors when rooted.
    if (self:GetIsRooted()) then
        return false, 0
    end
    return true, 4
end

function Whip:OnUpdate(deltaTime)

    PROFILE("Whip:OnUpdate")
    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then        
        self:UpdateRootState()
           
        self:UpdateOrders(deltaTime)
    end
    
end

function Whip:AdjustPathingLocation(location)

    location = GetGroundAt(self, location, PhysicsMask.AIMovement)
    return location
    
end

function Whip:OnUpdateAnimationInput(modelMixin)

    PROFILE("Whip:OnUpdateAnimationInput")  
    
    local activity = "none"

    if self.slapping then
        activity = "primary"
    elseif self.whacking then
        activity = "whack"
    elseif self.bombarding then
        activity = "secondary"
    end 
    
    modelMixin:SetAnimationInput("activity", activity)
    modelMixin:SetAnimationInput("rooted", self.rooted)
    modelMixin:SetAnimationInput("move", self.moving and "run" or "idle")
    
end

function Whip:GetEyePos()
    return self:GetOrigin() + self:GetCoords().yAxis * 1.8
end

function Whip:GetVisualRadius()

    local slapRange = LookupTechData(self:GetTechId(), kVisualRange, nil)
    if self:GetHasUpgrade(kTechId.WhipBombard) then
        return { slapRange, Whip.kBombardRange }
    end
    
    return slapRange
    
end

function Whip:GetShowHitIndicator()
    return false
end

if Client then

    function Whip:OnTag(tagName)

        PROFILE("ARC:OnTag")
        
        if tagName == "attack_start" then
            self:TriggerEffects("whip_attack_start")        
        end
        
    end

end

function Whip:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

Shared.LinkClassToMap("Whip", Whip.kMapName, networkVars, true)