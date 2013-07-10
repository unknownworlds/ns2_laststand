// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BalanceMisc.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kWorkersPerTechpoint = 5

kPoisonDamageThreshhold = 5

// Time spawning alien player must be in egg before hatching
kAlienSpawnTime = 2
kInitialMACs = 0
// Construct at a slower rate than players
kMACConstructEfficacy = .3
kFlamethrowerAltTechResearchCost = 20
kDefaultFov = 90
kEmbryoFov = 100
kSkulkFov = 105
kGorgeFov = 95
kLerkFov = 100
kFadeFov = 90
kOnosFov = 90
kExoFov = 95

kResearchMod = 1

kMinSupportedRTs = 0
kRTsPerTechpoint = 3

kEMPBlastEnergyDamage = 50

kEnzymeAttackSpeed = 1.25

// reduces all upgrade / life form costs
kHyperMutationCostScalar = 1 // 0.8

kHallucinationHealthFraction = 0.2
kHallucinationArmorFraction = 0
kHallucinationMaxHealth = 600

// set to -1 for no time limit
kParasiteDuration = 30

// celerity kicks in after X seconds from last attack
kCelerityStart = .5
kCelerityBuildUpDuration = .5
kCelerityRampDownDuration = .2
kCeleritySpeedModifier = 0.3
kSkulkCeleritySpeedModifier = 0.3
kGorgeCeleritySpeedModifier = 0.7
kLerkCeleritySpeedModifier = 0.2
kFadeCeleritySpeedModifier = 0.45
kOnosCeleritySpeedModifier = 0.3

// no speed bonus as default
kAlienDefaultInfestationSpeedBonus = 0.0
kSkulkInfestationSpeedBonus = 0.0
kGorgeInfestationSpeedBonus = 0.0
kLerkInfestationSpeedBonus = 0.0
kFadeInfestationSpeedBonus = 0.0
kOnosInfestationSpeedBonus = 0.0

kHydrasPerHive = 3
kClogsPerHive = 10
kNumWebsPerGorge = 10
kCystInfestDuration = 37.5

kSentriesPerBattery = 3

kDefaultStructureCost = 10
kStructureCircleRange = 4
kInfantryPortalUpgradeCost = 10
kInfantryPortalAttachRange = 10
kArmoryWeaponAttachRange = 10
// Minimum distance that initial IP spawns away from team location
kInfantryPortalMinSpawnDistance = 4
kItemStayTime = 9999    // NS1
kInfestCost = 10
// For power points
kMarineRepairHealthPerSecond = 600
// The base weapons need to cost a small amount otherwise they can
// be spammed.
kRifleCost = 0
kPistolCost = 0
kAxeCost = 0
// % gain every second whether in use or not
kInitialDrifters = 0
kSkulkCost = 0
kBuildHydraDelay = .5
kLerkWeaponSwitchTime = .5
kMACSpeedAmount = .5
// How close should MACs/Drifters fly to operate on target
kCommandStationEngagementDistance = 4
kInfantryPortalEngagementDistance = 2
kArmoryEngagementDistance = 3
kArmsLabEngagementDistance = 3
kExtractorEngagementDistance = 2
kObservatoryEngagementDistance = 1
kPhaseGateEngagementDistance = 2
kRoboticsFactorEngagementDistance = 5
kARCEngagementDistance = 2
kSentryEngagementDistance = 2
kPlayerEngagementDistance = 1
kExoEngagementDistance = 1.5
kOnosEngagementDistance = 2
kLerkSporeShootRange = 10

// entrance and exit
kNumGorgeTunnels = 2

// maturation time for alien buildings
kHiveMaturationTime = 180
kHarvesterMaturationTime = 150
kWhipMaturationTime = 120
kCragMaturationTime = 120
kShiftMaturationTime = 90
kShadeMaturationTime = 120
kVeilMaturationTime = 60
kSpurMaturationTime = 60
kShellMaturationTime = 60
kCystMaturationTime = 90
kHydraMaturationTime = 140
kEggMaturationTime = 100
kTunnelEntranceMaturationTime = 120

kNutrientMistMaturitySpeedup = 3

kMinBuildTimePerHealSpray = .25
kMaxBuildTimePerHealSpray = 0.7

// Marine buy costs
kFlamethrowerAltCost = 5

// Scanner sweep
kScanDuration = 10
kScanRadius = 20

// Distress Beacon (from NS1)
kDistressBeaconRange = 15
kDistressBeaconTime = 3

