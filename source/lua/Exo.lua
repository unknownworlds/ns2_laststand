// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\Exo.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponHolder.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")

local kExoFirstPersonHitEffectName = PrecacheAsset("cinematics/marine/exo/hit_view.cinematic")

class 'Exo' (Player)

local networkVars =
{
    flashlightOn = "boolean",
    flashlightLastFrame = "private boolean",
    idleSound2DId = "private entityid",
    thrustersActive = "compensated boolean",
    timeThrustersEnded = "private compensated time",
    timeThrustersStarted = "private compensated time",
    weaponUpgradeLevel = "integer (0 to 3)",
    inventoryWeight = "float",

    driverHealth = string.format("private float (0 to %f by 1)", LiveMixin.kMaxHealth),
    driverArmor = string.format("private float (0 to %f by 1)", LiveMixin.kMaxArmor)
}

Exo.kMapName = "exo"

local kModelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_cm.animation_graph")

local kDualModelName = PrecacheAsset("models/marine/exosuit/exosuit_mm.model")
local kDualAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_mm.animation_graph")

local kClawRailgunModelName = PrecacheAsset("models/marine/exosuit/exosuit_cr.model")
local kClawRailgunAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_cr.animation_graph")

local kDualRailgunModelName = PrecacheAsset("models/marine/exosuit/exosuit_rr.model")
local kDualRailgunAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_rr.animation_graph")

Shared.PrecacheSurfaceShader("shaders/ExoScreen.surface_shader")

local kIdle2D = PrecacheAsset("sound/NS2.fev/marine/heavy/idle_2D")

if Client then
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/heal_exo_view.surface_shader")
end

local kExoHealViewMaterialName = "cinematics/vfx_materials/heal_exo_view.material"

local kHealthWarning = PrecacheAsset("sound/NS2.fev/marine/heavy/warning")
local kHealthWarningTrigger = 0.4

local kHealthCritical = PrecacheAsset("sound/NS2.fev/marine/heavy/critical")
local kHealthCriticalTrigger = 0.2

local kWalkMaxSpeed = 1.0
local kMaxSpeed = 1.0
local kViewOffsetHeight = 2.3
local kAcceleration = 1.0

local kSmashEggRange = 1.5

local kCrouchShrinkAmount = 0
local kExtentsCrouchShrinkAmount = 0

local kThrustersCooldownTime = 4
local kThrusterDuration = 1.5

local kDeploy2DSound = PrecacheAsset("sound/NS2.fev/marine/heavy/deploy_2D")

local kThrusterCinematic = PrecacheAsset("cinematics/marine/exo/thruster.cinematic")
local kThrusterLeftAttachpoint = "Exosuit_LFoot"
local kThrusterRightAttachpoint = "Exosuit_RFoot"
local kFlaresAttachpoint = "Exosuit_UpprTorso"

// How fast does the Exo armor get repaired by welders.
local kArmorWeldRatePlayer = 25
local kArmorWeldRateMAC = 12.5

local kExoViewDamaged = PrecacheAsset("cinematics/marine/exo/hurt_view.cinematic")
local kExoViewHeavilyDamaged = PrecacheAsset("cinematics/marine/exo/hurt_severe_view.cinematic")

local kFlareCinematic = PrecacheAsset("cinematics/marine/exo/lens_flare.cinematic")

local kThrusterUpwardsAcceleration = 2
local kThrusterHorizontalAcceleration = 2

Exo.kXZExtents = 0.55
Exo.kYExtents = 1.2

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)

local function SmashNearbyEggs(self)

    if not GetIsVortexed(self) then

        local nearbyEggs = GetEntitiesWithinRange("Egg", self:GetOrigin(), kSmashEggRange)
        for _, egg in ipairs(nearbyEggs) do
            egg:Kill(self, self, self:GetOrigin(), Vector(0, -1, 0))
        end
    
    end
    
    // Keep on killing those nasty eggs forever.
    return true
    
end

