// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/StunMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/SprintMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/Weapons/Marine/Builder.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/DisorientableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/WebableMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'Marine' (Player)

Marine.kMapName = "marine"

if Server then
    Script.Load("lua/Marine_Server.lua")
elseif Client then
    Script.Load("lua/Marine_Client.lua")
end

Shared.PrecacheSurfaceShader("models/marine/marine.surface_shader")
Shared.PrecacheSurfaceShader("models/marine/marine_noemissive.surface_shader")

Marine.kModelName = PrecacheAsset("models/marine/male/male.model")
Marine.kBlackArmorModelName = PrecacheAsset("models/marine/male/male_special.model")
Marine.kSpecialEditionModelName = PrecacheAsset("models/marine/male/male_special_v1.model")

Marine.kMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

Marine.kDieSoundName = PrecacheAsset("sound/NS2.fev/marine/common/death")
Marine.kFlashlightSoundName = PrecacheAsset("sound/NS2.fev/common/light")
Marine.kGunPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_gun")
Marine.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")
Marine.kChatSound = PrecacheAsset("sound/NS2.fev/marine/common/chat")
Marine.kSoldierLostAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/soldier_lost")

Marine.kFlinchEffect = PrecacheAsset("cinematics/marine/hit.cinematic")
Marine.kFlinchBigEffect = PrecacheAsset("cinematics/marine/hit_big.cinematic")

Marine.kHitGroundStunnedSound = PrecacheAsset("sound/NS2.fev/marine/common/jump")
Marine.kSprintStart = PrecacheAsset("sound/NS2.fev/marine/common/sprint_start")
Marine.kSprintTiredEnd = PrecacheAsset("sound/NS2.fev/marine/common/sprint_tired")
Marine.kLoopingSprintSound = PrecacheAsset("sound/NS2.fev/marine/common/sprint_loop")

Marine.kEffectNode = "fxnode_playereffect"
Marine.kHealth = kMarineHealth
Marine.kBaseArmor = kMarineArmor
Marine.kArmorPerUpgradeLevel = kArmorPerUpgradeLevel
Marine.kMaxSprintFov = 95
// Player phase delay - players can only teleport this often
Marine.kPlayerPhaseDelay = 2

Marine.kWalkMaxSpeed = 5                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
Marine.kRunMaxSpeed = 6.0               // 10 miles an hour = 16,093 meters/hour = 4.4 meters/second (increase for FPS tastes)
Marine.kRunInfestationMaxSpeed = 5.2    // 10 miles an hour = 16,093 meters/hour = 4.4 meters/second (increase for FPS tastes)

// How fast does our armor get repaired by welders
Marine.kArmorWeldRate = 25
Marine.kWeldedEffectsInterval = .5

Marine.kSpitSlowDuration = 3

Marine.kWalkBackwardSpeedScalar = 1.0

// start the get up animation after stun before giving back control
Marine.kGetUpAnimationLength = 0.5

// tracked per techId
Marine.kMarineAlertTimeout = 4

local kDropWeaponTimeLimit = 1
local kPickupWeaponTimeLimit = 1

Marine.kAcceleration = 100
Marine.kSprintAcceleration = 120 // 70
Marine.kSprintInfestationAcceleration = 60

Marine.kGroundFrictionForce = 16

Marine.kAirStrafeWeight = 2

local networkVars =
{      
    flashlightOn = "boolean",
    timeOfLastPhase = "private time",
    
    timeOfLastDrop = "private time",
    timeOfLastPickUpWeapon = "private time",
    
    flashlightLastFrame = "private boolean",
    
    timeLastSpitHit = "private time",
    lastSpitDirection = "private vector",
    
    ruptured = "boolean",
    interruptAim = "private boolean",
    poisoned = "boolean",
    catpackboost = "private boolean",
    weaponUpgradeLevel = "integer (0 to 3)",
    
    unitStatusPercentage = "private integer (0 to 100)"
    
}

AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(SprintMixin, networkVars)
AddMixinNetworkVars(OrderSelfMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(WebableMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)

function Marine:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    InitMixin(self, MarineActionFinderMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, SelectableMixin)
    
    Player.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, WebableMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, TunnelUserMixin)
    
    //self.loopingSprintSoundEntId = Entity.invalidId
    
    if Server then
    
        /*self.loopingSprintSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingSprintSound:SetAsset(Marine.kLoopingSprintSound)
        self.loopingSprintSound:SetParent(self)
        self.loopingSprintSoundEntId = self.loopingSprintSound:GetId()*/
        
        self.timePoisoned = 0
        self.poisoned = false
        
        // stores welder / builder progress
        self.unitStatusPercentage = 0
        self.timeLastUnitPercentageUpdate = 0
        
    elseif Client then
    
        self.flashlight = Client.CreateRenderLight()
        
        self.flashlight:SetType( RenderLight.Type_Spot )
        self.flashlight:SetColor( Color(.8, .8, 1) )
        self.flashlight:SetInnerCone( math.rad(30) )
        self.flashlight:SetOuterCone( math.rad(35) )
        self.flashlight:SetIntensity( 10 )
        self.flashlight:SetRadius( 15 ) 
        self.flashlight:SetGoboTexture("models/marine/male/flashlight.dds")
        
        self.flashlight:SetIsVisible(false)
        
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })

        InitMixin(self, DisorientableMixin)
        
    end

end

function Marine:OnInitialized()

    // work around to prevent the spin effect at the infantry portal spawned from
    // local player should not see the holo marine model
    if Client and Client.GetIsControllingPlayer() then
    
        local ips = GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), self:GetOrigin(), 1)
        if #ips > 0 then
            Shared.SortEntitiesByDistance(self:GetOrigin(), ips)
            ips[1]:PreventSpinEffect(0.2)
        end
    
    end

    // These mixins must be called before SetModel because SetModel eventually
    // calls into OnUpdatePoseParameters() which calls into these mixins.
    // Yay for convoluted class hierarchies!!!
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })
    InitMixin(self, OrderSelfMixin, { kPriorityAttackTargets = { "Harvester" } })
    InitMixin(self, StunMixin)
    InitMixin(self, NanoShieldMixin)
    InitMixin(self, SprintMixin)
    InitMixin(self, WeldableMixin)
    
    // SetModel must be called before Player.OnInitialized is called so the attach points in
    // the Marine are valid to attach weapons to. This is far too subtle...
    self:SetModel(Marine.kModelName, Marine.kMarineAnimationGraph)
    
    Player.OnInitialized(self)
    
    // Calculate max and starting armor differently
    self.armor = 0
    
    if Server then
    
        self.armor = self:GetArmorAmount()
        self.maxArmor = self.armor
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, InfestationTrackerMixin)
        self.timeRuptured = 0
        self.interruptStartTime = 0
        self.timeLastPoisonDamage = 0
        
        self.lastPoisonAttackerId = Entity.invalidId
        
    elseif Client then
    
        InitMixin(self, HiveVisionMixin)
        
        self:AddHelpWidget("GUIMarineHealthRequestHelp", 2)
        self:AddHelpWidget("GUIMarineFlashlightHelp", 2)
        self:AddHelpWidget("GUIBuyShotgunHelp", 2)
        self:AddHelpWidget("GUIMarineWeldHelp", 2)
        self:AddHelpWidget("GUIMapHelp", 1)
        
        self.notifications = { }
        self.timeLastSpitHitEffect = 0
        
    end
    
    self.weaponDropTime = 0
    self.timeOfLastPhase = 0
    
    local viewAngles = self:GetViewAngles()
    self.lastYaw = viewAngles.yaw
    self.lastPitch = viewAngles.pitch
    
    // -1 = leftmost, +1 = right-most
    self.horizontalSwing = 0
    // -1 = up, +1 = down
    
    self.timeLastSpitHit = 0
    self.lastSpitDirection = Vector(0, 0, 0)
    self.timeOfLastDrop = 0
    self.timeOfLastPickUpWeapon = 0
    self.ruptured = false
    self.interruptAim = false
    self.catpackboost = false
    self.timeCatpackboost = 0
    
    self.flashlightLastFrame = false
    
end

local blockBlackArmor = false
if Server then
    Event.Hook("Console_blockblackarmor", function() if Shared.GetCheatsEnabled() then blockBlackArmor = not blockBlackArmor end end)
end