kEnergizeRange = 15
// per stack
kEnergizeEnergyIncrease = .25
kStructureEnergyPerEnergize = 0.15
kPlayerEnergyPerEnergize = 15
kEnergizeUpdateRate = 1

kEchoRange = 8

kSprayDouseOnFireChance = .5

// Players get energy back at this rate when on fire 
kOnFireEnergyRecuperationScalar = .6

// Infestation
kStructureInfestationRadius = 2
kHiveInfestationRadius = 20
kInfestationRadius = 7.5
kGorgeInfestationLifetime = 60
kMarineInfestationSpeedScalar = .1

kDamageVelocityScalar = 2.5

// Each upgrade costs this much extra evolution time
kUpgradeGestationTime = 2

// Cyst parent ranges, how far a cyst can support another cyst
//
// NOTE: I think the range is a bit long for kCystMaxParentRange, there will be gaps between the
// infestation patches if the range is > kInfestationRadius * 1.75 (about).
// 
kHiveCystParentRange = 15 // distance from a hive a cyst can be connected
kCystMaxParentRange = 15 // distance from a cyst another cyst can be placed
kCystRedeployRange = 6 // distance from existing Cysts that will cause redeployment

// Damage over time that all cysts take when not connected
kCystUnconnectedDamage = 12

// Light shaking constants
kOnosLightDistance = 50
kOnosLightShakeDuration = .2
kLightShakeMaxYDiff = .05
kLightShakeBaseSpeed = 30
kLightShakeVariableSpeed = 30

// Egg Drop cost
kEggBuildCost = 2

// Jetpack
kJetpackUseFuelRate = .25
kJetpackUpgradeUseFuelRate = .15
kJetpackReplenishFuelRate = .35

// Mines
kNumMines = 3
kMineActiveTime = 4
kMineAlertTime = 8
kMineDetonateRange = 4
kMineTriggerRange = 1.5

// Onos
kGoreMarineFallTime = 1
kDisruptTime = 5

kEncrustMaxLevel = 5
kSpitObscureTime = 8
kGorgeCreateDistance = 6.5

kMaxTimeToSprintAfterAttack = .2

// Welding variables
// Also: MAC.kRepairHealthPerSecond
// Also: Exo -> kArmorWeldRate
kWelderPowerRepairRate = 220
kBuilderPowerRepairRate = 110
kWelderSentryRepairRate = 150
kPlayerWeldRate = 30
kStructureWeldRate = 90
kDoorWeldTime = 15

kHatchCooldown = 5
kEggsPerHatch = 2

kHealingBedStructureRegen     = 5 // Health per second

kAlienRegenerationTime = 1

kAlienInnateRegenerationPercentage  = 0.02
kAlienMinInnateRegeneration = 1
kAlienMaxInnateRegeneration = 20

// used for hive healing and regeneration upgrade
kAlienRegenerationPercentage = 0.08
kAlienMinRegeneration = 10
kAlienMaxRegeneration = 60

// when in combat self healing (innate healing or through upgrade) is multiplied with this value
kAlienRegenerationCombatModifier = 0.2

kCarapaceSpeedReduction = 0.0
kSkulkCarapaceSpeedReduction = 0 //0.08
kGorgeCarapaceSpeedReduction = 0 //0.08
kLerkCarapaceSpeedReduction = 0 //0.15
kFadeCarapaceSpeedReduction = 0 //0.15
kOnosCarapaceSpeedReduction = 0 //0.12

// Umbra blocks 1 out of this many bullet
kUmbraBlockRate = 2
// Carries the umbra cloud for x additional seconds
kUmbraRetainTime = .5

kBellySlideCost = 25
kLerkFlapEnergyCost = 3
kFadeShadowStepCost = 10
kChargeEnergyCost = 40 // per second

kAbilityMaxEnergy = 100
kAdrenalineAbilityMaxEnergy = 200

kOnosAcceleration = 55
kOnosBaseSpeed = 2
kOnosExtraSpeed = 7
kOnosSpeedScalar = 3
kOnosReduceSpeedScalar = 5
kOnosStompMaxVelocity = .25
kOnosActiveAmount = .75 // Cory likes .5
kOnosInactiveChangeSpeed = 2
kOnosMinActiveViewModelParam = .6
kOnosBackBackwardSpeedScalar = .2

kPistolWeight = 0.09
kRifleWeight = 0.13
kGrenadeLauncherWeight = 0.2
kFlamethrowerWeight = 0.25
kShotgunWeight = 0.14

// set to -1 to disable or a positive number
kResourcesPerNode = -1

kDropStructureEnergyCost = 20

kMinWebLength = 0.5
kMaxWebLength = 8