function Exo:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kExoFov })
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, WeldableMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, TunnelUserMixin)
    
    self:SetIgnoreHealth(true)
    
    self:AddTimedCallback(SmashNearbyEggs, 0.1)
    
    self.deployed = false
    
    self.flashlightOn = false
    self.flashlightLastFrame = false
    self.idleSound2DId = Entity.invalidId
    self.timeThrustersEnded = 0
    self.timeThrustersStarted = 0
    self.inventoryWeight = 0
    
    if Server then
    
        self.idleSound2D = Server.CreateEntity(SoundEffect.kMapName)
        self.idleSound2D:SetAsset(kIdle2D)
        self.idleSound2D:SetParent(self)
        self.idleSound2D:Start()
        
        // Only sync 2D sound with this Exo player.
        self.idleSound2D:SetPropagate(Entity.Propagate_Callback)
        function self.idleSound2D.OnGetIsRelevant(_, player)
            return player == self
        end
        
        self.idleSound2DId = self.idleSound2D:GetId()
        
    elseif Client then
    
        self.flashlight = Client.CreateRenderLight()
        
        self.flashlight:SetType(RenderLight.Type_Spot)
        self.flashlight:SetColor(Color(.8, .8, 1))
        self.flashlight:SetInnerCone(math.rad(30))
        self.flashlight:SetOuterCone(math.rad(45))
        self.flashlight:SetIntensity(10)
        self.flashlight:SetRadius(25)
        //self.flashlight:SetGoboTexture("models/marine/male/flashlight.dds")
        
        self.flashlight:SetIsVisible(false)
        
    end
    
end

kExoLayout2DropTechId = 
{
    MinigunMinigun = kTechId.DropDualMiniExo,
    ClawRailgun    = kTechId.DropClawRailExo,
    RailgunRailgun = kTechId.DropDualRailExo
}

function Exo:OnInitialized()

    // Only set the model on the Server, the Client
    // will already have the correct model at this point.
    if Server then
    
        local modelName = kModelName
        local graphName = kAnimationGraph
        if self.layout == "MinigunMinigun" then
        
            modelName = kDualModelName
            graphName = kDualAnimationGraph
            
        elseif self.layout == "ClawRailgun" then
        
            modelName = kClawRailgunModelName
            graphName = kClawRailgunAnimationGraph
            
        elseif self.layout == "RailgunRailgun" then
        
            modelName = kDualRailgunModelName
            graphName = kDualRailgunAnimationGraph
            
        end
        
        // SetModel must be called before Player.OnInitialized is called so the attach points in
        // the Exo are valid to attach weapons to. This is far too subtle...
        self:SetModel(modelName, graphName)
        
    end
    
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })
    
    Player.OnInitialized(self)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self.armor = self:GetArmorAmount()
        if self.oldArmor then
            // restore armor from previous life..
            self.armor = self.oldArmor
        end
        self.maxArmor = self.armor
        
        self.thrustersActive = false
        
    elseif Client then
    
        InitMixin(self, HiveVisionMixin)
        self.clientThrustersActive = self.thrustersActive

        self.thrusterLeftCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.thrusterLeftCinematic:SetCinematic(kThrusterCinematic)
        self.thrusterLeftCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.thrusterLeftCinematic:SetParent(self)
        self.thrusterLeftCinematic:SetCoords(Coords.GetIdentity())
        self.thrusterLeftCinematic:SetAttachPoint(self:GetAttachPointIndex(kThrusterLeftAttachpoint))
        self.thrusterLeftCinematic:SetIsVisible(false)
        
        self.thrusterRightCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.thrusterRightCinematic:SetCinematic(kThrusterCinematic)
        self.thrusterRightCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.thrusterRightCinematic:SetParent(self)
        self.thrusterRightCinematic:SetCoords(Coords.GetIdentity())
        self.thrusterRightCinematic:SetAttachPoint(self:GetAttachPointIndex(kThrusterRightAttachpoint))
        self.thrusterRightCinematic:SetIsVisible(false)
        
        self.flares = Client.CreateCinematic(RenderScene.Zone_Default)
        self.flares:SetCinematic(kFlareCinematic)
        self.flares:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.flares:SetParent(self)
        self.flares:SetCoords(Coords.GetIdentity())
        self.flares:SetAttachPoint(self:GetAttachPointIndex(kFlaresAttachpoint))
        self.flares:SetIsVisible(false)
        
    end
    
end

local function ShowHUD(self, show)

    assert(Client)
    
    if ClientUI.GetScript("Hud/Marine/GUIMarineHUD") then
        ClientUI.GetScript("Hud/Marine/GUIMarineHUD"):SetIsVisible(show)
    end
    if ClientUI.GetScript("Hud/Marine/GUIExoHUD") then
        ClientUI.GetScript("Hud/Marine/GUIExoHUD"):SetIsVisible(show)
    end
    