function Marine:GetArmorLevel()

    local armorLevel = 0
    local techTree = self:GetTechTree()

    if techTree then
    
        local armor3Node = techTree:GetTechNode(kTechId.Armor3)
        local armor2Node = techTree:GetTechNode(kTechId.Armor2)
        local armor1Node = techTree:GetTechNode(kTechId.Armor1)
    
        if armor3Node and armor3Node:GetResearched() then
            armorLevel = 3
        elseif armor2Node and armor2Node:GetResearched()  then
            armorLevel = 2
        elseif armor1Node and armor1Node:GetResearched()  then
            armorLevel = 1
        end
        
    end

    return armorLevel

end

function Marine:GetWeaponLevel()

    local weaponLevel = 3
    local techTree = self:GetTechTree()

    if techTree then
        
            local weapon3Node = techTree:GetTechNode(kTechId.Weapons3)
            local weapon2Node = techTree:GetTechNode(kTechId.Weapons2)
            local weapon1Node = techTree:GetTechNode(kTechId.Weapons1)
        
            if weapon3Node and weapon3Node:GetResearched() then
                weaponLevel = 3
            elseif weapon2Node and weapon2Node:GetResearched()  then
                weaponLevel = 2
            elseif weapon1Node and weapon1Node:GetResearched()  then
                weaponLevel = 1
            end
            
    end

    return weaponLevel

end

function Marine:GetCanRepairOverride(target)
    return self:GetWeapon(Welder.kMapName) and HasMixin(target, "Weldable") and ( (target:isa("Marine") and target:GetArmor() < target:GetMaxArmor()) or (not target:isa("Marine") and target:GetHealthScalar() < 0.9) )
end

function Marine:GetSlowOnLand()
    return true
end

function Marine:GetArmorAmount()

    local armorLevels = 0
    
    if(GetHasTech(self, kTechId.Armor3, true)) then
        armorLevels = 3
    elseif(GetHasTech(self, kTechId.Armor2, true)) then
        armorLevels = 2
    elseif(GetHasTech(self, kTechId.Armor1, true)) then
        armorLevels = 1
    end
    
    return Marine.kBaseArmor + armorLevels*Marine.kArmorPerUpgradeLevel
    
end

function Marine:GetNanoShieldOffset()
    return Vector(0, -0.1, 0)
end

function Marine:OnDestroy()

    Player.OnDestroy(self)
    
    if Client then
    
        if self.ruptureMaterial then
        
            Client.DestroyRenderMaterial(self.ruptureMaterial)
            self.ruptureMaterial = nil
            
        end
        
        if self.flashlight ~= nil then
            Client.DestroyRenderLight(self.flashlight)
        end
        
        if self.buyMenu then
        
            GetGUIManager():DestroyGUIScript(self.buyMenu)
            self.buyMenu = nil
            MouseTracker_SetIsVisible(false)
            
        end
        
    end
    
end

function Marine:GetGroundFrictionForce()
    return ConditionalValue(self.crouching or self.isUsing, 28, Marine.kGroundFrictionForce) 
end

function Marine:HandleButtons(input)

    PROFILE("Marine:HandleButtons")
    
    Player.HandleButtons(self, input)
    
    if self:GetCanControl() then
    
        // Update sprinting state
        self:UpdateSprintingState(input)
        
        local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.flashlightLastFrame and flashlightPressed then
        
            self:SetFlashlightOn(not self:GetFlashlightOn())
            StartSoundEffectOnEntity(Marine.kFlashlightSoundName, self, 1, self)
            
        end
        self.flashlightLastFrame = flashlightPressed
        
        if Server then

            if bit.band(input.commands, Move.Drop) ~= 0 and not self:GetIsVortexed() then

                self:Drop()
                
            elseif bit.band(input.commands, Move.Use) ~= 0 and not self:GetIsVortexed() then

                // Pick up weapon

                local weaponTarget = self:FindWeaponTarget()
                
                if weaponTarget and Shared.GetTime() > self.timeOfLastPickUpWeapon + kPickupWeaponTimeLimit then
                
                    if weaponTarget.GetReplacementWeaponMapName then
                    
                        local replacement = weaponTarget:GetReplacementWeaponMapName()
                        local toReplace = self:GetWeapon(replacement)

                        if toReplace then
                        
                            self:RemoveWeapon(toReplace)
                            DestroyEntity(toReplace)
                            
                        end
                        
                    end
                    
                    self:AddWeapon(weaponTarget, true)
                    StartSoundEffectAtOrigin(Marine.kGunPickupSound, self:GetOrigin())
                    
                    self.timeOfLastPickUpWeapon = Shared.GetTime()

                else

                    local target = self:FindDismantleTarget()
                    if target then
                        target:OnUse(self, kUseInterval, {})
                    end


                end
            end
        end
    end
    
