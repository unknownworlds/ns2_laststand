// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTreeConstants.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kTechId = enum({
    
    'None',
    
    'VoteConcedeRound',
    
    'SpawnMarine', 'SpawnAlien', 'CollectResources',
    
    // General orders and actions ("Default" is right-click)
    'Default', 'Move', 'Attack', 'Build', 'Construct', 'Cancel', 'Recycle', 'Weld', 'AutoWeld', 'Stop', 'SetRally', 'SetTarget', 'Follow',
    // special mac order (follows the target, welds the target as priority and others in range)
    'FollowAndWeld',
    // Alien specific orders
    'AlienMove', 'AlienAttack', 'AlienConstruct', 'Heal', 'AutoHeal',
    
    // Commander menus for selected units
    'RootMenu', 'BuildMenu', 'AdvancedMenu', 'AssistMenu', 'MarkersMenu', 'UpgradesMenu', 'WeaponsMenu',
    
    // Robotics factory menus
    'RoboticsFactoryARCUpgradesMenu', 'RoboticsFactoryMACUpgradesMenu', 'UpgradeRoboticsFactory',

    'ReadyRoomPlayer', 
    
    // Doors
    'Door', 'DoorOpen', 'DoorClose', 'DoorLock', 'DoorUnlock',

    // Misc
    'ResourcePoint', 'TechPoint', 'SocketPowerNode', 'Mine',
    
    /////////////
    // Marines //
    /////////////
    
    // Marine classes + spectators
    'Marine', 'Exo', 'MarineCommander', 'JetpackMarine', 'Spectator', 'AlienSpectator',
    
    // Marine alerts (specified alert sound and text in techdata if any)
    'MarineAlertAcknowledge', 'MarineAlertNeedMedpack', 'MarineAlertNeedAmmo', 'MarineAlertNeedOrder', 'MarineAlertHostiles', 'MarineCommanderEjected', 'MACAlertConstructionComplete',    
    'MarineAlertSentryFiring', 'MarineAlertCommandStationUnderAttack',  'MarineAlertSoldierLost', 'MarineAlertCommandStationComplete',
    
    'MarineAlertInfantryPortalUnderAttack', 'MarineAlertSentryUnderAttack', 'MarineAlertStructureUnderAttack', 'MarineAlertExtractorUnderAttack', 'MarineAlertSoldierUnderAttack',
    
    'MarineAlertResearchComplete', 'MarineAlertManufactureComplete', 'MarineAlertUpgradeComplete', 'MarineAlertOrderComplete', 'MarineAlertWeldingBlocked', 'MarineAlertMACBlocked', 'MarineAlertNotEnoughResources', 'MarineAlertObjectiveCompleted', 'MarineAlertConstructionComplete',
    
    // Marine orders 
    'Defend',
    
    // Special tech
    'TwoCommandStations', 'ThreeCommandStations',

    // Marine tech 
    'CommandStation', 'MAC', 'Armory', 'InfantryPortal', 'Extractor', 'Sentry', 'ARC',
    'Scan', 'AmmoPack', 'MedPack', 'CatPack', 'CatPackTech', 'PowerPoint', 'AdvancedArmoryUpgrade', 'Observatory', 'Detector', 'DistressBeacon', 'PhaseGate', 'RoboticsFactory', 'ARCRoboticsFactory', 'ArmsLab',
    'PowerPack', 'SentryBattery', 'PrototypeLab', 'AdvancedArmory',
    
    // Weapon tech
    'RifleUpgradeTech', 'ShotgunTech', 'GrenadeLauncherTech', 'FlamethrowerTech', 'FlamethrowerAltTech', 'WelderTech', 'MinesTech',
    'DropWelder', 'DropMines', 'DropShotgun', 'DropGrenadeLauncher', 'DropFlamethrower',
    'DropDualMiniExo', 'DropDualRailExo', 'DropClawRailExo',
    'DropMedPack', 'DropAmmoPack', 'DropSentry',
    
    // Marine buys
    'RifleUpgrade', 'FlamethrowerAlt',
    
    // Research 
    'PhaseTech', 'MACSpeedTech', 'MACEMPTech', 'ARCArmorTech', 'ARCSplashTech', 'JetpackTech', 'ExosuitTech',
    'DualMinigunTech', 'DualMinigunExosuit',
    'ClawRailgunTech', 'ClawRailgunExosuit',
    'DualRailgunTech', 'DualRailgunExosuit',
    'DropJetpack', 'DropExosuit',
    
    // MAC (build bot) abilities
    'MACEMP', 'Welding',
    
    // Weapons 
    'Rifle', 'Pistol', 'Shotgun', 'Claw', 'Minigun', 'Railgun', 'GrenadeLauncher', 'Flamethrower', 'Axe', 'LayMines', 'Welder', 'BuildSentry',
    
    // Armor
    'Jetpack', 'JetpackFuelTech', 'JetpackArmorTech', 'Exosuit', 'ExosuitLockdownTech', 'ExosuitUpgradeTech',
    
    // Marine upgrades
    'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
    
    // Activations
    'ARCDeploy', 'ARCUndeploy',
    
    // Commander abilities
    'NanoShield',
    
    ////////////
    // Aliens //
    ////////////

    // Alien lifeforms 
    'Skulk', 'Gorge', 'Lerk', 'Fade', 'Onos', "AlienCommander", "AllAliens", "Hallucination",
    
    // Special tech
    'TwoHives', 'ThreeHives', 'UpgradeToCragHive', 'UpgradeToShadeHive', 'UpgradeToShiftHive',
    
    // Alien abilities (not all are needed, only ones with damage types)
    'Bite', 'LerkBite', 'Parasite',  'Spit', 'BuildAbility', 'Spray', 'Spores', 'HydraSpike', 'Swipe', 'StabBlink', 'Gore', 'Smash',
    'Babbler', 'BabblerEgg',

    
    // upgradeable alien abilities (need to be unlocked)
    'LifeFormMenu',
    'BileBomb', 'GorgeTunnelTech', 'WebTech', 'Leap', 'Blink', 'Stomp', 'BoneShield', 'Spikes', 'Umbra', 'PoisonDart', 'Xenocide', 'Vortex', 'PrimalScream', 'BabblerAbility',

    // Alien structures 
    'Hive', 'HiveHeal', 'CragHive', 'ShadeHive', 'ShiftHive','Harvester', 'Drifter', 'Egg', 'Embryo', 'Hydra', 'Cyst', 'Clog', 'GorgeTunnel', 'Web',
    'GorgeEgg', 'LerkEgg', 'FadeEgg', 'OnosEgg',
    
    // Infestation upgrades
    'HealingBed', 'MucousMembrane', 'BacterialReceptors',

    // Upgrade buildings and abilities (structure, upgraded structure, passive, triggered, targeted)
    'Shell', 'Crag', 'CragHeal',
    'Whip', 'EvolveBombard', 'WhipBombard', 'WhipBombardCancel', 'WhipBomb', 'GrenadeWhack',
    'Spur', 'Shift', 'EvolveEcho', 'ShiftHatch', 'ShiftEcho', 'ShiftEnergize', 
    'Veil', 'Shade', 'EvolveHallucinations', 'ShadeDisorient', 'ShadeCloak', 'ShadePhantomMenu', 'ShadePhantomStructuresMenu',
    'UpgradeCeleritySpur', 'CeleritySpur', 'UpgradeAdrenalineSpur', 'AdrenalineSpur', 'UpgradeHyperMutationSpur', 'HyperMutationSpur',
    'UpgradeSilenceVeil', 'SilenceVeil', 'UpgradeCamouflageVeil', 'CamouflageVeil', 'UpgradeAuraVeil', 'AuraVeil', 'UpgradeFeintVeil', 'FeintVeil',
    'UpgradeRegenerationShell', 'RegenerationShell', 'UpgradeCarapaceShell', 'CarapaceShell',
    'DrifterCamouflage',
    
    // echo menu
    'TeleportHydra', 'TeleportWhip', 'TeleportCrag', 'TeleportShade', 'TeleportShift', 'TeleportVeil', 'TeleportSpur', 'TeleportShell', 'TeleportHive', 'TeleportEgg',
    
    // Whip movement
    'WhipRoot', 'WhipUnroot',
    
    // Alien abilities and upgrades
    'Carapace', 'Regeneration', 'Aura', 'Silence', 'Feint', 'Camouflage', 'Celerity', 'Adrenaline', 'HyperMutation',  
    
    // Alien alerts
    'AlienAlertNeedMist', 'AlienAlertNeedEnzyme', 'AlienAlertNeedHealing', 'AlienAlertStructureUnderAttack', 'AlienAlertHiveUnderAttack', 'AlienAlertHiveDying', 'AlienAlertHarvesterUnderAttack',
    'AlienAlertLifeformUnderAttack', 'AlienAlertGorgeBuiltHarvester', 'AlienCommanderEjected',
    'AlienAlertOrderComplete',
    'AlienAlertNotEnoughResources', 'AlienAlertResearchComplete', 'AlienAlertManufactureComplete', 'AlienAlertUpgradeComplete', 'AlienAlertHiveComplete',
    
    // Pheromones
    'ThreatMarker', 'LargeThreatMarker', 'NeedHealingMarker', 'WeakMarker', 'ExpandingMarker',
    
    // Infestation
    'Infestation',
    
    // Commander abilities
    'BoneWall', 'NutrientMist', 'HealWave', 'CragUmbra', 'ShadeInk', 'EnzymeCloud', 'Rupture',
    
    // Alien Commander hallucinations
    'HallucinateDrifter', 'HallucinateSkulk', 'HallucinateGorge', 'HallucinateLerk', 'HallucinateFade', 'HallucinateOnos',
    'HallucinateHive', 'HallucinateWhip', 'HallucinateShade', 'HallucinateCrag', 'HallucinateShift', 'HallucinateHarvester', 'HallucinateHydra',
    
    // Voting commands
    'VoteDownCommander1', 'VoteDownCommander2', 'VoteDownCommander3',
    
    'GameStarted',
    
    'DeathTrigger',

    // Maximum index
    'Max'
    
    })

// Increase techNode network precision if more needed
kTechIdMax  = kTechId.Max

// Tech types
kTechType = enum({ 'Invalid', 'Order', 'Research', 'Upgrade', 'Action', 'Buy', 'Build', 'EnergyBuild', 'Manufacture', 'Activation', 'Menu', 'EnergyManufacture', 'PlasmaManufacture', 'Special', 'Passive' })

// Button indices
kRecycleCancelButtonIndex   = 12
kMarineUpgradeButtonIndex   = 5
kAlienBackButtonIndex       = 8