end

function Exo:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    ShowHUD(self, false)
    
end

function Exo:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount
end

function Exo:GetExtentsCrouchShrinkAmount()
    return kExtentsCrouchShrinkAmount
end

// exo has no crouch animations
function Exo:GetCanCrouch()
    return false
end

function Exo:InitWeapons()

    Player.InitWeapons(self)
    
    local weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)
    
    if self.layout == "ClawMinigun" then
        weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
    elseif self.layout == "MinigunMinigun" then
        weaponHolder:SetWeapons(Minigun.kMapName, Minigun.kMapName)
    elseif self.layout == "ClawRailgun" then
        weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
    elseif self.layout == "RailgunRailgun" then
        weaponHolder:SetWeapons(Railgun.kMapName, Railgun.kMapName)
    else
    
        Print("Warning: incorrect layout set for exosuit")
        weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
        
    end
    
    weaponHolder:TriggerEffects("exo_login")
    self.inventoryWeight = weaponHolder:GetInventoryWeight(self)
    self:SetActiveWeapon(ExoWeaponHolder.kMapName)
    StartSoundEffectForPlayer(kDeploy2DSound, self)
    
end

function Exo:GetMaxBackwardSpeedScalar()
    return 1
end    

function Exo:OnDestroy()

    if self.flashlight ~= nil then
        Client.DestroyRenderLight(self.flashlight)
    end
    
    if self.thrusterLeftCinematic then
    
        Client.DestroyCinematic(self.thrusterLeftCinematic)
        self.thrusterLeftCinematic = nil
    
    end
    
    if self.thrusterRightCinematic then
    
        Client.DestroyCinematic(self.thrusterRightCinematic)
        self.thrusterRightCinematic = nil
    
    end
    
    if self.flares then
    
        Client.DestroyCinematic(self.flares)
        self.flares = nil
        
    end
    
    if self.armorDisplay then
        
        Client.DestroyGUIView(self.armorDisplay)
        self.armorDisplay = nil
        
    end
    
end

function Exo:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Exo:GetAcceleration()
    return ConditionalValue(self:GetIsOnSurface(), kAcceleration, kThrusterHorizontalAcceleration) * self:GetInventorySpeedScalar()
end

function Exo:GetMaxSpeed(possible)

    if possible then
        return kWalkMaxSpeed
    end    
    
    return kMaxSpeed * self:GetInventorySpeedScalar()
    
end

function Exo:MakeSpecialEdition()
    // Currently there's no Exo special edition visual difference
end

function Exo:GetHeadAttachpointName()
    return "Exosuit_HoodHinge"
end

function Exo:GetArmorAmount()

    local armorLevels = 0
    
    if GetHasTech(self, kTechId.Armor3, true) then
        armorLevels = 3
    elseif GetHasTech(self, kTechId.Armor2, true) then
        armorLevels = 2
    elseif GetHasTech(self, kTechId.Armor1, true) then
        armorLevels = 1
    end
    
    return kExosuitArmor + armorLevels * kExosuitArmorPerUpgradeLevel
    
end

function Exo:GetFirstPersonHitEffectName()
    return kExoFirstPersonHitEffectName
end 

function Exo:GetCanRepairOverride(target)
    return false
end

function Exo:GetReceivesBiologicalDamage()
    return false
end

function Exo:GetReceivesVaporousDamage()
    return false
end

function Exo:GetCanBeWeldedOverride()
    return not self:GetIsVortexed() and self:GetArmor() < self:GetMaxArmor(), false
end

function Exo:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

local function UpdateHealthWarningTriggered(self)

    local healthPercent = self:GetArmorScalar()
    if healthPercent > kHealthWarningTrigger then
        self.healthWarningTriggered = false
    end
    
    if healthPercent > kHealthCriticalTrigger then
        self.healthCriticalTriggered = false
    end
    
end

local kEngageOffset = Vector(0, 1.5, 0)
function Exo:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

local kExoHealthbarOffset = Vector(0, 1.8, 0)
function Exo:GetHealthbarOffset()
    return kExoHealthbarOffset
end