end

function Marine:GetOnGroundRecently()
    return (self.timeLastOnGround ~= nil and Shared.GetTime() < self.timeLastOnGround + 0.4) 
end

function Marine:SetFlashlightOn(state)
    self.flashlightOn = state
end

function Marine:GetFlashlightOn()
    return self.flashlightOn
end

function Marine:GetInventorySpeedScalar()
    return 1 - self:GetWeaponsWeight()
end

function Marine:GetCrouchSpeedScalar()
    return Player.kCrouchSpeedScalar
end

function Marine:GetMaxSpeed(possible)

    if possible then
        return Marine.kRunMaxSpeed
    end

    local onInfestation = self:GetGameEffectMask(kGameEffect.OnInfestation)
    local sprintingScalar = self:GetSprintingScalar()
    local maxSprintSpeed = ConditionalValue(onInfestation, Marine.kWalkMaxSpeed + (Marine.kRunInfestationMaxSpeed - Marine.kWalkMaxSpeed)*sprintingScalar, Marine.kWalkMaxSpeed + (Marine.kRunMaxSpeed - Marine.kWalkMaxSpeed)*sprintingScalar)
    local maxSpeed = ConditionalValue(self:GetIsSprinting(), maxSprintSpeed, Marine.kWalkMaxSpeed)
    
    // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar() + .17

    // Take into account crouching
    if not self:GetIsJumping() then
        maxSpeed = ( 1 - self:GetCrouchAmount() * self:GetCrouchSpeedScalar() ) * maxSpeed
    end

    local adjustedMaxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * inventorySpeedScalar 
    //Print("Adjusted max speed => %.2f (without inventory: %.2f)", adjustedMaxSpeed, adjustedMaxSpeed / inventorySpeedScalar )
    return adjustedMaxSpeed
    
end

function Marine:OnClampSpeed(input, velocity)
end

function Marine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocityLength() / (Marine.kRunMaxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier()), 0, 1)
end

// Maximum speed a player can move backwards
function Marine:GetMaxBackwardSpeedScalar()
    return Marine.kWalkBackwardSpeedScalar
end

function Marine:GetAirMoveScalar()
    return 0.1
end

function Marine:GetAirFrictionForce()
    return 2 * self.slowAmount
end

function Marine:GetJumpHeight()
    return Player.kJumpHeight - Player.kJumpHeight * self.slowAmount * 0.8
end

function Marine:GetCanBeWeldedOverride()
    return not self:GetIsVortexed() and self:GetArmor() < self:GetMaxArmor(), false
end

function Marine:GetAcceleration()

    local acceleration = Marine.kAcceleration 
    
    if self:GetIsSprinting() then
        acceleration = Marine.kAcceleration + (Marine.kSprintAcceleration - Marine.kAcceleration) * self:GetSprintingScalar()
    end

    acceleration = acceleration * self:GetSlowSpeedModifier()
    acceleration = acceleration * self:GetInventorySpeedScalar()

    /*
    if self.timeLastSpitHit + Marine.kSpitSlowDuration > Shared.GetTime() then
        acceleration = acceleration * 0.5
    end
    */

    return acceleration * self:GetCatalystMoveSpeedModifier()

end

// Returns -1 to 1
function Marine:GetWeaponSwing()
    return self.horizontalSwing
end

function Marine:GetWeaponDropTime()
    return self.weaponDropTime
end

local marineTechButtons = { kTechId.Attack, kTechId.Move, kTechId.Defend  }
function Marine:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then
        techButtons = marineTechButtons
    end
    
    return techButtons
 
end

function Marine:GetCatalystFireModifier()
    return ConditionalValue(self:GetHasCatpackBoost(), CatPack.kAttackSpeedModifier, 1)
end