function Exo:OnWeldOverride(doer, elapsedTime)

    if self:GetArmor() < self:GetMaxArmor() then
    
        local weldRate = kArmorWeldRatePlayer
        if doer and doer:isa("MAC") then
            weldRate = kArmorWeldRateMAC
        end
      
        local addArmor = weldRate * elapsedTime
        self:SetArmor(self:GetArmor() + addArmor)
        
        if Server then
            UpdateHealthWarningTriggered(self)
        end
        
    end
    
end

function Exo:GetPlayerStatusDesc()
    return self:GetIsAlive() and kPlayerStatus.Exo or kPlayerStatus.Dead
end

/**
 * The Exo does not use anything. It smashes.
 */
function Exo:GetIsAbleToUse()
    return false
end

function Exo:GetInventorySpeedScalar(player)
    return 1 - self.inventoryWeight
end

local function UpdateIdle2DSound(self, yaw, pitch, dt)

    if self.idleSound2DId ~= Entity.invalidId then
    
        local idleSound2D = Shared.GetEntity(self.idleSound2DId)
        
        self.lastExoYaw = self.lastExoYaw or yaw
        self.lastExoPitch = self.lastExoPitch or pitch
        
        local yawDiff = math.abs(GetAnglesDifference(yaw, self.lastExoYaw))
        local pitchDiff = math.abs(GetAnglesDifference(pitch, self.lastExoPitch))
        
        self.lastExoYaw = yaw
        self.lastExoPitch = pitch
        
        local rotateSpeed = math.min(1, ((yawDiff ^ 2) + (pitchDiff ^ 2)) / 0.05)
        //idleSound2D:SetParameter("rotate", rotateSpeed, 1)
        
    end
    
end

local function UpdateThrusterEffects(self)

    if self.clientThrustersActive ~= self.thrustersActive then
    
        self.clientThrustersActive = self.thrustersActive
        
        // TODO: start / end thruster loop sound
        
        if self.thrustersActive then            
            self:TriggerEffects("exo_thruster_start")            
        else            
            self:TriggerEffects("exo_thruster_end")            
        end
    
    end
    
    local showEffect = ( not self:GetIsLocalPlayer() or self:GetIsThirdPerson() ) and self.thrustersActive
    self.thrusterLeftCinematic:SetIsVisible(showEffect)
    self.thrusterRightCinematic:SetIsVisible(showEffect)

end

function Exo:OnProcessMove(input)

    Player.OnProcessMove(self, input)
    
    if Client and not Shared.GetIsRunningPrediction() then
        UpdateIdle2DSound(self, input.yaw, input.pitch, input.time)
        UpdateThrusterEffects(self)
    end
    
    local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
    if not self.flashlightLastFrame and flashlightPressed then
    
        self:SetFlashlightOn(not self:GetFlashlightOn())
        StartSoundEffectOnEntity(Marine.kFlashlightSoundName, self, 1, self)
        
    end
    self.flashlightLastFrame = flashlightPressed
    
end

function Exo:SetFlashlightOn(state)
    self.flashlightOn = state
end

function Exo:GetFlashlightOn()
    return self.flashlightOn
end

if Server then

    function Exo:OnHealed()
        UpdateHealthWarningTriggered(self)
    end
    
    function Exo:OnTakeDamage(damage, attacker, doer, point, direction, damageType)
    
        local healthPercent = self:GetArmorScalar()
        if not self.healthCriticalTriggered and healthPercent <= kHealthCriticalTrigger then
        
            StartSoundEffectForPlayer(kHealthCritical, self)
            self.healthCriticalTriggered = true
            
        elseif not self.healthWarningTriggered and healthPercent <= kHealthWarningTrigger then
        
            StartSoundEffectForPlayer(kHealthWarning, self)
            self.healthWarningTriggered = true
            
        end
        
    end
    
    function Exo:OnKill(attacker, doer, point, direction)
    
        Player.OnKill(self, attacker, doer, point, direction)
        
        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon and activeWeapon.OnParentKilled then
            activeWeapon:OnParentKilled(attacker, doer, point, direction)
        end
        
        self:TriggerEffects("death", { classname = self:GetClassName(), effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })
        
    end
    
end

if Client then

    // The Exo overrides the default trigger for footsteps.
    // They are triggered by the view model for the local player but
    // still uses the default behavior for other players viewing the Exo.
    function Exo:TriggerFootstep()
    
        if self ~= Client.GetLocalPlayer() then
            Player.TriggerFootstep(self)
        end
        
    end
    
    function Exo:UpdateClientEffects(deltaTime, isLocal)
    
        Player.UpdateClientEffects(self, deltaTime, isLocal)
        
        if isLocal then
        
            local visible = self.deployed and self:GetIsAlive() and not self:GetIsThirdPerson()
            ShowHUD(self, visible)
            
        end
        
    end
    
    function Exo:OnUpdateRender()
    
        PROFILE("Exo:OnUpdateRender")
        
        Player.OnUpdateRender(self)
        
        local isLocal = self:GetIsLocalPlayer()
        local flashLightVisible = self.flashlightOn and (isLocal or self:GetIsVisible()) and self:GetIsAlive()
        local flaresVisible = flashLightVisible and (not isLocal or self:GetIsThirdPerson())
        
        // Synchronize the state of the light representing the flash light.
        self.flashlight:SetIsVisible(flashLightVisible)
        self.flares:SetIsVisible(flaresVisible)
        
        if self.flashlightOn then
        
            local coords = Coords(self:GetViewCoords())
            coords.origin = coords.origin + coords.zAxis * 0.75
            
            self.flashlight:SetCoords(coords)
            
            // Only display atmospherics for third person players.
            local density = 0.2
            if isLocal and not self:GetIsThirdPerson() then
                density = 0
            end
            self.flashlight:SetAtmosphericDensity(density)
            
        end
        
        if self:GetIsLocalPlayer() then
        
            local armorDisplay = self.armorDisplay
            if not armorDisplay then
            
                armorDisplay = Client.CreateGUIView(256, 256)
                armorDisplay:Load("lua/GUIExoArmorDisplay.lua")
                armorDisplay:SetTargetTexture("*exo_armor")
                self.armorDisplay = armorDisplay
                
            end
            
            local armorAmount = self:GetIsAlive() and math.ceil(math.max(1, self:GetArmor())) or 0
            armorDisplay:SetGlobal("armorAmount", armorAmount)
            
            // damaged effects for view model. triggers when under 60% and a stronger effect under 30%. every 3 seconds and non looping, so the effects fade out when healed up
            if not self.timeLastDamagedEffect or self.timeLastDamagedEffect + 3 < Shared.GetTime() then
            
                local healthScalar = self:GetHealthScalar()
                
                if healthScalar < .7 then
                
                    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                    local cinematicName = kExoViewDamaged
                    
                    if healthScalar < .4 then
                        cinematicName = kExoViewHeavilyDamaged
                    end
                    
                    cinematic:SetCinematic(cinematicName)
                
                end
                
                self.timeLastDamagedEffect = Shared.GetTime()
                
            end
            
        elseif self.armorDisplay then
        
            Client.DestroyGUIView(self.armorDisplay)
            self.armorDisplay = nil
            
        end
        
    end
    
end

function Exo:GetCanClimb()
    return false
end

function Exo:GetDeathMapName()
    return MarineSpectator.kMapName
end

function Exo:OnTag(tagName)

    PROFILE("Exo:OnTag")

    Player.OnTag(self, tagName)
    
    if tagName == "deploy_end" then
        self.deployed = true
    end
    
end

// jumping is handled in a different way for exos
function Exo:GetCanJump()
    return false
end

function Exo:HandleButtons(input)

    // LS Exos cannot move
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0
    input.commands = RemoveMoveCommand( input.commands, Move.Jump )

    Player.HandleButtons(self, input)
    
    // LS - let players exit the exosuit with the drop key
    if Server then

        if bit.band( input.commands, Move.Drop ) ~= 0 
        and self:GetIsAlive() then

            local techId = kExoLayout2DropTechId[ self.layout ]
            if techId == nil then
                techId = kTechId.DropExosuit
            end

            local exo = CreateEntityForTeam( techId, self:GetOrigin(), self:GetTeamNumber() )
            exo:SetHealth( self:GetArmor() )

            // Pop the marine next to the exosuit, make sure he does not get stuck
            local extents = LookupTechData(
                    kTechDataMaxExtents, kTechId.Marine,
                    Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents))
            local safeSpawnPoint = GetRandomSpawnForCapsule(
                    extents.y, extents.x, exo:GetOrigin()+Vector(0,3,0), 0, 2, EntityFilterAll()) 
                    or exo:GetOrigin() + Vector(0,3,0)

            local health = self.driverHealth
            local armor = self.driverArmor
            local marine = self:Replace(Marine.kMapName, self:GetTeamNumber(), false, safeSpawnPoint)
            marine:SetHealth(health)
            marine:SetArmor(armor)

        end

    end
    
    self:UpdateThrusters(input)