function Marine:GetCatalystMoveSpeedModifier()
    return ConditionalValue(self:GetHasCatpackBoost(), CatPack.kMoveSpeedScalar, 1)
end

function Marine:GetChatSound()
    return Marine.kChatSound
end

function Marine:GetDeathMapName()
    return MarineSpectator.kMapName
end

// Returns the name of the primary weapon
function Marine:GetPlayerStatusDesc()

    local status = kPlayerStatus.Void
    
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end
    
    local weapon = self:GetWeaponInHUDSlot(1)
    if (weapon) then
        if (weapon:isa("GrenadeLauncher")) then
            return kPlayerStatus.GrenadeLauncher
        elseif (weapon:isa("Rifle")) then
            return kPlayerStatus.Rifle
        elseif (weapon:isa("Shotgun")) then
            return kPlayerStatus.Shotgun
        elseif (weapon:isa("Flamethrower")) then
            return kPlayerStatus.Flamethrower
        end
    end
    
    return status
end

function Marine:GetCanDropWeapon(weapon, ignoreDropTimeLimit)

    if not weapon then
        weapon = self:GetActiveWeapon()
    end
    
    if weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() then
    
        // Don't drop weapons too fast.
        if ignoreDropTimeLimit or (Shared.GetTime() > (self.timeOfLastDrop + kDropWeaponTimeLimit)) then
            return true
        end
        
    end
    
    return false
    
end

// Do basic prediction of the weapon drop on the client so that any client
// effects for the weapon can be dealt with.
function Marine:Drop(weapon, ignoreDropTimeLimit, ignoreReplacementWeapon)

    local activeWeapon = self:GetActiveWeapon()
    
    if not weapon then
        weapon = activeWeapon
    end
    
    if self:GetCanDropWeapon(weapon, ignoreDropTimeLimit) then
    
        if weapon == activeWeapon then
            self:SelectNextWeapon()
        end
        
        weapon:OnPrimaryAttackEnd(self)
        
        if Server then
        
            self:RemoveWeapon(weapon)
            
            local weaponSpawnCoords = self:GetAttachPointCoords(Weapon.kHumanAttachPoint)
            weapon:SetCoords(weaponSpawnCoords)
            
        end
        
        // Tell weapon not to be picked up again for a bit
        weapon:Dropped(self)
        
        // Set activity end so we can't drop like crazy
        self.timeOfLastDrop = Shared.GetTime() 
        
        if Server then
        
            if ignoreReplacementWeapon ~= true and weapon.GetReplacementWeaponMapName then
            
                self:GiveItem(weapon:GetReplacementWeaponMapName(), false)
                // the client expects the next weapon is going to be selected (does not know about the replacement).
                self:SelectNextWeaponInDirection(1)
                
            end
            
        end
        
        return true
        
    end
    
    return false
    
end

function Marine:OnStun()

    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon then
        activeWeapon:OnHolster(self)
    end
    
end

function Marine:OnStunEnd()

    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon then
        activeWeapon:OnDraw(self)
    end
    
end

function Marine:OnHitGroundStunned()

    if Server then
        StartSoundEffectOnEntity(Marine.kHitGroundStunnedSound, self)
    end
    
end

function Marine:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

function Marine:OnWeldOverride(doer, elapsedTime)

    if self:GetArmor() < self:GetMaxArmor() then
    
        local addArmor = Marine.kArmorWeldRate * elapsedTime
        self:SetArmor(self:GetArmor() + addArmor)
        
    end
    
end

function Marine:OnSpitHit(direction)

    if Server then
        self.timeLastSpitHit = Shared.GetTime()
        self.lastSpitDirection = direction  
    end

end

function Marine:GetCanChangeViewAngles()
    return not self:GetIsStunned()
end    

function Marine:GetPlayFootsteps()
    return self:GetVelocityLength() > .75 and self:GetIsOnGround() and self:GetIsAlive()
end

function Marine:OnUseTarget(target)

    local activeWeapon = self:GetActiveWeapon()

    if target and HasMixin(target, "Construct") and ( target:GetCanConstruct(self) or (target.CanBeWeldedByBuilder and target:CanBeWeldedByBuilder()) ) then
    
        if activeWeapon and activeWeapon:GetMapName() ~= Builder.kMapName then
            self:SetActiveWeapon(Builder.kMapName)
            self.weaponBeforeUse = activeWeapon:GetMapName()
        end
        
    else
        if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName and self.weaponBeforeUse then
            self:SetActiveWeapon(self.weaponBeforeUse)
        end    
    end