end

local function HandleThrusterStart(self)

    self.onGroundNeedsUpdate = true
    self.onGround = false                
    self.thrustersActive = true 
    self.jumping = true
    self.timeThrustersStarted = Shared.GetTime()

end

local function HandleThrusterEnd(self)

    self.thrustersActive = false
    self.timeThrustersEnded = Shared.GetTime()
    
    if self:GetIsOnGround() then
        self.jumping = false
    end 
    
end

function Exo:UpdateThrusters(input)

    local lastThrustersActive = self.thrustersActive
    local jumpPressed = (bit.band(input.commands, Move.Jump) ~= 0)

    if jumpPressed ~= lastThrustersActive then
    
        if jumpPressed then
        
            if self.timeThrustersEnded + kThrustersCooldownTime < Shared.GetTime() then
                HandleThrusterStart(self)
            end

        else
            HandleThrusterEnd(self)
        end
        
    end
    
    if self.thrustersActive and self.timeThrustersStarted + kThrusterDuration < Shared.GetTime() then
        HandleThrusterEnd(self)
    end

end

function Exo:GetIsOnSurface()
    return Player.GetIsOnSurface(self) and not self.thrustersActive
end

function Exo:GetIsOnGround()
    return Player.GetIsOnGround(self) and not self.thrustersActive
end

// for jetpack fuel display
function Exo:GetFuel()

    if self.thrustersActive then
        self.fuelFraction = 1 - Clamp((Shared.GetTime() - self.timeThrustersStarted) / kThrusterDuration, 0, 1)
    else
        self.fuelFraction = Clamp((Shared.GetTime() - self.timeThrustersEnded) / kThrustersCooldownTime, 0, 1)
    end
    
    return self.fuelFraction
        
end

local kUpVector = Vector(0, 1, 0)

// required to not stick to the ground during jetpacking
function Exo:ComputeForwardVelocity(input)

    // Call the original function to get the base forward velocity.
    local forwardVelocity = Player.ComputeForwardVelocity(self, input)
    
    if self.thrustersActive then
        forwardVelocity = forwardVelocity + kUpVector * kThrusterUpwardsAcceleration
    end
    
    return forwardVelocity
    
end

function Exo:AdjustGravityForce(input, gravity)
    
    if self.thrustersActive then
        gravity = 0
    end
    
    return gravity
      
end

function Exo:ConstrainMoveVelocity(wishVelocity)

end

function Exo:PerformsVerticalMove()
    return self.thrustersActive
end

function Exo:GetAirFrictionForce()
    return 0.5
end   

function Exo:GetAirMoveScalar()
    return 1
end

function Exo:GetArmorUseFractionOverride()
 return 1.0
end

if Client then

    function Exo:OnUpdate(deltaTime)

        Player.OnUpdate(self, deltaTime)
        UpdateThrusterEffects(self)

    end

end

if Server then

    local function GetCanTriggerAlert(self, techId, timeOut)

        if not self.alertTimes then
            self.alertTimes = {}
        end
        
        return not self.alertTimes[techId] or self.alertTimes[techId] + timeOut < Shared.GetTime()

    end
    
    function Exo:OnOverrideOrder(order)
        
        local orderTarget = nil
        
        if order:GetParam() ~= nil then
            orderTarget = Shared.GetEntity(order:GetParam())
        end
        
        // exos can only attack or move
        if orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
            order:SetType(kTechId.Attack)
        else
            order:SetType(kTechId.Move)
        end
        
    end

end

function Exo:GetAnimateDeathCamera()
    return false
end

function Exo:OverrideHealViewMateral()
    return kExoHealViewMaterialName
end

function  Exo:GetShowDamageArrows()
    return true
end

Shared.LinkClassToMap("Exo", Exo.kMapName, networkVars)