end

function Marine:OnUseEnd() 

    local activeWeapon = self:GetActiveWeapon()

    if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName and self.weaponBeforeUse then
        self:SetActiveWeapon(self.weaponBeforeUse)
    end

end

function Marine:OnUpdateAnimationInput(modelMixin)

    PROFILE("Marine:OnUpdateAnimationInput")
    
    Player.OnUpdateAnimationInput(self, modelMixin)
    
    if not self:GetIsJumping() and self:GetIsSprinting() then
        modelMixin:SetAnimationInput("move", "sprint")
    end
    
   if self:GetIsStunned() and self:GetRemainingStunTime() > 0.5 then
        modelMixin:SetAnimationInput("move", "stun")
    end

    modelMixin:SetAnimationInput("attack_speed", self:GetCatalystFireModifier())
    
end

function Marine:ModifyVelocity(input, velocity)

    Player.ModifyVelocity(self, input, velocity)
    
    if not self:GetIsOnGround() and input.move:GetLength() ~= 0 then
    
        local moveLengthXZ = velocity:GetLengthXZ()
        local previousY = velocity.y
        local adjustedZ = false
        local viewCoords = self:GetViewCoords()
        
        if input.move.x ~= 0  then
        
            local redirectedVelocityX = GetNormalizedVectorXZ(self:GetViewCoords().xAxis) * input.move.x
            redirectedVelocityX = redirectedVelocityX * input.time * Marine.kAirStrafeWeight + GetNormalizedVectorXZ(velocity)
            
            redirectedVelocityX:Normalize()            
            redirectedVelocityX:Scale(moveLengthXZ)
            redirectedVelocityX.y = previousY            
            VectorCopy(redirectedVelocityX,  velocity)
            
        end
        
    end
    
end

function Marine:OnProcessMove(input)

    if Server then
    
        self.ruptured = Shared.GetTime() - self.timeRuptured < Rupture.kDuration
        self.interruptAim  = Shared.GetTime() - self.interruptStartTime < Gore.kAimInterruptDuration
        self.catpackboost = Shared.GetTime() - self.timeCatpackboost < CatPack.kDuration
        
        if self.unitStatusPercentage ~= 0 and self.timeLastUnitPercentageUpdate + 2 < Shared.GetTime() then
            self.unitStatusPercentage = 0
        end    
        
        if self.poisoned then
        
            if self:GetIsAlive() and self.timeLastPoisonDamage + 1 < Shared.GetTime() then
            
                local attacker = Shared.GetEntity(self.lastPoisonAttackerId)
            
                local currentHealth = self:GetHealth()
                local poisonDamage = kBitePoisonDamage
                
                // never kill the marine with poison only
                if currentHealth - poisonDamage < kPoisonDamageThreshhold then
                    poisonDamage = math.max(0, currentHealth - kPoisonDamageThreshhold)
                end
                
                self:DeductHealth(poisonDamage, attacker, nil, true)
                self.timeLastPoisonDamage = Shared.GetTime()   
                
            end
            
            if self.timePoisoned + kPoisonBiteDuration < Shared.GetTime() then
            
                self.timePoisoned = 0
                self.poisoned = false
                
            end
            
        end
        
    end
    
    Player.OnProcessMove(self, input)
    
end

function Marine:GetIsInterrupted()
    return self.interruptAim
end

function Marine:OnUpdateCamera(deltaTime)

    if self:GetIsStunned() then
        self:SetDesiredCameraYOffset(-1.3)
    else
        Player.OnUpdateCamera(self, deltaTime)
    end

end

function Marine:GetHasCatpackBoost()
    return self.catpackboost
end

// dont allow marines to me chain stomped. this gives them breathing time and the onos needs to time the stomps instead of spamming
// and being able to permanently disable the marine
function Marine:GetIsStunAllowed()
    return not self.timeLastStun or self.timeLastStun + kDisruptMarineTimeout < Shared.GetTime()
end

Shared.LinkClassToMap("Marine", Marine.kMapName, networkVars)
