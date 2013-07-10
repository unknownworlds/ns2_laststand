// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechData.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A "database" of attributes for all units, abilities, structures, weapons, etc. in the game.
// Shared between client and server.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set up structure data for easy use by Server.lua and model classes
// Store whatever data is necessary here and use LookupTechData to access
// Store any data that needs to used on both client and server here
// Lookup by key with LookupTechData()
kTechDataId                             = "id"
// Localizable string describing tech node
kTechDataDisplayName                    = "displayname"
// For alien traits and marine upgrades, these distinct character codes will be stored in sponitor's database
kTechDataSponitorCode                   = "sponitorchar"
// Include and set to false if not meant to display on commander UI "enables: "
kTechIDShowEnables                      = "showenables"
kTechDataMapName                        = "mapname"
kTechDataModel                          = "model"
// TeamResources, resources or energy
kTechDataCostKey                        = "costkey"
kTechDataBuildTime                      = "buildtime"
// If an entity has this field, it's treated as a research node instead of a build node
kTechDataResearchTimeKey                = "researchTime"
kTechDataMaxHealth                      = "maxhealth"
kTechDataMaxArmor                       = "maxarmor"
kTechDataDamageType                     = "damagetype"
// Class that structure must be placed on top of (resource towers on resource points)
// If adding more attach classes, add them to GetIsAttachment(). When attaching entities
// to this attach class, ignore class.
kStructureAttachClass                   = "attachclass"
// Structure must be placed within kStructureAttachRange of this class, but it isn't actually attached.
// This can be a table of strings as well. Near class must have the same team number.
kStructureBuildNearClass                = "buildnearclass"
// Structure attaches to wall/roof
kStructureBuildOnWall                   = "buildonwall"
// If specified along with attach class, this entity can only be built within this range of an attach class (infantry portal near Command Station)
// If specified, you must also specify the tech id of the attach class.
// This can be a table of ids as well.
kStructureAttachRange                   = "attachrange"
// If specified, this entity can only be built if there is a powered attach class within kStructureAttachRange.
kStructureAttachRequiresPower           = "attachrequirespower"
// If specified, draw a range indicator for the commander when selected.
kVisualRange                            = "visualrange"
// set to true when attach structure is not required but optional
kTechDataAttachOptional                   = "attachoptional"
// The tech id of the attach class 
kStructureAttachId                      = "attachid"
// If specified, this tech is an alien class that can be gestated into
kTechDataGestateName                    = "gestateclass"
// If specified, how much time it takes to evolve into this class
kTechDataGestateTime                    = "gestatetime"
// If specified, object spawns this far off the ground
kTechDataSpawnHeightOffset              = "spawnheight"
// All player tech ids should have this, nothing else uses it. Pre-computed by looking at the min and max extents of the model, 
// adding their absolute values together and dividing by 2. 
kTechDataMaxExtents                     = "maxextents"
// If specified, is amount of energy structure starts with
kTechDataInitialEnergy                  = "initialenergy"
// If specified, is max energy structure can have
kTechDataMaxEnergy                      = "maxenergy"
// Menu priority. If more than one techId is specified for the same spot in a menu, use the one with the higher priority.
// If a tech doesn't specify a priority, treat as 0. If all priorities are tied, show none of them. This is how Starcraft works (see siege behavior).
kTechDataMenuPriority                   = "menupriority"
// if an alert with higher priority is trigger the interval should be ignored
kTechDataAlertPriority                  = "alertpriority"
// Indicates that the tech node is an upgrade of another tech node, so that the previous tech is still active (ie, if you upgrade a hive
// to an advanced hive, your team still has "hive" technology.
kTechDataUpgradeTech                    = "upgradetech"
// Set true if entity should be rotated before being placed
kTechDataSpecifyOrientation             = "specifyorientation"
// manipulate build coords in a custom function
kTechDataOverrideCoordsMethod           = "overridecoordsmethod"
// Point value for killing structure
kTechDataPointValue                     = "pointvalue"
// Set to false if not yet implemented, for displaying differently for not enabling
kTechDataImplemented                    = "implemented"
// Set to localizable string that will be added to end of description indicating date it went in. 
kTechDataNew                            = "new"
// For setting grow parameter on alien structures
kTechDataGrows                          = "grows"
// Commander hotkey. Not currently used.
kTechDataHotkey                         = "hotkey"
// Alert sound name
kTechDataAlertSound                     = "alertsound"
// Alert text for commander HUD
kTechDataAlertText                      = "alerttext"
// Alert type. These are the types in CommanderUI_GetDynamicMapBlips. "Request" alert types count as player alert requests and show up on the commander HUD as such.
kTechDataAlertType                      = "alerttype"
// Alert scope
kTechDataAlertTeam                      = "alertteam"
// Alert should ignore distance for triggering
kTechDataAlertIgnoreDistance            = "alertignoredistance"
// Alert should also trigger a team message.
kTechDataAlertSendTeamMessage           = "alertsendteammessage"
// Sound that plays for Comm and ordered players when given this order
kTechDataOrderSound                     = "ordersound"
// Don't send alert to originator of this alert 
kTechDataAlertOthersOnly                = "alertothers"
// Usage notes, caveats, etc. for use in commander tooltip (localizable)
kTechDataTooltipInfo                    = "tooltipinfo"
// Quite the same as tooltip, but shorter
kTechDataHint                           = "hintinfo"
// Indicate tech id that we're replicating
// Engagement distance - how close can unit get to it before it can repair or build it
kTechDataEngagementDistance             = "engagementdist"
// Can only be built on infestation
kTechDataRequiresInfestation            = "requiresinfestation"
// Cannot be built on infestation (cannot be specified with kTechDataRequiresInfestation)
kTechDataNotOnInfestation               = "notoninfestation"
// Special ghost-guide method. Called with commander as argument, returns a map of entities with ranges to lit up.
kTechDataGhostGuidesMethod               = "ghostguidesmethod"
// Special requirements for building. Called with techId, the origin and normal for building location and the commander. Returns true if the special requirement is met.
kTechDataBuildRequiresMethod            = "buildrequiresmethod"
// Allows dropping onto other entities
kTechDataAllowStacking                 = "allowstacking"
// will ignore other entities when searching for spawn position
kTechDataCollideWithWorldOnly          = "collidewithworldonly"
// ignore pathing mesh when placing entities
kTechDataIgnorePathingMesh     = "ignorepathing"
// used for gorges
kTechDataMaxAmount = "maxstructureamount"
// requires power
kTechDataRequiresPower = "requirespower"
// for drawing ghost model, client
kTechDataGhostModelClass = "ghostmodelclass"
// for gorge build, can consume when dropping
kTechDataAllowConsumeDrop = "allowconsumedrop"
// true when the host structure requires to be mature
kTechDataRequiresMature = "requiresmature"
// only useable once every X seconds
kTechDataCooldown = "coldownduration"
// ignore any alert interval
kTechDataAlertIgnoreInterval = "ignorealertinterval"
// used for alien upgrades
kTechDataCategory = "techcategory"
// custom message displayed for the commander when build method failed
kTechDataBuildMethodFailedMessage = "commanderbuildmethodfailed"
kTechDataAbilityType = "abilitytype"

function BuildTechData()
    
    local techData = { 

        // Orders
        { [kTechDataId] = kTechId.Move,                  [kTechDataDisplayName] = "MOVE", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MOVE_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.Attack,                [kTechDataDisplayName] = "ATTACK", [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "ATTACK_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName},
        { [kTechDataId] = kTechId.Build,                 [kTechDataDisplayName] = "BUILD", [kTechDataTooltipInfo] = "BUILD_TOOLTIP"},
        { [kTechDataId] = kTechId.Construct,             [kTechDataDisplayName] = "CONSTRUCT", [kTechDataOrderSound] = MarineCommander.kBuildStructureSound},
        { [kTechDataId] = kTechId.Cancel,                [kTechDataDisplayName] = "CANCEL", [kTechDataHotkey] = Move.ESC},
        { [kTechDataId] = kTechId.FollowAndWeld,         [kTechDataDisplayName] = "FOLLOWANDWELD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "FOLLOWANDWELD_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kWeldOrderSound},    
        { [kTechDataId] = kTechId.Weld,                  [kTechDataDisplayName] = "WELD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "WELD_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kWeldOrderSound},
        { [kTechDataId] = kTechId.AutoWeld,              [kTechDataDisplayName] = "WELD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "WELD_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kWeldOrderSound},
        { [kTechDataId] = kTechId.Stop,                  [kTechDataDisplayName] = "STOP", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "STOP_TOOLTIP"},
        { [kTechDataId] = kTechId.SetRally,              [kTechDataDisplayName] = "SET_RALLY_POINT", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "RALLY_POINT_TOOLTIP"},
        { [kTechDataId] = kTechId.SetTarget,             [kTechDataDisplayName] = "SET_TARGET", [kTechDataHotkey] = Move.T, [kTechDataTooltipInfo] = "SET_TARGET_TOOLTIP"},
        
        { [kTechDataId] = kTechId.Welding,           [kTechDataDisplayName] = "WELDING", [kTechDataTooltipInfo] = "WELDING_TOOLTIP", },
        
        { [kTechDataId] = kTechId.AlienMove,             [kTechDataDisplayName] = "MOVE", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MOVE_TOOLTIP", [kTechDataOrderSound] = AlienCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.AlienAttack,           [kTechDataDisplayName] = "ATTACK", [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "ATTACK_TOOLTIP", [kTechDataOrderSound] = AlienCommander.kAttackOrderSoundName},
        { [kTechDataId] = kTechId.AlienConstruct,        [kTechDataDisplayName] = "CONSTRUCT", [kTechDataOrderSound] = AlienCommander.kBuildStructureSound},
        { [kTechDataId] = kTechId.Heal,                  [kTechDataDisplayName] = "HEAL", [kTechDataOrderSound] = AlienCommander.kHealTarget},
        { [kTechDataId] = kTechId.AutoHeal,              [kTechDataDisplayName] = "HEAL", [kTechDataOrderSound] = AlienCommander.kHealTarget},
        
        { [kTechDataId] = kTechId.SpawnMarine,       [kTechDataDisplayName] = "SPAWN_MARINE", [kTechDataTooltipInfo] = "SPAWN_MARINE_TOOLTIP", },
        { [kTechDataId] = kTechId.SpawnAlien,       [kTechDataDisplayName] = "SPAWN_ALIEN", [kTechDataTooltipInfo] = "SPAWN_ALIEN_TOOLTIP", },
        { [kTechDataId] = kTechId.CollectResources,       [kTechDataDisplayName] = "COLLECT_RESOURCES", [kTechDataTooltipInfo] = "COLLECT_RESOURCES_TOOLTIP", },
        { [kTechDataId] = kTechId.Detector,       [kTechDataDisplayName] = "DETECTOR", [kTechDataTooltipInfo] = "DETECTOR_TOOLTIP", },
        
        // Ready room player is the default player, hence the ReadyRoomPlayer.kMapName
        { [kTechDataId] = kTechId.ReadyRoomPlayer,        [kTechDataDisplayName] = "READY_ROOM_PLAYER", [kTechDataMapName] = LSReadyRoomPlayer.kMapName, [kTechDataModel] = Marine.kModelName, [kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents) },
        
        // Spectators classes.
        { [kTechDataId] = kTechId.Spectator,              [kTechDataModel] = "" },
        { [kTechDataId] = kTechId.AlienSpectator,         [kTechDataModel] = "" },
        
        // Marine classes
        { [kTechDataId] = kTechId.Marine,      [kTechDataDisplayName] = "MARINE", [kTechDataMapName] = Marine.kMapName, [kTechDataModel] = Marine.kModelName, [kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), [kTechDataMaxHealth] = Marine.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataPointValue] = kMarinePointValue},
        { [kTechDataId] = kTechId.Exo,              [kTechDataDisplayName] = "EXOSUIT", [kTechDataTooltipInfo] = "EXOSUIT_TOOLTIP", [kTechDataMapName] = Exo.kMapName, [kTechDataMaxExtents] = Vector(Exo.kXZExtents, Exo.kYExtents, Exo.kXZExtents), [kTechDataMaxHealth] = kExosuitHealth, [kTechDataEngagementDistance] = kExoEngagementDistance, [kTechDataPointValue] = kExosuitPointValue},
        { [kTechDataId] = kTechId.MarineCommander,     [kTechDataDisplayName] = "MARINE_COMMANDER", [kTechDataMapName] = MarineCommander.kMapName, [kTechDataModel] = ""},
        { [kTechDataId] = kTechId.JetpackMarine,   [kTechDataHint] = "JETPACK_HINT",    [kTechDataDisplayName] = "JETPACK", [kTechDataMapName] = JetpackMarine.kMapName, [kTechDataModel] = JetpackMarine.kModelName, [kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), [kTechDataMaxHealth] = JetpackMarine.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataPointValue] = kMarinePointValue},
        
        // Marine orders
        { [kTechDataId] = kTechId.Defend,             [kTechDataDisplayName] = "DEFEND", [kTechDataOrderSound] = MarineCommander.kDefendTargetSound},

        // Menus
        { [kTechDataId] = kTechId.RootMenu,              [kTechDataDisplayName] = "SELECT", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "SELECT_TOOLTIP"},
        { [kTechDataId] = kTechId.BuildMenu,             [kTechDataDisplayName] = "BUILD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "BUILD_TOOLTIP"},
        { [kTechDataId] = kTechId.AdvancedMenu,          [kTechDataDisplayName] = "ADVANCED", [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "ADVANCED_TOOLTIP"},
        { [kTechDataId] = kTechId.AssistMenu,            [kTechDataDisplayName] = "ASSIST", [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] = "ASSIST_TOOLTIP"},
        { [kTechDataId] = kTechId.MarkersMenu,           [kTechDataDisplayName] = "MARKERS", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "PHEROMONE_TOOLTIP"},
        { [kTechDataId] = kTechId.UpgradesMenu,          [kTechDataDisplayName] = "UPGRADES", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "TEAM_UPGRADES_TOOLTIP"},
        { [kTechDataId] = kTechId.WeaponsMenu,           [kTechDataDisplayName] = "WEAPONS_MENU", [kTechDataTooltipInfo] = "WEAPONS_MENU_TOOLTIP"},

        // Marine menus
        { [kTechDataId] = kTechId.RoboticsFactoryARCUpgradesMenu,            [kTechDataDisplayName] = "ARC_UPGRADES", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.RoboticsFactoryMACUpgradesMenu,            [kTechDataDisplayName] = "MAC_UPGRADES", [kTechDataHotkey] = Move.P},
        
        { [kTechDataId] = kTechId.TwoCommandStations, [kTechDataDisplayName] = "TWO_COMMAND_STATIONS", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] = "TWO_COMMAND_STATIONS"},               
        { [kTechDataId] = kTechId.ThreeCommandStations, [kTechDataDisplayName] = "TWO_COMMAND_STATIONS", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] = "THREE_COMMAND_STATIONS"},               
        { [kTechDataId] = kTechId.TwoHives, [kTechDataDisplayName] = "TWO_HIVES", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] = "TWO_HIVES"},               
        { [kTechDataId] = kTechId.ThreeHives, [kTechDataDisplayName] = "THREE_HIVES", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] = "THREE_HIVES"},                
        
        // Misc.
        { [kTechDataId] = kTechId.PowerPoint,    [kTechDataHint] = "POWERPOINT_HINT",        [kTechDataMapName] = PowerPoint.kMapName,            [kTechDataDisplayName] = "POWER_NODE",  [kTechDataCostKey] = 0,   [kTechDataMaxHealth] = kPowerPointHealth, [kTechDataMaxArmor] = kPowerPointArmor, [kTechDataBuildTime] = kPowerPointBuildTime, [kTechDataPointValue] = kPowerPointPointValue, [kTechDataTooltipInfo] = "POWERPOINT_TOOLTIP"},        
        { [kTechDataId] = kTechId.SocketPowerNode,    [kTechDataDisplayName] = "SOCKET_POWER_NODE", [kTechDataCostKey] = kPowerNodeCost, [kTechDataBuildTime] = 0.1, },

        { [kTechDataId] = kTechId.ResourcePoint,   [kTechDataHint] = "RESOURCE_NOZZLE_TOOLTIP",      [kTechDataMapName] = ResourcePoint.kPointMapName,    [kTechDataDisplayName] = "RESOURCE_NOZZLE", [kTechDataModel] = ResourcePoint.kModelName},
        { [kTechDataId] = kTechId.TechPoint,     [kTechDataHint] = "TECH_POINT_HINT",        [kTechDataTooltipInfo] = "TECH_POINT_TOOLTIP", [kTechDataMapName] = TechPoint.kMapName,             [kTechDataDisplayName] = "TECH_POINT", [kTechDataModel] = TechPoint.kModelName},
        { [kTechDataId] = kTechId.Door,                  [kTechDataDisplayName] = "DOOR", [kTechDataTooltipInfo] = "DOOR_TOOLTIP", [kTechDataMapName] = Door.kMapName, [kTechDataMaxHealth] = kDoorHealth, [kTechDataMaxArmor] = kDoorArmor, [kTechDataPointValue] = kDoorPointValue },
        { [kTechDataId] = kTechId.DoorOpen,              [kTechDataDisplayName] = "OPEN_DOOR", [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "OPEN_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorClose,             [kTechDataDisplayName] = "CLOSE_DOOR", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "CLOSE_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorLock,              [kTechDataDisplayName] = "LOCK_DOOR", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "LOCKED_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorUnlock,            [kTechDataDisplayName] = "UNLOCK_DOOR", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "UNLOCK_DOOR_TOOLTIP"},
        
        // Marine Commander abilities    
        { [kTechDataId] = kTechId.NanoShield,    [kTechDataCooldown] = kNanoShieldCooldown,      [kTechDataAllowStacking] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataMapName] = NanoShield.kMapName,   [kTechDataDisplayName] = "NANO_SHIELD_DEFENSE", [kTechDataCostKey] = kNanoShieldCost, [kTechDataTooltipInfo] = "NANO_SHIELD_DEFENSE_TOOLTIP"},        
        { [kTechDataId] = kTechId.AmmoPack,              [kTechDataAllowStacking] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataMapName] = AmmoPack.kMapName,  [kTechDataDisplayName] = "AMMO_PACK",      [kTechDataCostKey] = kAmmoPackCost,            [kTechDataModel] = AmmoPack.kModelName, [kTechDataTooltipInfo] = "AMMO_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight },
        { [kTechDataId] = kTechId.MedPack,   [kTechDataCooldown] = kMedpackCooldown,  [kTechDataAllowStacking] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataMapName] = MedPack.kMapName,   [kTechDataDisplayName] = "MED_PACK",     [kTechDataCostKey] = kMedPackCost,             [kTechDataModel] = MedPack.kModelName,  [kTechDataTooltipInfo] = "MED_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight},
        { [kTechDataId] = kTechId.CatPack,               [kTechDataAllowStacking] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataMapName] = CatPack.kMapName,   [kTechDataDisplayName] = "CAT_PACK",      [kTechDataCostKey] = kCatPackCost,             [kTechDataModel] = CatPack.kModelName,  [kTechDataTooltipInfo] = "CAT_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight},
        { [kTechDataId] = kTechId.Scan,    [kTechDataCooldown] = kScanCooldown,            [kTechDataAllowStacking] = true, [kTechDataCollideWithWorldOnly] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataMapName] = Scan.kMapName,     [kTechDataDisplayName] = "SCAN",      [kTechDataHotkey] = Move.S,   [kTechDataCostKey] = kObservatoryScanCost, [kTechDataTooltipInfo] = "SCAN_TOOLTIP"},

        // Command station and its buildables
        { [kTechDataId] = kTechId.CommandStation, [kTechDataMaxExtents] = Vector(1.5, 1, 0.4), [kTechDataHint] = "COMMAND_STATION_HINT", [kTechDataAllowStacking] = true, [kStructureAttachClass] = "TechPoint", [kTechDataAttachOptional] = false, [kTechDataOverrideCoordsMethod] = OptionalAttachToFreeTechPoint, [kTechDataGhostModelClass] = "MarineGhostModel",  [kTechDataMapName] = CommandStation.kMapName,     [kTechDataDisplayName] = "COMMAND_STATION",  [kTechDataNotOnInfestation] = true,   [kTechDataBuildTime] = kCommandStationBuildTime, [kTechDataCostKey] = kCommandStationCost, [kTechDataModel] = CommandStation.kModelName,             [kTechDataMaxHealth] = kCommandStationHealth, [kTechDataMaxArmor] = kCommandStationArmor,      [kTechDataSpawnHeightOffset] = 0, [kTechDataEngagementDistance] = kCommandStationEngagementDistance, [kTechDataInitialEnergy] = kCommandStationInitialEnergy,      [kTechDataMaxEnergy] = kCommandStationMaxEnergy, [kTechDataPointValue] = kCommandStationPointValue, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "COMMAND_STATION_TOOLTIP"},       

        { [kTechDataId] = kTechId.Recycle,               [kTechDataDisplayName] = "RECYCLE", [kTechDataCostKey] = 0,    [kTechIDShowEnables] = false,       [kTechDataResearchTimeKey] = kRecycleTime, [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] =  "RECYCLE_TOOLTIP"},
        { [kTechDataId] = kTechId.MAC,        [kTechDataHint] = "MAC_HINT",           [kTechDataMapName] = MAC.kMapName,                      [kTechDataDisplayName] = "MAC",  [kTechDataMaxHealth] = MAC.kHealth, [kTechDataMaxArmor] = MAC.kArmor, [kTechDataCostKey] = kMACCost, [kTechDataResearchTimeKey] = kMACBuildTime, [kTechDataModel] = MAC.kModelName, [kTechDataDamageType] = kMACAttackDamageType, [kTechDataInitialEnergy] = kMACInitialEnergy, [kTechDataMaxEnergy] = kMACMaxEnergy, [kTechDataMenuPriority] = 1, [kTechDataPointValue] = kMACPointValue, [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MAC_TOOLTIP"},
        { [kTechDataId] = kTechId.CatPackTech,           [kTechDataCostKey] = kCatPackTechResearchCost,          [kTechDataResearchTimeKey] = kCatPackTechResearchTime, [kTechDataDisplayName] = "CAT_PACKS", [kTechDataTooltipInfo] = "CAT_PACK_TECH_TOOLTIP"},

        // Marine base structures
        { [kTechDataId] = kTechId.Extractor, [kTechDataHint] = "EXTRACTOR_HINT", [kTechDataAllowStacking] = true,    [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataRequiresPower] = true,       [kTechDataMapName] = Extractor.kMapName,                [kTechDataDisplayName] = "EXTRACTOR",           [kTechDataCostKey] = kExtractorCost,       [kTechDataBuildTime] = kExtractorBuildTime, [kTechDataEngagementDistance] = kExtractorEngagementDistance, [kTechDataModel] = Extractor.kModelName,            [kTechDataMaxHealth] = kExtractorHealth, [kTechDataMaxArmor] = kExtractorArmor, [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kExtractorPointValue, [kTechDataHotkey] = Move.E, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] =  "EXTRACTOR_TOOLTIP"},
        { [kTechDataId] = kTechId.InfantryPortal, [kTechDataHint] = "INFANTRY_PORTAL_HINT", [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataRequiresPower] = true, [kTechDataGhostGuidesMethod] = GetInfantryPortalGhostGuides, [kTechDataBuildRequiresMethod] = GetCommandStationIsBuilt,   [kTechDataMapName] = InfantryPortal.kMapName,           [kTechDataDisplayName] = "INFANTRY_PORTAL",     [kTechDataCostKey] = kInfantryPortalCost,   [kTechDataPointValue] = kInfantryPortalPointValue,   [kTechDataBuildTime] = kInfantryPortalBuildTime, [kTechDataMaxHealth] = kInfantryPortalHealth, [kTechDataMaxArmor] = kInfantryPortalArmor, [kTechDataModel] = InfantryPortal.kModelName, [kStructureBuildNearClass] = "CommandStation", [kStructureAttachId] = kTechId.CommandStation, [kStructureAttachRange] = kInfantryPortalAttachRange, [kTechDataEngagementDistance] = kInfantryPortalEngagementDistance, [kTechDataHotkey] = Move.P, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "INFANTRY_PORTAL_TOOLTIP"},
        { [kTechDataId] = kTechId.Armory,         [kTechDataHint] = "ARMORY_HINT", [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataRequiresPower] = true,      [kTechDataMapName] = Armory.kMapName,                   [kTechDataDisplayName] = "ARMORY",              [kTechDataCostKey] = kArmoryCost,              [kTechDataBuildTime] = kArmoryBuildTime, [kTechDataMaxHealth] = kArmoryHealth, [kTechDataMaxArmor] = kArmoryArmor, [kTechDataEngagementDistance] = kArmoryEngagementDistance, [kTechDataModel] = Armory.kModelName, [kTechDataPointValue] = kArmoryPointValue, [kTechDataInitialEnergy] = kArmoryInitialEnergy,   [kTechDataMaxEnergy] = kArmoryMaxEnergy, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ARMORY_TOOLTIP"},
        { [kTechDataId] = kTechId.ArmsLab,        [kTechDataHint] = "ARMSLAB_HINT", [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataRequiresPower] = true,       [kTechDataMapName] = ArmsLab.kMapName,                  [kTechDataDisplayName] = "ARMS_LAB",            [kTechDataCostKey] = kArmsLabCost,              [kTechDataBuildTime] = kArmsLabBuildTime, [kTechDataMaxHealth] = kArmsLabHealth, [kTechDataMaxArmor] = kArmsLabArmor, [kTechDataEngagementDistance] = kArmsLabEngagementDistance, [kTechDataModel] = ArmsLab.kModelName, [kTechDataPointValue] = kArmsLabPointValue, [kTechDataHotkey] = Move.A, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ARMS_LAB_TOOLTIP"},
        { [kTechDataId] = kTechId.Sentry,   [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_SENTRIES",      [kTechDataHint] = "SENTRY_HINT", [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataMapName] = Sentry.kMapName,                   [kTechDataDisplayName] = "SENTRY_TURRET",       [kTechDataCostKey] = kSentryCost,         [kTechDataPointValue] = kSentryPointValue, [kTechDataModel] = Sentry.kModelName,            [kTechDataBuildTime] = kSentryBuildTime, [kTechDataMaxHealth] = kSentryHealth,  [kTechDataMaxArmor] = kSentryArmor, [kTechDataDamageType] = kSentryAttackDamageType, [kTechDataSpecifyOrientation] = true, [kTechDataHotkey] = Move.S, [kTechDataInitialEnergy] = kSentryInitialEnergy,      [kTechDataMaxEnergy] = kSentryMaxEnergy, [kTechDataNotOnInfestation] = true, [kTechDataEngagementDistance] = kSentryEngagementDistance, [kTechDataTooltipInfo] = "SENTRY_TOOLTIP", [kStructureBuildNearClass] = "SentryBattery", [kStructureAttachRange] = SentryBattery.kRange, [kTechDataBuildRequiresMethod] = GetCheckSentryLimit, [kTechDataGhostGuidesMethod] = GetBatteryInRange },
        { [kTechDataId] = kTechId.SentryBattery, [kTechDataBuildRequiresMethod] = GetRoomHasNoSentryBattery, [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_ONLY_ONE_BATTERY_PER_ROOM",  [kTechDataHint] = "SENTRY_BATTERY_HINT", [kTechDataGhostModelClass] = "MarineGhostModel", [kTechDataMapName] = SentryBattery.kMapName,                [kTechDataDisplayName] = "SENTRY_BATTERY",          [kTechDataCostKey] = kSentryBatteryCost,      [kTechDataPointValue] = kSentryBatteryPointValue, [kTechDataModel] = SentryBattery.kModelName,  [kTechDataEngagementDistance] = 2,   [kTechDataBuildTime] = kSentryBatteryBuildTime, [kTechDataMaxHealth] = kSentryBatteryHealth,  [kTechDataMaxArmor] = kSentryBatteryArmor, [kTechDataTooltipInfo] = "SENTRY_BATTERY_TOOLTIP", [kTechDataHotkey] = Move.S, [kTechDataNotOnInfestation] = true, [kVisualRange] = SentryBattery.kRange},

        // MACs 
        { [kTechDataId] = kTechId.MACEMP,    [kTechDataCooldown] = kEMPCooldown,       [kTechDataDisplayName] = "MAC_EMP", [kTechDataTooltipInfo] = "MAC_EMP_TOOLTIP", [kTechDataCostKey] = kEMPCost },        
        { [kTechDataId] = kTechId.MACEMPTech,       [kTechDataDisplayName] = "MAC_EMP_RESEARCH", [kTechDataTooltipInfo] = "MAC_EMP_RESEARCH_TOOLTIP", [kTechDataCostKey] = kTechEMPResearchCost,             [kTechDataResearchTimeKey] = kTechEMPResearchTime, },
        { [kTechDataId] = kTechId.MACSpeedTech,     [kTechDataDisplayName] = "MAC_SPEED",  [kTechDataCostKey] = kTechMACSpeedResearchCost,  [kTechDataResearchTimeKey] = kTechMACSpeedResearchTime, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "MAC_SPEED_TOOLTIP"},

        // Marine advanced structures
        { [kTechDataId] = kTechId.AdvancedArmory, [kTechDataHint] = "ADVANCED_ARMORY_HINT", [kTechDataTooltipInfo] =  "ADVANCED_ARMORY_TOOLTIP", [kTechDataGhostModelClass] = "MarineGhostModel",   [kTechIDShowEnables] = false, [kTechDataRequiresPower] = true,     [kTechDataMapName] = AdvancedArmory.kMapName,                   [kTechDataDisplayName] = "ADVANCED_ARMORY",     [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,  [kTechDataModel] = Armory.kModelName,                     [kTechDataMaxHealth] = kAdvancedArmoryHealth,   [kTechDataMaxArmor] = kAdvancedArmoryArmor,  [kTechDataEngagementDistance] = kArmoryEngagementDistance,  [kTechDataUpgradeTech] = kTechId.Armory, [kTechDataPointValue] = kAdvancedArmoryPointValue},
        { [kTechDataId] = kTechId.Observatory, [kTechDataHint] = "OBSERVATORY_HINT", [kTechDataGhostModelClass] = "MarineGhostModel",  [kTechDataRequiresPower] = true,        [kTechDataMapName] = Observatory.kMapName,    [kTechDataDisplayName] = "OBSERVATORY",  [kVisualRange] = Observatory.kDetectionRange, [kTechDataCostKey] = kObservatoryCost,       [kTechDataModel] = Observatory.kModelName,            [kTechDataBuildTime] = kObservatoryBuildTime, [kTechDataMaxHealth] = kObservatoryHealth,   [kTechDataEngagementDistance] = kObservatoryEngagementDistance, [kTechDataMaxArmor] = kObservatoryArmor,   [kTechDataInitialEnergy] = kObservatoryInitialEnergy,      [kTechDataMaxEnergy] = kObservatoryMaxEnergy, [kTechDataPointValue] = kObservatoryPointValue, [kTechDataHotkey] = Move.O, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "OBSERVATORY_TOOLTIP"},
        { [kTechDataId] = kTechId.DistressBeacon,    [kTechDataBuildTime] = 0.1,    [kTechDataDisplayName] = "DISTRESS_BEACON",   [kTechDataHotkey] = Move.B, [kTechDataCostKey] = kObservatoryDistressBeaconCost, [kTechDataTooltipInfo] =  "DISTRESS_BEACON_TOOLTIP"},

        { [kTechDataId] = kTechId.RoboticsFactory, [kTechDataHint] = "ROBOTICS_FACTORY_HINT", [kTechDataGhostModelClass] = "MarineGhostModel",    [kTechDataRequiresPower] = true,   [kTechDataDisplayName] = "ROBOTICS_FACTORY",  [kTechDataMapName] = RoboticsFactory.kMapName, [kTechDataCostKey] = kRoboticsFactoryCost,       [kTechDataModel] = RoboticsFactory.kModelName,    [kTechDataEngagementDistance] = kRoboticsFactorEngagementDistance,        [kTechDataSpecifyOrientation] = true, [kTechDataBuildTime] = kRoboticsFactoryBuildTime, [kTechDataMaxHealth] = kRoboticsFactoryHealth,    [kTechDataMaxArmor] = kRoboticsFactoryArmor, [kTechDataPointValue] = kRoboticsFactoryPointValue, [kTechDataHotkey] = Move.R, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ROBOTICS_FACTORY_TOOLTIP"},        
        { [kTechDataId] = kTechId.UpgradeRoboticsFactory, [kTechDataDisplayName] = "UPGRADE_ROBOTICS_FACTORY", [kTechIDShowEnables] = false, [kTechDataCostKey] = kUpgradeRoboticsFactoryCost,   [kTechDataResearchTimeKey] = kUpgradeRoboticsFactoryTime, [kTechDataTooltipInfo] = "UPGRADE_ROBOTICS_FACTORY_TOOLTIP"},        
        { [kTechDataId] = kTechId.ARCRoboticsFactory, [kTechDataCostKey] = kRoboticsFactoryCost + kUpgradeRoboticsFactoryCost, [kTechDataHint] = "ARC_ROBOTICS_FACTORY_HINT", [kTechDataRequiresPower] = true,  [kTechIDShowEnables] = false,  [kTechDataDisplayName] = "ARC_ROBOTICS_FACTORY",  [kTechDataMapName] = ARCRoboticsFactory.kMapName, [kTechDataModel] = RoboticsFactory.kModelName,   [kTechDataEngagementDistance] = kRoboticsFactorEngagementDistance,        [kTechDataSpecifyOrientation] = true, [kTechDataBuildTime] = kRoboticsFactoryBuildTime, [kTechDataMaxHealth] = kARCRoboticsFactoryHealth,    [kTechDataMaxArmor] = kARCRoboticsFactoryArmor, [kTechDataPointValue] = kARCRoboticsFactoryPointValue, [kTechDataHotkey] = Move.R, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ARC_ROBOTICS_FACTORY_TOOLTIP"},        

        { [kTechDataId] = kTechId.ARC,      [kTechDataHint] = "ARC_HINT",             [kTechDataDisplayName] = "ARC",               [kTechDataTooltipInfo] = "ARC_TOOLTIP", [kTechDataMapName] = ARC.kMapName,   [kTechDataCostKey] = kARCCost,       [kTechDataDamageType] = kARCDamageType,  [kTechDataResearchTimeKey] = kARCBuildTime, [kTechDataMaxHealth] = kARCHealth, [kTechDataEngagementDistance] = kARCEngagementDistance, [kVisualRange] = ARC.kFireRange, [kTechDataMaxArmor] = kARCArmor, [kTechDataModel] = ARC.kModelName, [kTechDataMaxHealth] = kARCHealth, [kTechDataPointValue] = kARCPointValue, [kTechDataHotkey] = Move.T},
        { [kTechDataId] = kTechId.ARCSplashTech,        [kTechDataCostKey] = kARCSplashTechResearchCost,             [kTechDataResearchTimeKey] = kARCSplashTechResearchTime, [kTechDataDisplayName] = "ARC_SPLASH", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ARCArmorTech,         [kTechDataCostKey] = kARCArmorTechResearchCost,             [kTechDataResearchTimeKey] = kARCArmorTechResearchTime, [kTechDataDisplayName] = "ARC_ARMOR", [kTechDataImplemented] = false },
        
        // Upgrades
        { [kTechDataId] = kTechId.PhaseTech,             [kTechDataCostKey] = kPhaseTechResearchCost,                [kTechDataDisplayName] = "PHASE_TECH", [kTechDataResearchTimeKey] = kPhaseTechResearchTime, [kTechDataTooltipInfo] = "PHASE_TECH_TOOLTIP" },
        { [kTechDataId] = kTechId.PhaseGate, [kTechDataHint] = "PHASE_GATE_HINT", [kTechDataGhostModelClass] = "MarineGhostModel",    [kTechDataRequiresPower] = true,        [kTechDataMapName] = PhaseGate.kMapName,                    [kTechDataDisplayName] = "PHASE_GATE",  [kTechDataCostKey] = kPhaseGateCost,       [kTechDataModel] = PhaseGate.kModelName, [kTechDataBuildTime] = kPhaseGateBuildTime, [kTechDataMaxHealth] = kPhaseGateHealth,   [kTechDataEngagementDistance] = kPhaseGateEngagementDistance, [kTechDataMaxArmor] = kPhaseGateArmor,   [kTechDataPointValue] = kPhaseGatePointValue, [kTechDataHotkey] = Move.P, [kTechDataNotOnInfestation] = true, [kTechDataSpecifyOrientation] = true, [kTechDataTooltipInfo] = "PHASE_GATE_TOOLTIP"},
        { [kTechDataId] = kTechId.AdvancedArmoryUpgrade, [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,  [kTechIDShowEnables] = false,          [kTechDataResearchTimeKey] = kAdvancedArmoryResearchTime,  [kTechDataHotkey] = Move.U, [kTechDataDisplayName] = "ADVANCED_ARMORY_UPGRADE", [kTechDataTooltipInfo] =  "ADVANCED_ARMORY_TOOLTIP"},
        { [kTechDataId] = kTechId.PrototypeLab, [kTechDataHint] = "PROTOTYPE_LAB_HINT", [kTechDataGhostModelClass] = "MarineGhostModel",  [kTechDataRequiresPower] = true,  [kTechDataMapName] = PrototypeLab.kMapName,  [kTechDataNotOnInfestation] = true,   [kTechDataCostKey] = kPrototypeLabCost,                     [kTechDataResearchTimeKey] = kPrototypeLabBuildTime,       [kTechDataDisplayName] = "PROTOTYPE_LAB", [kTechDataModel] = PrototypeLab.kModelName, [kTechDataMaxHealth] = kPrototypeLabHealth, [kTechDataPointValue] = kPrototypeLabPointValue, [kTechDataTooltipInfo] = "PROTOTYPE_LAB_TOOLTIP"},
       
        // Weapons
        
        { [kTechDataId] = kTechId.MinesTech,   [kTechDataCostKey] = kMineResearchCost, [kTechDataResearchTimeKey] = kMineResearchTime, [kTechDataDisplayName] = "MINES"},
        { [kTechDataId] = kTechId.LayMines,    [kTechDataMapName] = LayMines.kMapName,         [kTechDataDisplayName] = "MINE",   [kTechDataModel] = Mine.kModelName,      [kTechDataCostKey] = kMineCost },
        { [kTechDataId] = kTechId.Mine,        [kTechDataMapName] = Mine.kMapName,             [kTechDataHint] = "MINE_HINT", [kTechDataDisplayName] = "MINE", [kTechDataEngagementDistance] = kMineDetonateRange, [kTechDataMaxHealth] = kMineHealth, [kTechDataTooltipInfo] = "MINE_TOOLTIP",  [kTechDataMaxArmor] = kMineArmor, [kTechDataModel] = Mine.kModelName, [kTechDataPointValue] = kMinePointValue, },

        { [kTechDataId] = kTechId.WelderTech,  [kTechDataCostKey] = kWelderTechResearchCost,     [kTechDataResearchTimeKey] = kWelderTechResearchTime, [kTechDataDisplayName] = "RESEARCH_WELDER", [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] =  "WELDER_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.Welder,     [kTechDataMaxHealth] = kMarineWeaponHealth, [kTechDataPointValue] = kWeaponPointValue, [kTechDataMapName] = Welder.kMapName,                    [kTechDataDisplayName] = "WELDER",      [kTechDataModel] = Welder.kModelName, [kTechDataDamageType] = kWelderDamageType, [kTechDataCostKey] = kWelderCost  },
        
        { [kTechDataId] = kTechId.Claw,      [kTechDataMapName] = Claw.kMapName, [kTechDataDisplayName] = "CLAW",  [kTechDataDamageType] = kClawDamageType },

        { [kTechDataId] = kTechId.Rifle,      [kTechDataMaxHealth] = kMarineWeaponHealth, [kTechDataTooltipInfo] = "RIFLE_TOOLTIP", [kTechDataPointValue] = kWeaponPointValue,    [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "RIFLE",         [kTechDataModel] = Rifle.kModelName, [kTechDataDamageType] = kRifleDamageType, [kTechDataCostKey] = kRifleCost, },
        { [kTechDataId] = kTechId.Pistol,     [kTechDataMaxHealth] = kMarineWeaponHealth, [kTechDataPointValue] = kWeaponPointValue,          [kTechDataMapName] = Pistol.kMapName,                   [kTechDataDisplayName] = "PISTOL",         [kTechDataModel] = Pistol.kModelName, [kTechDataDamageType] = kPistolDamageType, [kTechDataCostKey] = kPistolCost, [kTechDataTooltipInfo] = "PISTOL_TOOLTIP"},
        { [kTechDataId] = kTechId.Axe,                   [kTechDataMapName] = Axe.kMapName,                      [kTechDataDisplayName] = "SWITCH_AX",         [kTechDataModel] = Axe.kModelName, [kTechDataDamageType] = kAxeDamageType, [kTechDataCostKey] = kAxeCost, [kTechDataTooltipInfo] = "AXE_TOOLTIP"},
        { [kTechDataId] = kTechId.RifleUpgrade,          [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "RIFLE_UPGRADE", [kTechDataImplemented] = false, [kTechDataCostKey] = kRifleUpgradeCost, },
        { [kTechDataId] = kTechId.Shotgun,     [kTechDataMaxHealth] = kMarineWeaponHealth,    [kTechDataPointValue] = kWeaponPointValue,      [kTechDataMapName] = Shotgun.kMapName,                  [kTechDataDisplayName] = "SHOTGUN",             [kTechDataTooltipInfo] =  "SHOTGUN_TOOLTIP", [kTechDataModel] = Shotgun.kModelName, [kTechDataDamageType] = kShotgunDamageType, [kTechDataCostKey] = kShotgunCost, [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = true },
 
        // dropped by commander:
        
        { [kTechDataId] = kTechId.FlamethrowerTech,      [kTechDataCostKey] = kFlamethrowerTechResearchCost,     [kTechDataResearchTimeKey] = kFlamethrowerTechResearchTime, [kTechDataDisplayName] = "RESEARCH_FLAMETHROWERS", [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] =  "FLAMETHROWER_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.FlamethrowerAltTech,   [kTechDataCostKey] = kFlamethrowerAltTechResearchCost,  [kTechDataResearchTimeKey] = kFlamethrowerAltTechResearchTime, [kTechDataDisplayName] = "RESEARCH_FLAMETHROWER_ALT", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "FLAMETHROWER_ALT_TOOLTIP"},
        { [kTechDataId] = kTechId.Flamethrower,     [kTechDataMaxHealth] = kMarineWeaponHealth, [kTechDataPointValue] = kWeaponPointValue,  [kTechDataMapName] = Flamethrower.kMapName,             [kTechDataDisplayName] = "FLAMETHROWER", [kTechDataTooltipInfo] = "FLAMETHROWER_TOOLTIP", [kTechDataModel] = Flamethrower.kModelName,  [kTechDataDamageType] = kFlamethrowerDamageType, [kTechDataCostKey] = kFlamethrowerCost, [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = true},
        { [kTechDataId] = kTechId.DualMinigunTech,       [kTechDataCostKey] = kDualMinigunTechResearchCost,      [kTechDataResearchTimeKey] = kDualRailgunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_DUAL_MINIGUNS", [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "DUAL_MINIGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.ClawRailgunTech,       [kTechDataCostKey] = kClawRailgunTechResearchCost,      [kTechDataResearchTimeKey] = kClawMinigunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_CLAW_RAILGUN", [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "CLAW_RAILGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.DualRailgunTech,       [kTechDataCostKey] = kDualRailgunTechResearchCost,      [kTechDataResearchTimeKey] = kDualMinigunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_DUAL_RAILGUNS", [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "DUAL_RAILGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.Minigun,               [kTechDataMapName] = Minigun.kMapName,                  [kTechDataDisplayName] = "MINIGUN", [kTechDataDamageType] = kMinigunDamageType,         [kTechDataCostKey] = kMinigunCost, [kTechDataDisplayName] = "MINIGUN_CLAW_TOOLTIP", [kTechDataModel] = Minigun.kModelName},
        { [kTechDataId] = kTechId.Railgun,               [kTechDataMapName] = Railgun.kMapName,                  [kTechDataDisplayName] = "RAILGUN", [kTechDataDamageType] = kRailgunDamageType,         [kTechDataCostKey] = kRailgunCost, [kTechDataDisplayName] = "RAILGUN_CLAW_TOOLTIP", [kTechDataModel] = Railgun.kModelName},
        { [kTechDataId] = kTechId.GrenadeLauncher,    [kTechDataMaxHealth] = kMarineWeaponHealth,  [kTechDataMapName] = GrenadeLauncher.kMapName,          [kTechDataDisplayName] = "GRENADE_LAUNCHER",  [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_TOOLTIP",   [kTechDataModel] = GrenadeLauncher.kModelName,   [kTechDataDamageType] = kRifleDamageType,    [kTechDataCostKey] = kGrenadeLauncherCost, [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = true},
        
        // LS - equipment pile spawnables
        { [kTechDataId] = kTechId.DropShotgun,   [kTechDataMapName] = Shotgun.kMapName, [kTechDataDisplayName] = "SHOTGUN", [kTechIDShowEnables] = false,  [kTechDataTooltipInfo] =  "SHOTGUN_TOOLTIP", [kTechDataModel] = Shotgun.kModelName, [kTechDataCostKey] = kShotgunCost, [kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory }, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropWelder,    [kTechDataMapName] = Welder.kMapName, [kTechDataDisplayName] = "WELDER", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "WELDER_TOOLTIP", [kTechDataModel] = Welder.kModelName, [kTechDataCostKey] = kWelderCost, [kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory }, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropMines,   [kTechDataMapName] = LayMines.kMapName, [kTechDataDisplayName] = "MINE", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "MINE_TOOLTIP", [kTechDataModel] = Mine.kModelName, [kTechDataCostKey] = kMineCost, [kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory }, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropGrenadeLauncher,   [kTechDataMapName] = GrenadeLauncher.kMapName, [kTechIDShowEnables] = false, [kTechDataDisplayName] = "GRENADE_LAUNCHER", [kTechDataTooltipInfo] =  "GRENADE_LAUNCHER_TOOLTIP", [kTechDataModel] = GrenadeLauncher.kModelName, [kTechDataCostKey] = kGrenadeLauncherCost, [kStructureAttachId] = kTechId.AdvancedArmory, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropFlamethrower,   [kTechDataMapName] = Flamethrower.kMapName, [kTechDataDisplayName] = "FLAMETHROWER", [kTechIDShowEnables] = false,  [kTechDataTooltipInfo] =  "FLAMETHROWER_TOOLTIP", [kTechDataModel] = Flamethrower.kModelName, [kTechDataCostKey] = kFlamethrowerCost, [kStructureAttachId] = kTechId.AdvancedArmory, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropJetpack,   [kTechDataMapName] = Jetpack.kMapName, [kTechDataDisplayName] = "JETPACK", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "JETPACK_TOOLTIP", [kTechDataModel] = Jetpack.kModelName, [kTechDataCostKey] = kJetpackCost, [kStructureAttachId] = kTechId.PrototypeLab, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropExosuit,   [kTechDataMapName] = Exosuit.kMapName, [kTechDataDisplayName] = "EXOSUIT", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "EXOSUIT_TOOLTIP", [kTechDataModel] = Exosuit.kModelName, [kTechDataCostKey] = kExosuitCost, [kStructureAttachId] = kTechId.PrototypeLab, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropSentry,   [kTechDataMapName] = LSBuildSentry.kMapName, [kTechDataDisplayName] = "SENTRY", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "SENTRY_TOOLTIP", [kTechDataModel] = Sentry.kModelName, [kTechDataCostKey] = kSentryCost, [kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory }, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },

        // New stuff for LS
        { [kTechDataId] = kTechId.DropDualMiniExo,   [kTechDataMapName] = DualMinigunExosuit.kMapName, [kTechDataDisplayName] = "DUALMINIGUN_EXOSUIT", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "DUALMINIGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataModel] = Exosuit.kModelName, [kTechDataCostKey] = kExosuitCost, [kStructureAttachId] = kTechId.PrototypeLab, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropDualRailExo,   [kTechDataMapName] = DualRailgunExosuit.kMapName, [kTechDataDisplayName] = "DUALRAILGUN_EXOSUIT", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "DUALRAILGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataModel] = Exosuit.kModelName, [kTechDataCostKey] = kExosuitCost, [kStructureAttachId] = nil, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropClawRailExo,   [kTechDataMapName] = ClawRailgunExosuit.kMapName, [kTechDataDisplayName] = "CLAWRAILGUN_EXOSUIT", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "CLAWRAILGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataModel] = Exosuit.kModelName, [kTechDataCostKey] = kExosuitCost, [kStructureAttachId] = nil, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropMedPack,   [kTechDataMapName] = MedPack.kMapName, [kTechDataDisplayName] = "MED_PACK", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "MED_PACK_TOOLTIP", [kTechDataModel] = MedPack.kModelName, [kTechDataCostKey] = kMedPackCost, [kStructureAttachId] = nil, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
        { [kTechDataId] = kTechId.DropAmmoPack,   [kTechDataMapName] = AmmoPack.kMapName, [kTechDataDisplayName] = "AMMO_PACK", [kTechIDShowEnables] = false, [kTechDataTooltipInfo] =  "AMMO_PACK_TOOLTIP", [kTechDataModel] = AmmoPack.kModelName, [kTechDataCostKey] = kAmmoPackCost, [kStructureAttachId] = nil, [kStructureAttachRange] = kArmoryWeaponAttachRange, [kStructureAttachRequiresPower] = false },
       
        { [kTechDataId] = kTechId.BuildSentry,    [kTechDataMapName] = LSBuildSentry.kMapName,         [kTechDataDisplayName] = "SENTRY",   [kTechDataModel] = Sentry.kModelName,      [kTechDataCostKey] = kSentryCost },
       
        // Marine upgrades
        { [kTechDataId] = kTechId.NerveGas,              [kTechDataDisplayName] = "NERVE_GAS",  [kTechDataCostKey] = kNerveGasCost, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "NERVE_GAS_TOOLTIP"},        
        { [kTechDataId] = kTechId.FlamethrowerAlt,       [kTechDataDisplayName] = "FLAMETHROWER_ALT", [kTechIDShowEnables] = false, [kTechDataCostKey] = kFlamethrowerAltCost },        
        
        // Armor and upgrades
        { [kTechDataId] = kTechId.Jetpack,       [kTechDataImplemented] = true,        [kTechDataMapName] = Jetpack.kMapName,                   [kTechDataDisplayName] = "JETPACK", [kTechDataModel] = Jetpack.kModelName, [kTechDataCostKey] = kJetpackCost, [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight },
        { [kTechDataId] = kTechId.JetpackTech,     [kTechDataImplemented] = true,      [kTechDataCostKey] = kJetpackTechResearchCost,               [kTechDataResearchTimeKey] = kJetpackTechResearchTime,     [kTechDataDisplayName] = "JETPACK_TECH" },
        { [kTechDataId] = kTechId.JetpackFuelTech,       [kTechDataCostKey] = kJetpackFuelTechResearchCost,           [kTechDataResearchTimeKey] = kJetpackFuelTechResearchTime,     [kTechDataDisplayName] = "JETPACK_FUEL_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] =  "JETPACK_FUEL_TOOLTIP"},
        { [kTechDataId] = kTechId.JetpackArmorTech,       [kTechDataCostKey] = kJetpackArmorTechResearchCost,         [kTechDataResearchTimeKey] = kJetpackArmorTechResearchTime,     [kTechDataDisplayName] = "JETPACK_ARMOR_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "JETPACK_ARMOR_TOOLTIP"},

        
        { [kTechDataId] = kTechId.Exosuit,           [kTechDataDisplayName] = "EXOSUIT", [kTechDataMapName] = "exo",               [kTechDataCostKey] = kExosuitCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "EXOSUIT_TECH_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight},
        { [kTechDataId] = kTechId.DualMinigunExosuit,            [kTechDataDisplayName] = "DUALMINIGUN_EXOSUIT", [kTechDataMapName] = "exo",               [kTechDataCostKey] = kDualExosuitCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "DUALMINIGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight},
        { [kTechDataId] = kTechId.ClawRailgunExosuit,            [kTechDataDisplayName] = "CLAWRAILGUN_EXOSUIT", [kTechDataMapName] = "exo",               [kTechDataCostKey] = kClawRailgunExosuitCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "CLAWRAILGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight},
        { [kTechDataId] = kTechId.DualRailgunExosuit,            [kTechDataDisplayName] = "DUALRAILGUN_EXOSUIT", [kTechDataMapName] = "exo",               [kTechDataCostKey] = kDualRailgunExosuitCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "DUALRAILGUN_EXOSUIT_TECH_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight},
        { [kTechDataId] = kTechId.ExosuitTech,        [kTechDataDisplayName] = "RESEARCH_EXOSUITS", [kTechDataCostKey] = kExosuitTechResearchCost,  [kTechDataResearchTimeKey] = kExosuitTechResearchTime},
        { [kTechDataId] = kTechId.ExosuitLockdownTech,  [kTechDataCostKey] = kExosuitLockdownTechResearchCost,               [kTechDataResearchTimeKey] = kExosuitLockdownTechResearchTime,     [kTechDataDisplayName] = "EXOSUIT_LOCKDOWN_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "EXOSUIT_LOCKDOWN_TOOLTIP"},
        { [kTechDataId] = kTechId.ExosuitUpgradeTech,  [kTechDataCostKey] = kExosuitUpgradeTechResearchCost,               [kTechDataResearchTimeKey] = kExosuitUpgradeTechResearchTime,     [kTechDataDisplayName] = "EXOSUIT_UPGRADE_TECH", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.Armor1,                [kTechDataCostKey] = kArmor1ResearchCost,                   [kTechDataResearchTimeKey] = kArmor1ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_ARMOR1_TOOLTIP"},
        { [kTechDataId] = kTechId.Armor2,                [kTechDataCostKey] = kArmor2ResearchCost,                   [kTechDataResearchTimeKey] = kArmor2ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR2", [kTechDataHotkey] = Move.X, [kTechDataTooltipInfo] = "MARINE_ARMOR2_TOOLTIP"},
        { [kTechDataId] = kTechId.Armor3,                [kTechDataCostKey] = kArmor3ResearchCost,                   [kTechDataResearchTimeKey] = kArmor3ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR3", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "MARINE_ARMOR3_TOOLTIP"},

        // Weapons research
        { [kTechDataId] = kTechId.Weapons1,              [kTechDataCostKey] = kWeapons1ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons1ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS1_TOOLTIP"},
        { [kTechDataId] = kTechId.Weapons2,              [kTechDataCostKey] = kWeapons2ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons2ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS2", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS2_TOOLTIP"},
        { [kTechDataId] = kTechId.Weapons3,              [kTechDataCostKey] = kWeapons3ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons3ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS3", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS3_TOOLTIP"},
        { [kTechDataId] = kTechId.RifleUpgradeTech,      [kTechDataCostKey] = kRifleUpgradeTechResearchCost,         [kTechDataResearchTimeKey] = kRifleUpgradeTechResearchTime, [kTechDataDisplayName] = "RIFLE_UPGRADE", [kTechDataHotkey] = Move.U, [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ShotgunTech,           [kTechDataCostKey] = kShotgunTechResearchCost,              [kTechDataResearchTimeKey] = kShotgunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_SHOTGUNS", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] =  "SHOTGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.GrenadeLauncherTech,   [kTechDataCostKey] = kGrenadeLauncherTechResearchCost,      [kTechDataResearchTimeKey] = kGrenadeLauncherTechResearchTime, [kTechDataDisplayName] = "RESEARCH_GRENADE_LAUNCHERS", [kTechDataHotkey] = Move.G, [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_TECH_TOOLTIP"},
        
        // ARC abilities
        { [kTechDataId] = kTechId.ARCDeploy,            [kTechDataCostKey] = 0,  [kTechIDShowEnables] = false, [kTechDataResearchTimeKey] = kARCDeployTime, [kTechDataDisplayName] = "ARC_DEPLOY",                     [kTechDataMenuPriority] = 1, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "ARC_DEPLOY_TOOLTIP"},
        { [kTechDataId] = kTechId.ARCUndeploy,          [kTechDataCostKey] = 0,  [kTechIDShowEnables] = false,  [kTechDataResearchTimeKey] = kARCUndeployTime, [kTechDataDisplayName] = "ARC_UNDEPLOY",                    [kTechDataMenuPriority] = 2, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "ARC_UNDEPLOY_TOOLTIP"},

        // upgradeable life forms
        { [kTechDataId] = kTechId.LifeFormMenu,           [kTechDataDisplayName] = "BASIC_LIFE_FORMS", [kTechDataTooltipInfo] = "BASIC_LIFE_FORMS_TOOLTIP", },

        // Alien abilities for damage types
        
        // tier 1
        { [kTechDataId] = kTechId.Bite,                  [kTechDataMapName] = BiteLeap.kMapName,        [kTechDataDamageType] = kBiteDamageType,        [kTechDataDisplayName] = "BITE", [kTechDataTooltipInfo] = "BITE_TOOLTIP"},
        { [kTechDataId] = kTechId.Parasite,              [kTechDataMapName] = Parasite.kMapName,        [kTechDataDamageType] = kParasiteDamageType,    [kTechDataDisplayName] = "PARASITE", [kTechDataTooltipInfo] = "PARASITE_TOOLTIP"},
        { [kTechDataId] = kTechId.Spit,                  [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kSpitDamageType,        [kTechDataDisplayName] = "SPIT", [kTechDataTooltipInfo] = "SPIT_TOOLTIP" },
        { [kTechDataId] = kTechId.BuildAbility,          [kTechDataMapName] = DropStructureAbility.kMapName,            [kTechDataDisplayName] = "BUILD_ABILITY", [kTechDataTooltipInfo] = "BUILD_ABILITY_TOOLTIP"},
        { [kTechDataId] = kTechId.Spray,                 [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kHealsprayDamageType,   [kTechDataDisplayName] = "SPRAY", [kTechDataTooltipInfo] = "SPRAY_TOOLTIP"},
        { [kTechDataId] = kTechId.Swipe,                 [kTechDataMapName] = SwipeBlink.kMapName,      [kTechDataDamageType] = kSwipeDamageType,       [kTechDataDisplayName] = "SWIPE_BLINK", [kTechDataTooltipInfo] = "SWIPE_TOOLTIP"},
        { [kTechDataId] = kTechId.Gore,                  [kTechDataMapName] = Gore.kMapName,            [kTechDataDamageType] = kGoreDamageType,        [kTechDataDisplayName] = "GORE", [kTechDataTooltipInfo] = "GORE_TOOLTIP"},
        { [kTechDataId] = kTechId.LerkBite,              [kTechDataMapName] = LerkBite.kMapName,        [kTechDataDamageType] = kLerkBiteDamageType,    [kTechDataDisplayName] = "LERK_BITE", [kTechDataTooltipInfo] = "LERK_BITE_TOOLTIP"},
 
        // tier 2
        { [kTechDataId] = kTechId.Leap,      [kTechDataDisplayName] = "LEAP", [kTechDataCostKey] = kLeapResearchCost, [kTechDataResearchTimeKey] = kLeapResearchTime, [kTechDataTooltipInfo] = "LEAP_TOOLTIP" },     
        { [kTechDataId] = kTechId.BileBomb,  [kTechDataMapName] = BileBomb.kMapName,        [kTechDataDamageType] = kBileBombDamageType,  [kTechDataDisplayName] = "BILEBOMB", [kTechDataCostKey] = kBileBombResearchCost, [kTechDataResearchTimeKey] = kBileBombResearchTime, [kTechDataTooltipInfo] = "BILEBOMB_TOOLTIP" },
        { [kTechDataId] = kTechId.WebTech,     [kTechDataDisplayName] = "WEBTECH", [kTechDataCostKey] = kWebResearchCost, [kTechDataResearchTimeKey] = kWebResearchTime, [kTechDataTooltipInfo] = "WEBTECH_TOOLTIP" },
        { [kTechDataId] = kTechId.Spores,    [kTechDataMapName] = Spores.kMapName,          [kTechDataDisplayName] = "SPORES", [kTechDataCostKey] = kSporesResearchCost, [kTechDataResearchTimeKey] = kSporesResearchTime, [kTechDataTooltipInfo] = "SPORES_TOOLTIP"},
        { [kTechDataId] = kTechId.Blink,         [kTechDataDisplayName] = "BLINK", [kTechDataCostKey] = kBlinkResearchCost, [kTechDataResearchTimeKey] = kBlinkResearchTime, [kTechDataTooltipInfo] = "BLINK_TOOLTIP"},  
        { [kTechDataId] = kTechId.Stomp,         [kTechDataDisplayName] = "STOMP", [kTechDataCostKey] = kStompResearchCost, [kTechDataResearchTimeKey] = kStompResearchTime, [kTechDataTooltipInfo] = "STOMP_TOOLTIP" }, 

        // tier 3
        { [kTechDataId] = kTechId.Xenocide,       [kTechDataMapName] = XenocideLeap.kMapName,    [kTechDataDamageType] = kXenocideDamageType,   [kTechDataDisplayName] = "XENOCIDE", [kTechDataCostKey] = kXenocideResearchCost, [kTechDataResearchTimeKey] = kXenocideResearchTime, [kTechDataTooltipInfo] = "XENOCIDE_TOOLTIP"},
        { [kTechDataId] = kTechId.BabblerAbility,      [kTechDataMapName] = BabblerAbility.kMapName,   [kTechDataDisplayName] = "BABBLER_ABILITY", [kTechDataTooltipInfo] = "BABBLER_ABILITY_TOOLTIP", [kTechDataCostKey] = kBabblerAbilityResearchCost, [kTechDataResearchTimeKey] = kBabblerAbilityResearchTime},
        { [kTechDataId] = kTechId.Umbra,     [kTechDataMapName] = LerkUmbra.kMapName,       [kTechDataDisplayName] = "UMBRA", [kTechDataCostKey] = kUmbraResearchCost, [kTechDataResearchTimeKey] = kUmbraResearchTime, [kTechDataTooltipInfo] = "UMBRA_TOOLTIP"},
        { [kTechDataId] = kTechId.Vortex ,      [kTechDataMapName] = Vortex.kMapName,   [kTechDataDisplayName] = "VORTEX", [kTechDataCostKey] = kVortexResearchCost, [kTechDataResearchTimeKey] = kVortexResearchTime, [kTechDataTooltipInfo] = "VORTEX_TOOLTIP"},

        // Alien structures (spawn hive at 110 units off ground = 2.794 meters)
        { [kTechDataId] = kTechId.Hive, [kTechDataMaxExtents] = Vector(2, 1, 2), [kTechDataHint] = "HIVE_HINT", [kTechDataAllowStacking] = true, [kTechDataGhostModelClass] = "AlienGhostModel",  [kTechDataMapName] = Hive.kMapName,   [kTechDataDisplayName] = "HIVE", [kTechDataCostKey] = kHiveCost,                     [kTechDataBuildTime] = kHiveBuildTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,                [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,              [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "HIVE_TOOLTIP"}, 
        { [kTechDataId] = kTechId.HiveHeal,            [kTechDataDisplayName] = "HEAL",    [kTechDataHotkey] = Move.H,                       [kTechDataCostKey] = kCragHealCost, [kTechDataTooltipInfo] = "HIVE_HEAL_TOOLTIP"},
    
        { [kTechDataId] = kTechId.HealingBed,      [kTechDataDisplayName] = "HEALING_BED",  [kTechDataCostKey] = kHealingBedCost, [kTechDataResearchTimeKey] = kHealingBedResearchTime,  [kTechDataTooltipInfo] = "HEALING_BED_TOOLTIP", },
        { [kTechDataId] = kTechId.MucousMembrane,     [kTechDataDisplayName] = "MUCOUS_MEMBRANE",  [kTechDataImplemented] = false, [kTechDataCostKey] = kMucousMembraneCost, [kTechDataResearchTimeKey] = kMucousMembraneResearchTime,   [kTechDataTooltipInfo] = "MUCOUS_MEMBRANE_TOOLTIP", },
        { [kTechDataId] = kTechId.BacterialReceptors,     [kTechDataDisplayName] = "BACTERIAL_RECEPTORS",  [kTechDataCostKey] = kBacterialReceptorsCost, [kTechDataResearchTimeKey] = kBacterialReceptorsResearchTime, [kTechDataTooltipInfo] = "BACTERIAL_RECEPTORS_TOOLTIP", },

        { [kTechDataId] = kTechId.UpgradeToCragHive,    [kTechDataMapName] = CragHive.kMapName,   [kTechDataDisplayName] = "UPGRADE_CRAG_HIVE",  [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataTooltipInfo] = "UPGRADE_CRAG_HIVE_TOOLTIP", },
        { [kTechDataId] = kTechId.UpgradeToShiftHive,   [kTechDataMapName] = ShiftHive.kMapName,   [kTechDataDisplayName] = "UPGRADE_SHIFT_HIVE",  [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataTooltipInfo] = "UPGRADE_SHIFT_HIVE_TOOLTIP", },
        { [kTechDataId] = kTechId.UpgradeToShadeHive,   [kTechDataMapName] = ShadeHive.kMapName,   [kTechDataDisplayName] = "UPGRADE_SHADE_HIVE",  [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataTooltipInfo] = "UPGRADE_SHADE_HIVE_TOOLTIP", },

        { [kTechDataId] = kTechId.CragHive,  [kTechDataHint] = "CRAG_HIVE_HINT",          [kTechDataMapName] = CragHive.kMapName,                   [kTechDataDisplayName] = "CRAG_HIVE", [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataBuildTime] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,  [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,     [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "CRAG_HIVE_TOOLTIP"},
        { [kTechDataId] = kTechId.ShadeHive, [kTechDataHint] = "SHADE_HIVE_HINT",          [kTechDataMapName] = ShadeHive.kMapName,                   [kTechDataDisplayName] = "SHADE_HIVE", [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataBuildTime] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,  [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,     [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "SHADE_HIVE_TOOLTIP"},
        { [kTechDataId] = kTechId.ShiftHive, [kTechDataHint] = "SHIFT_HIVE_HINT",          [kTechDataMapName] = ShiftHive.kMapName,                   [kTechDataDisplayName] = "SHIFT_HIVE", [kTechDataCostKey] = kUpgradeHiveCost, [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime, [kTechDataBuildTime] = kUpgradeHiveResearchTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,  [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,     [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "SHIFT_HIVE_TOOLTIP"},
        
        // Drifter and tech
        { [kTechDataId] = kTechId.DrifterCamouflage,     [kTechDataDisplayName] = "CAMOUFLAGE",  [kTechDataTooltipInfo] = "DRIFTER_CAMOUFLAGE_TOOLTIP"},
        { [kTechDataId] = kTechId.Drifter,    [kTechDataHint] = "DRIFTER_HINT",           [kTechDataMapName] = Drifter.kMapName,                      [kTechDataDisplayName] = "DRIFTER",       [kTechDataCostKey] = kDrifterCost,              [kTechDataResearchTimeKey] = kDrifterBuildTime,     [kTechDataHotkey] = Move.D, [kTechDataMaxHealth] = kDrifterHealth, [kTechDataMaxArmor] = kDrifterArmor, [kTechDataModel] = Drifter.kModelName, [kTechDataDamageType] = kDrifterAttackDamageType, [kTechDataPointValue] = kDrifterPointValue, [kTechDataTooltipInfo] = "DRIFTER_TOOLTIP", [kTechDataInitialEnergy] = kDrifterInitialEnergy,      [kTechDataMaxEnergy] = kDrifterMaxEnergy,},   
               
        // Alien buildables
        { [kTechDataId] = kTechId.Egg,    [kTechDataHint] = "EGG_HINT",    [kTechDataMapName] = Egg.kMapName,                         [kTechDataDisplayName] = "EGG",         [kTechDataTooltipInfo] = "EGG_DROP_TOOLTIP", [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataBuildTime] = 1, [kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2), [kTechDataRequiresInfestation] = true }, 
        { [kTechDataId] = kTechId.GorgeEgg,   [kTechDataHint] = "EGG_HINT", [kTechDataMapName] = GorgeEgg.kMapName,                         [kTechDataDisplayName] = "GORGE_EGG",         [kTechDataTooltipInfo] = "GORGE_EGG_DROP_TOOLTIP", [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataResearchTimeKey] = kGorgeGestateTime, [kTechDataCostKey] = kGorgeCost, [kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2), [kTechDataRequiresInfestation] = true }, 
        { [kTechDataId] = kTechId.LerkEgg,    [kTechDataHint] = "EGG_HINT", [kTechDataMapName] = LerkEgg.kMapName,                         [kTechDataDisplayName] = "LERK_EGG",         [kTechDataTooltipInfo] = "LERK_EGG_DROP_TOOLTIP", [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataResearchTimeKey] = kLerkGestateTime, [kTechDataCostKey] = kLerkCost, [kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2), [kTechDataRequiresInfestation] = true }, 
        { [kTechDataId] = kTechId.FadeEgg,    [kTechDataHint] = "EGG_HINT", [kTechDataMapName] = FadeEgg.kMapName,                         [kTechDataDisplayName] = "FADE_EGG",         [kTechDataTooltipInfo] = "FADE_EGG_DROP_TOOLTIP", [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataResearchTimeKey] = kFadeGestateTime, [kTechDataCostKey] = kFadeCost, [kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2), [kTechDataRequiresInfestation] = true }, 
        { [kTechDataId] = kTechId.OnosEgg,    [kTechDataHint] = "EGG_HINT", [kTechDataMapName] = OnosEgg.kMapName,                         [kTechDataDisplayName] = "ONOS_EGG",         [kTechDataTooltipInfo] = "ONOS_EGG_DROP_TOOLTIP", [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataResearchTimeKey] = kOnosGestateTime, [kTechDataCostKey] = kOnosCost, [kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2), [kTechDataRequiresInfestation] = true }, 

        { [kTechDataId] = kTechId.Harvester, [kTechDataMaxExtents] = Vector(1, 1, 1), [kTechDataHint] = "HARVESTER_HINT", [kTechDataAllowStacking] = true, [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Harvester.kMapName,                    [kTechDataDisplayName] = "HARVESTER",  [kTechDataRequiresInfestation] = true,   [kTechDataCostKey] = kHarvesterCost,            [kTechDataBuildTime] = kHarvesterBuildTime, [kTechDataHotkey] = Move.H, [kTechDataMaxHealth] = kHarvesterHealth, [kTechDataMaxArmor] = kHarvesterArmor, [kTechDataModel] = Harvester.kModelName,           [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kHarvesterPointValue, [kTechDataTooltipInfo] = "HARVESTER_TOOLTIP"},
        { [kTechDataId] = kTechId.HarvesterUpgrade,      [kTechDataCostKey] = kResourceUpgradeResearchCost,          [kTechDataResearchTimeKey] = kResourceUpgradeResearchTime, [kTechDataDisplayName] = string.format("Upgrade player resource production by %d%%", math.floor(kResourceUpgradeAmount*100)), [kTechDataHotkey] = Move.U },

        // Infestation
        { [kTechDataId] = kTechId.Infestation,           [kTechDataDisplayName] = "INFESTATION", [kTechDataTooltipInfo] = "INFESTATION_TOOLTIP", },
        { [kTechDataId] = kTechId.GrenadeWhack,           [kTechDataDisplayName] = "GRENADE_WHACK", [kTechDataTooltipInfo] = "GRENADE_WHACK_TOOLTIP", },

        // Upgrade structures and research
        { [kTechDataId] = kTechId.Shell, [kTechDataHint] = "SHELL_HINT",  [kTechDataGhostModelClass] = "AlienGhostModel",     [kTechDataMapName] = Shell.kMapName,                         [kTechDataDisplayName] = "SHELL",  [kTechDataCostKey] = kShellCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kShellBuildTime, [kTechDataModel] = Shell.kModelName,           [kTechDataMaxHealth] = kShellHealth, [kTechDataMaxArmor] = kShellArmor,  [kTechDataPointValue] = kShellPointValue, [kTechDataTooltipInfo] = "SHELL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeRegenerationShell,   [kTechDataDisplayName] = "UPGRADE_REGENERATION_SHELL",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_REGENERATION_SHELL_TOOLTIP", [kTechDataCostKey] = kRegenerationResearchCost, [kTechDataResearchTimeKey] =  kRegenerationResearchTime},
        { [kTechDataId] = kTechId.RegenerationShell, [kTechDataHint] = "REGENERATION_SHELL_HINT",         [kTechDataMapName] = RegenerationShell.kMapName,                 [kTechDataDisplayName] = "REGENERATION_SHELL",  [kTechDataCostKey] = kShellCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kShellBuildTime, [kTechDataModel] = Shell.kModelName,           [kTechDataMaxHealth] = kShellHealth, [kTechDataMaxArmor] = kShellArmor,  [kTechDataPointValue] = kShellPointValue, [kTechDataTooltipInfo] = "REGENERATION_SHELL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeCarapaceShell,   [kTechDataDisplayName] = "UPGRADE_CARAPACE_SHELL",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_CARAPACE_SHELL_TOOLTIP", [kTechDataCostKey] = kCarapaceResearchCost, [kTechDataResearchTimeKey] =  kCarapaceResearchTime},
        { [kTechDataId] = kTechId.CarapaceShell,   [kTechDataHint] = "CARAPACE_SHELL_HINT",        [kTechDataMapName] = CarapaceShell.kMapName,                 [kTechDataDisplayName] = "CARAPACE_SHELL",  [kTechDataCostKey] = kShellCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kShellBuildTime, [kTechDataModel] = Shell.kModelName,           [kTechDataMaxHealth] = kShellHealth, [kTechDataMaxArmor] = kShellArmor,  [kTechDataPointValue] = kShellPointValue, [kTechDataTooltipInfo] = "CARAPACE_SHELL_TOOLTIP", [kTechDataGrows] = true},

        { [kTechDataId] = kTechId.Crag, [kTechDataHint] = "CRAG_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Crag.kMapName,                         [kTechDataDisplayName] = "CRAG",  [kTechDataCostKey] = kCragCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kCragBuildTime, [kTechDataModel] = Crag.kModelName,           [kTechDataMaxHealth] = kCragHealth, [kTechDataMaxArmor] = kCragArmor,   [kTechDataInitialEnergy] = kCragInitialEnergy,      [kTechDataMaxEnergy] = kCragMaxEnergy, [kTechDataPointValue] = kCragPointValue, [kVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "CRAG_TOOLTIP", [kTechDataGrows] = true},

        { [kTechDataId] = kTechId.Whip, [kTechDataHint] = "WHIP_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Whip.kMapName,                         [kTechDataDisplayName] = "WHIP",  [kTechDataCostKey] = kWhipCost,    [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.W,        [kTechDataBuildTime] = kWhipBuildTime, [kTechDataModel] = Whip.kModelName,           [kTechDataMaxHealth] = kWhipHealth, [kTechDataMaxArmor] = kWhipArmor,   [kTechDataDamageType] = kDamageType.Structural, [kTechDataInitialEnergy] = kWhipInitialEnergy,      [kTechDataMaxEnergy] = kWhipMaxEnergy, [kVisualRange] = Whip.kRange, [kTechDataPointValue] = kWhipPointValue, [kTechDataTooltipInfo] = "WHIP_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.EvolveBombard,   [kTechDataRequiresMature] = true,      [kTechDataDisplayName] = "EVOLVE_BOMBARD",  [kTechDataCostKey] = kEvolveBombardCost, [kTechDataResearchTimeKey] = kEvolveBombardResearchTime, [kTechDataTooltipInfo] = "EVOLVE_BOMBARD_TOOLTIP" },

        { [kTechDataId] = kTechId.Spur,  [kTechDataHint] = "SPUR_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",     [kTechDataMapName] = Spur.kMapName,                         [kTechDataDisplayName] = "SPUR",  [kTechDataCostKey] = kSpurCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kSpurBuildTime, [kTechDataModel] = Spur.kModelName,           [kTechDataMaxHealth] = kSpurHealth, [kTechDataMaxArmor] = kSpurArmor,  [kTechDataPointValue] = kSpurPointValue, [kTechDataTooltipInfo] = "SPUR_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeCeleritySpur,   [kTechDataDisplayName] = "UPGRADE_CELERITY_SPUR",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_CELERITY_SPUR_TOOLTIP", [kTechDataCostKey] = kCelerityResearchCost, [kTechDataResearchTimeKey] =  kCelerityResearchTime},
        { [kTechDataId] = kTechId.CeleritySpur,  [kTechDataHint] = "CELERITY_SPUR_HINT",        [kTechDataMapName] = CeleritySpur.kMapName,                 [kTechDataDisplayName] = "CELERITY_SPUR",  [kTechDataCostKey] = kSpurCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kSpurBuildTime, [kTechDataModel] = Spur.kModelName,           [kTechDataMaxHealth] = kSpurHealth, [kTechDataMaxArmor] = kSpurArmor,  [kTechDataPointValue] = kSpurPointValue, [kTechDataTooltipInfo] = "CELERITY_SPUR_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeHyperMutationSpur,   [kTechDataDisplayName] = "UPGRADE_HYPERMUTATION_SPUR",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_HYPERMUTATION_SPUR_TOOLTIP", [kTechDataCostKey] = kCelerityResearchCost, [kTechDataResearchTimeKey] =  kCelerityResearchTime},
        { [kTechDataId] = kTechId.HyperMutationSpur,   [kTechDataHint] = "HYPERMUTATION_SPUR_HINT",   [kTechDataMapName] = HyperMutationSpur.kMapName,                 [kTechDataDisplayName] = "HYPERMUTATION_SPUR",  [kTechDataCostKey] = kSpurCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kSpurBuildTime, [kTechDataModel] = Spur.kModelName,           [kTechDataMaxHealth] = kSpurHealth, [kTechDataMaxArmor] = kSpurArmor,  [kTechDataPointValue] = kSpurPointValue, [kTechDataTooltipInfo] = "HYPERMUTATION_SPUR_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeAdrenalineSpur,   [kTechDataDisplayName] = "UPGRADE_ADRENALINE_SPUR",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_ADRENALINE_SPUR_TOOLTIP", [kTechDataCostKey] = kAdrenalineResearchCost, [kTechDataResearchTimeKey] =  kAdrenalineResearchTime},
        { [kTechDataId] = kTechId.AdrenalineSpur,    [kTechDataHint] = "ADRENALINE_SPUR_HINT",      [kTechDataMapName] = AdrenalineSpur.kMapName,                 [kTechDataDisplayName] = "ADRENALINE_SPUR",  [kTechDataCostKey] = kSpurCost,     [kTechDataRequiresInfestation] = true,    [kTechDataBuildTime] = kSpurBuildTime, [kTechDataModel] = Spur.kModelName,           [kTechDataMaxHealth] = kSpurHealth, [kTechDataMaxArmor] = kSpurArmor,  [kTechDataPointValue] = kSpurPointValue, [kTechDataTooltipInfo] = "ADRENALINE_SPUR_TOOLTIP", [kTechDataGrows] = true},

        { [kTechDataId] = kTechId.Shift, [kTechDataHint] = "SHIFT_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Shift.kMapName,                        [kTechDataDisplayName] = "SHIFT",  [kTechDataRequiresInfestation] = true, [kTechDataCostKey] = kShiftCost,    [kTechDataHotkey] = Move.S,        [kTechDataBuildTime] = kShiftBuildTime, [kTechDataModel] = Shift.kModelName,           [kTechDataMaxHealth] = kShiftHealth,  [kTechDataMaxArmor] = kShiftArmor,  [kTechDataInitialEnergy] = kShiftInitialEnergy,      [kTechDataMaxEnergy] = kShiftMaxEnergy, [kTechDataPointValue] = kShiftPointValue, [kVisualRange] = kEchoRange, [kTechDataTooltipInfo] = "SHIFT_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.EvolveEcho, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "EVOLVE_ECHO", [kTechDataCostKey] = kEvolveEchoCost, [kTechDataResearchTimeKey] = kEvolveEchoResearchTime, [kTechDataTooltipInfo] = "EVOLVE_ECHO_TOOLTIP"},

        { [kTechDataId] = kTechId.Veil, [kTechDataHint] = "VEIL_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",     [kTechDataMapName] = Veil.kMapName,                         [kTechDataDisplayName] = "VEIL",  [kTechDataCostKey] = kVeilCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kVeilBuildTime, [kTechDataModel] = Veil.kModelName,           [kTechDataMaxHealth] = kVeilHealth, [kTechDataMaxArmor] = kVeilArmor,  [kTechDataPointValue] = kVeilPointValue, [kTechDataTooltipInfo] = "VEIL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeSilenceVeil,   [kTechDataDisplayName] = "UPGRADE_SILENCE_VEIL",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_SILENCE_VEIL_TOOLTIP", [kTechDataCostKey] = kSilenceResearchCost, [kTechDataResearchTimeKey] =  kSilenceResearchTime},
        { [kTechDataId] = kTechId.SilenceVeil,  [kTechDataHint] = "SILENCE_VEIL_HINT",        [kTechDataMapName] = SilenceVeil.kMapName,                 [kTechDataDisplayName] = "SILENCE_VEIL",  [kTechDataCostKey] = kVeilCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kVeilBuildTime, [kTechDataModel] = Veil.kModelName,           [kTechDataMaxHealth] = kVeilHealth, [kTechDataMaxArmor] = kVeilArmor,  [kTechDataPointValue] = kVeilPointValue, [kTechDataTooltipInfo] = "SILENCE_VEIL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeCamouflageVeil,   [kTechDataDisplayName] = "UPGRADE_CAMOUFLAGE_VEIL",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_CAMOUFLAGE_VEIL_TOOLTIP", [kTechDataCostKey] = kCamouflageResearchCost, [kTechDataResearchTimeKey] =  kCamouflageResearchTime},
        { [kTechDataId] = kTechId.CamouflageVeil,  [kTechDataHint] = "CAMOUFLAGE_VEIL_HINT",        [kTechDataMapName] = CamouflageVeil.kMapName,                 [kTechDataDisplayName] = "CAMOUFLAGE_VEIL",  [kTechDataCostKey] = kVeilCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kVeilBuildTime, [kTechDataModel] = Veil.kModelName,           [kTechDataMaxHealth] = kVeilHealth, [kTechDataMaxArmor] = kVeilArmor,  [kTechDataPointValue] = kVeilPointValue, [kTechDataTooltipInfo] = "CAMOUFLAGE_VEIL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeAuraVeil,   [kTechDataImplemented] = false, [kTechDataDisplayName] = "UPGRADE_AURA_VEIL",  [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataTooltipInfo] = "UPGRADE_AURA_VEIL_TOOLTIP", [kTechDataCostKey] = kAuraResearchCost, [kTechDataResearchTimeKey] =  kAuraResearchTime},
        { [kTechDataId] = kTechId.AuraVeil,      [kTechDataImplemented] = false, [kTechDataMapName] = AuraVeil.kMapName,                 [kTechDataDisplayName] = "AURA_VEIL",  [kTechDataCostKey] = kVeilCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kVeilBuildTime, [kTechDataModel] = Veil.kModelName,           [kTechDataMaxHealth] = kVeilHealth, [kTechDataMaxArmor] = kVeilArmor,  [kTechDataPointValue] = kVeilPointValue, [kTechDataTooltipInfo] = "AURA_VEIL_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeFeintVeil,   [kTechDataDisplayName] = "UPGRADE_FEINT_VEIL",  [kTechDataTooltipInfo] = "UPGRADE_FEINT_VEIL_TOOLTIP", [kTechDataHint] = "COMM_SEL_UPGRADING", [kTechDataCostKey] = kFeintResearchCost, [kTechDataResearchTimeKey] =  kFeintResearchTime},
        { [kTechDataId] = kTechId.FeintVeil,  [kTechDataHint] = "FEINT_VEIL_HINT",    [kTechDataMapName] = FeintVeil.kMapName,                 [kTechDataDisplayName] = "FEINT_VEIL",  [kTechDataCostKey] = kVeilCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kVeilBuildTime, [kTechDataModel] = Veil.kModelName,           [kTechDataMaxHealth] = kVeilHealth, [kTechDataMaxArmor] = kVeilArmor,  [kTechDataPointValue] = kVeilPointValue, [kTechDataTooltipInfo] = "AURA_VEIL_TOOLTIP", [kTechDataGrows] = true},


        { [kTechDataId] = kTechId.TeleportHydra, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_HYDRA",  [kTechDataCostKey] = kEchoHydraCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Hydra.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportWhip, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_WHIP",  [kTechDataCostKey] = kEchoWhipCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Whip.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportCrag, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_CRAG",  [kTechDataCostKey] = kEchoCragCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Crag.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportShade, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_SHADE",  [kTechDataCostKey] = kEchoShadeCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Shade.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportShift, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_SHIFT",  [kTechDataCostKey] = kEchoShiftCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Shift.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportVeil, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_VEIL",  [kTechDataCostKey] = kEchoVeilCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Veil.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportSpur, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_SPUR",  [kTechDataCostKey] = kEchoSpurCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Spur.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportShell, [kTechDataRequiresMature] = true,  [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_SHELL",  [kTechDataCostKey] = kEchoShellCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Shell.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.TeleportHive, [kTechDataRequiresMature] = true, [kTechDataImplemented] = false, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",  [kTechDataDisplayName] = "ECHO_HIVE",  [kTechDataCostKey] = kEchoHiveCost,   [kTechDataRequiresInfestation] = false, [kTechDataModel] = Hive.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP", [kTechDataSpawnHeightOffset] = 2.494, [kStructureAttachClass] = "TechPoint"},
        { [kTechDataId] = kTechId.TeleportEgg, [kTechDataRequiresMature] = true, [kTechDataGhostModelClass] = "TeleportAlienGhostModel",   [kTechDataDisplayName] = "ECHO_EGG",  [kTechDataCostKey] = kEchoEggCost,   [kTechDataRequiresInfestation] = true, [kTechDataModel] = Egg.kModelName, [kTechDataTooltipInfo] = "ECHO_TOOLTIP"},


        { [kTechDataId] = kTechId.Shade, [kTechDataHint] = "SHADE_HINT", [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Shade.kMapName,                        [kTechDataDisplayName] = "SHADE",  [kTechDataCostKey] = kShadeCost,      [kTechDataRequiresInfestation] = true,     [kTechDataBuildTime] = kShadeBuildTime, [kTechDataHotkey] = Move.D, [kTechDataModel] = Shade.kModelName,           [kTechDataMaxHealth] = kShadeHealth, [kTechDataMaxArmor] = kShadeArmor,   [kTechDataInitialEnergy] = kShadeInitialEnergy,      [kTechDataMaxEnergy] = kShadeMaxEnergy, [kTechDataPointValue] = kShadePointValue, [kVisualRange] = Shade.kCloakRadius, [kTechDataMaxExtents] = Vector(1, 1.3, .4), [kTechDataTooltipInfo] = "SHADE_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.EvolveHallucinations, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "EVOLVE_HALLUCINATIONS",  [kTechDataCostKey] = kEvolveHallucinationsCost, [kTechDataResearchTimeKey] = kEvolveHallucinationsResearchTime, [kTechDataTooltipInfo] = "EVOLVE_HALLUCINATIONS_TOOLTIP" },

        { [kTechDataId] = kTechId.Web, [kTechDataModel] = Bomb.kModelName, [kTechDataSpecifyOrientation] = true,  [kTechDataGhostModelClass] = "WebGhostModel", [kTechDataMaxAmount] = kNumWebsPerGorge,  [kTechDataDisplayName] = "WEB", [kTechDataCostKey] = kWebBuildCost, [kTechDataTooltipInfo] = "WEB_TOOLTIP" },        
        { [kTechDataId] = kTechId.Hydra, [kTechDataHint] = "HYDRA_HINT", [kTechDataTooltipInfo] = "HYDRA_TOOLTIP", [kTechDataDamageType] = kHydraAttackDamageType, [kTechDataAllowConsumeDrop] = true, [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMaxAmount] = kHydrasPerHive,       [kTechDataMapName] = Hydra.kMapName,                        [kTechDataDisplayName] = "HYDRA",           [kTechDataCostKey] = kHydraCost,       [kTechDataBuildTime] = kHydraBuildTime, [kTechDataMaxHealth] = kHydraHealth, [kTechDataMaxArmor] = kHydraArmor, [kTechDataModel] = Hydra.kModelName, [kVisualRange] = Hydra.kRange, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kHydraPointValue, [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.Clog, [kTechDataGhostModelClass] = "AlienGhostModel",  [kTechDataAllowConsumeDrop] = true, [kTechDataTooltipInfo] = "CLOG_TOOLTIP", [kTechDataAllowStacking] = true,  [kTechDataMaxAmount] = kClogsPerHive,     [kTechDataMapName] = Clog.kMapName,                        [kTechDataDisplayName] = "CLOG",           [kTechDataCostKey] = kClogCost,  [kTechDataMaxHealth] = kClogHealth, [kTechDataMaxArmor] = kClogArmor, [kTechDataModel] = Clog.kModelName, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kClogPointValue },
        { [kTechDataId] = kTechId.GorgeTunnel, [kTechDataMaxExtents] = Vector(1.2, 1.2, 1.2), [kTechDataTooltipInfo] = "GORGE_TUNNEL_TOOLTIP", [kTechDataGhostModelClass] = "AlienGhostModel",  [kTechDataAllowConsumeDrop] = true, [kTechDataAllowStacking] = false,  [kTechDataMaxAmount] = kNumGorgeTunnels,     [kTechDataMapName] = TunnelEntrance.kMapName,    [kTechDataDisplayName] = "TUNNEL_ENTRANCE",           [kTechDataCostKey] = kGorgeTunnelCost,  [kTechDataMaxHealth] = kTunnelEntranceHealth, [kTechDataMaxArmor] = kTunnelEntranceArmor, [kTechDataBuildTime] = kGorgeTunnelBuildTime, [kTechDataModel] = TunnelEntrance.kModelName, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kTunnelEntrancePointValue },
        { [kTechDataId] = kTechId.GorgeTunnelTech, [kTechDataDisplayName] = "GORGE_TUNNEL_TECH", [kTechDataTooltipInfo] = "GORGE_TUNNEL_TECH_TOOLTIP", [kTechDataCostKey] = kGorgeTunnelResearchCost, [kTechDataResearchTimeKey] = kGorgeTunnelResearchTime },
        { [kTechDataId] = kTechId.Babbler,  [kTechDataMapName] = Babbler.kMapName,  [kTechDataDisplayName] = "BABBLER",  [kTechDataModel] = Babbler.kModelName, [kTechDataMaxHealth] = kBabblerHealth, [kTechDataMaxArmor] = kBabblerArmor, [kTechDataPointValue] = kBabblerPointValue, [kTechDataTooltipInfo] = "BABBLER_TOOLTIP" },
        { [kTechDataId] = kTechId.BabblerEgg,  [kTechDataAllowConsumeDrop] = true, [kTechDataMaxAmount] = kNumBabblerEggsPerGorge, [kTechDataCostKey] = kBabblerCost,   [kTechDataBuildTime] = kBabblerEggBuildTime,          [kTechDataMapName] = BabblerEgg.kMapName,  [kTechDataDisplayName] = "BABBLER_EGG",  [kTechDataModel] = BabblerEgg.kModelName, [kTechDataMaxHealth] = kBabblerEggHealth, [kTechDataMaxArmor] = kBabblerEggArmor, [kTechDataPointValue] = kBabblerEggPointValue, [kTechDataTooltipInfo] = "BABBLER_EGG_TOOLTIP" },


        { [kTechDataId] = kTechId.Cyst, [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_NO_CYST_PARENT_FOUND", [kTechDataOverrideCoordsMethod] = AlignCyst, [kTechDataHint] = "CYST_HINT", [kTechDataCooldown] = kCystCooldown, [kTechDataGhostModelClass] = "AlienGhostModel",    [kTechDataMapName] = Cyst.kMapName,                      [kTechDataDisplayName] = "CYST",     [kTechDataTooltipInfo] = "CYST_TOOLTIP",    [kTechDataCostKey] = kCystCost,       [kTechDataBuildTime] = kCystBuildTime, [kTechDataMaxHealth] = kCystHealth, [kTechDataMaxArmor] = kCystArmor, [kTechDataModel] = Cyst.kModelName, [kVisualRange] = kInfestationRadius, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kCystPointValue, [kTechDataGrows] = false,  [kTechDataBuildRequiresMethod]=GetCystParentAvailable, [kTechDataGhostGuidesMethod]=GetCystGhostGuides }, 
        { [kTechDataId] = kTechId.EnzymeCloud,     [kTechDataMapName] = EnzymeCloud.kMapName, [kTechDataDisplayName] = "ENZYME_CLOUD", [kTechDataCostKey] = kEnzymeCloudCost, [kTechDataTooltipInfo] =  "ENZYME_CLOUD_TOOLTIP"},
        { [kTechDataId] = kTechId.Rupture,   [kTechDataRequiresMature] = true,  [kTechDataMapName] = Rupture.kMapName, [kTechDataDisplayName] = "RUPTURE", [kTechDataCostKey] = kRuptureCost, [kTechDataTooltipInfo] =  "RUPTURE_TOOLTIP"},

        // Alien structure abilities and their energy costs
        { [kTechDataId] = kTechId.CragHeal,         [kTechDataDisplayName] = "HEAL",     [kTechDataCostKey] = kCragHealCost, [kTechDataTooltipInfo] = "CRAG_HEAL_TOOLTIP"},
        { [kTechDataId] = kTechId.CragUmbra,        [kTechDataDisplayName] = "UMBRA",     [kTechDataCostKey] = kCragUmbraCost, [kVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "CRAG_UMBRA_TOOLTIP"},
        { [kTechDataId] = kTechId.HealWave,         [kTechDataDisplayName] = "HEAL_WAVE",       [kTechDataCostKey] = kCragHealWaveCost,  [kTechDataTooltipInfo] = "HEAL_WAVE_TOOLTIP"},
        
        { [kTechDataId] = kTechId.WhipBombard,           [kTechDataHint] = "BOMBARD_WHIP_HINT", [kTechDataDisplayName] = "BOMBARD",         [kTechDataTooltipInfo] = "WHIP_BOMBARD_TOOLTIP", [kTechDataCostKey] = kWhipBombardCost },
        { [kTechDataId] = kTechId.WhipBombardCancel,      [kTechDataDisplayName] = "CANCEL",         [kTechDataTooltipInfo] = "WHIP_BOMBARD_CANCEL"},
        { [kTechDataId] = kTechId.WhipBomb,              [kTechDataMapName] = WhipBomb.kMapName,        [kTechDataDamageType] = kWhipBombDamageType,    [kTechDataModel] = "", [kTechDataDisplayName] = "WHIPBOMB", },

        { [kTechDataId] = kTechId.ShiftEcho,     [kTechDataDisplayName] = "ECHO",  [kTechDataTooltipInfo] = "SHIFT_ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.ShiftHatch, [kTechDataCooldown] = kHatchCooldown,  [kTechDataMaxExtents] = Vector(Onos.XExtents, Onos.YExtents, Onos.ZExtents),  [kStructureAttachRange] = kShiftHatchRange,      [kTechDataBuildRequiresMethod] = GetShiftIsBuilt, [kTechDataGhostGuidesMethod] = GetShiftHatchGhostGuides, [kTechDataMapName] = Egg.kMapName, [kTechDataGhostModelClass] = "AlienGhostModel", [kTechDataModel] = Egg.kModelName, [kTechDataRequiresInfestation] = true,  [kTechDataDisplayName] = "HATCH",      [kTechDataTooltipInfo] = "SHIFT_HATCH_TOOLTIP", [kTechDataCostKey] = kShiftHatchCost},
        { [kTechDataId] = kTechId.ShiftEnergize,         [kTechDataDisplayName] = "ENERGIZE",    [kTechDataTooltipInfo] = "SHIFT_ENERGIZE_TOOLTIP"},

        { [kTechDataId] = kTechId.ShadeDisorient,         [kTechDataDisplayName] = "DISORIENT",      [kTechDataHotkey] = Move.D,  [kVisualRange] = Shade.kCloakRadius, [kTechDataTooltipInfo] = "SHADE_DISORIENT_TOOLTIP"},        
        { [kTechDataId] = kTechId.ShadeCloak,             [kTechDataDisplayName] = "CLOAK",      [kTechDataHotkey] = Move.C,  [kTechDataTooltipInfo] = "SHADE_CLOAK_TOOLTIP"},        
        { [kTechDataId] = kTechId.ShadeInk,             [kTechDataDisplayName] = "INK",      [kTechDataHotkey] = Move.C,     [kTechDataCostKey] = kShadeInkCost, [kTechDataTooltipInfo] = "SHADE_INK_TOOLTIP"},   
        { [kTechDataId] = kTechId.ShadePhantomMenu,            [kTechDataDisplayName] = "PHANTOM",     [kTechDataHotkey] = Move.P, [kTechDataImplemented] = true },
        { [kTechDataId] = kTechId.ShadePhantomStructuresMenu,  [kTechDataDisplayName] = "PHANTOM",     [kTechDataHotkey] = Move.P, [kTechDataImplemented] = true },

        { [kTechDataId] = kTechId.HallucinateDrifter, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_DRIFTER", [kTechDataTooltipInfo] = "HALLUCINATE_DRIFTER_TOOLTIP", [kTechDataCostKey] = kHallucinateDrifterEnergyCost },
        { [kTechDataId] = kTechId.HallucinateSkulk, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_SKULK", [kTechDataTooltipInfo] = "HALLUCINATE_SKULK_TOOLTIP", [kTechDataCostKey] = kHallucinateSkulkEnergyCost },
        { [kTechDataId] = kTechId.HallucinateGorge, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_GORGE", [kTechDataTooltipInfo] = "HALLUCINATE_GORGE_TOOLTIP", [kTechDataCostKey] = kHallucinateGorgeEnergyCost },
        { [kTechDataId] = kTechId.HallucinateLerk, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_LERK", [kTechDataTooltipInfo] = "HALLUCINATE_LERK_TOOLTIP", [kTechDataCostKey] = kHallucinateLerkEnergyCost },
        { [kTechDataId] = kTechId.HallucinateFade, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_FADE", [kTechDataTooltipInfo] = "HALLUCINATE_FADE_TOOLTIP", [kTechDataCostKey] = kHallucinateFadeEnergyCost },
        { [kTechDataId] = kTechId.HallucinateOnos, [kTechDataRequiresMature] = true, [kTechDataDisplayName] = "HALLUCINATE_ONOS", [kTechDataTooltipInfo] = "HALLUCINATE_ONOS_TOOLTIP", [kTechDataCostKey] = kHallucinateOnosEnergyCost },
        
        { [kTechDataId] = kTechId.HallucinateHive, [kTechDataRequiresMature] = true, [kTechDataSpawnHeightOffset] = 2.494, [kStructureAttachClass] = "TechPoint", [kTechDataDisplayName] =      "HALLUCINATE_HIVE",      [kTechDataModel] = Hive.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_HIVE_TOOLTIP", [kTechDataCostKey] = kHallucinateHiveEnergyCost },
        { [kTechDataId] = kTechId.HallucinateWhip, [kTechDataRequiresMature] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] =      "HALLUCINATE_WHIP",      [kTechDataModel] = Whip.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_WHIP_TOOLTIP", [kTechDataCostKey] = kHallucinateWhipEnergyCost },
        { [kTechDataId] = kTechId.HallucinateShade, [kTechDataRequiresMature] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] =     "HALLUCINATE_SHADE",     [kTechDataModel] = Shade.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_SHADE_TOOLTIP", [kTechDataCostKey] = kHallucinateShadeEnergyCost },
        { [kTechDataId] = kTechId.HallucinateCrag, [kTechDataRequiresMature] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] =      "HALLUCINATE_CRAG",      [kTechDataModel] = Crag.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_CRAG_TOOLTIP", [kTechDataCostKey] = kHallucinateCragEnergyCost },
        { [kTechDataId] = kTechId.HallucinateShift, [kTechDataRequiresMature] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] =     "HALLUCINATE_SHIFT",     [kTechDataModel] = Shift.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_SHIFT_TOOLTIP", [kTechDataCostKey] = kHallucinateShiftEnergyCost },        
        { [kTechDataId] = kTechId.HallucinateHarvester, [kTechDataRequiresMature] = true, [kStructureAttachClass] = "ResourcePoint", [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] = "HALLUCINATE_HARVESTER", [kTechDataModel] = Harvester.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_HARVESTER_TOOLTIP", [kTechDataCostKey] = kHallucinateHarvesterEnergyCost },
        { [kTechDataId] = kTechId.HallucinateHydra, [kTechDataRequiresMature] = true, [kTechDataEngagementDistance] = 3.5, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] =     "HALLUCINATE_HYDRA",     [kTechDataModel] = Hydra.kModelName, [kTechDataTooltipInfo] = "HALLUCINATE_HYDRA_TOOLTIP", [kTechDataCostKey] = kHallucinateHydraEnergyCost },
        
        { [kTechDataId] = kTechId.WhipUnroot,           [kTechDataDisplayName] = "UNROOT_WHIP",     [kTechDataTooltipInfo] = "UNROOT_WHIP_TOOLTIP", [kTechDataMenuPriority] = 1},
        { [kTechDataId] = kTechId.WhipRoot,             [kTechDataDisplayName] = "ROOT_WHIP",       [kTechDataTooltipInfo] = "ROOT_WHIP_TOOLTIP", [kTechDataMenuPriority] = 2},

        // Alien lifeforms
        { [kTechDataId] = kTechId.Skulk,                 [kTechDataMapName] = Skulk.kMapName, [kTechDataGestateName] = Skulk.kMapName,                      [kTechDataGestateTime] = kSkulkGestateTime, [kTechDataDisplayName] = "SKULK",  [kTechDataTooltipInfo] = "SKULK_TOOLTIP",        [kTechDataModel] = Skulk.kModelName, [kTechDataCostKey] = kSkulkCost, [kTechDataMaxHealth] = Skulk.kHealth, [kTechDataMaxArmor] = Skulk.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents), [kTechDataPointValue] = kSkulkPointValue},
        { [kTechDataId] = kTechId.Gorge,                 [kTechDataMapName] = Gorge.kMapName, [kTechDataGestateName] = Gorge.kMapName,                      [kTechDataGestateTime] = kGorgeGestateTime, [kTechDataDisplayName] = "GORGE", [kTechDataTooltipInfo] = "GORGE_TOOLTIP",          [kTechDataModel] = Gorge.kModelName,[kTechDataCostKey] = kGorgeCost, [kTechDataMaxHealth] = kGorgeHealth, [kTechDataMaxArmor] = kGorgeArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Gorge.kXZExtents, Gorge.kYExtents, Gorge.kXZExtents), [kTechDataPointValue] = kGorgePointValue},
        { [kTechDataId] = kTechId.Lerk,                  [kTechDataMapName] = Lerk.kMapName, [kTechDataGestateName] = Lerk.kMapName,                       [kTechDataGestateTime] = kLerkGestateTime, [kTechDataDisplayName] = "LERK",   [kTechDataTooltipInfo] = "LERK_TOOLTIP",         [kTechDataModel] = Lerk.kModelName,[kTechDataCostKey] = kLerkCost, [kTechDataMaxHealth] = kLerkHealth, [kTechDataMaxArmor] = kLerkArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Lerk.XZExtents, Lerk.YExtents, Lerk.XZExtents), [kTechDataPointValue] = kLerkPointValue},
        { [kTechDataId] = kTechId.Fade,                  [kTechDataMapName] = Fade.kMapName, [kTechDataGestateName] = Fade.kMapName,                       [kTechDataGestateTime] = kFadeGestateTime, [kTechDataDisplayName] = "FADE",   [kTechDataTooltipInfo] = "FADE_TOOLTIP",         [kTechDataModel] = Fade.kModelName,[kTechDataCostKey] = kFadeCost, [kTechDataMaxHealth] = Fade.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxArmor] = Fade.kArmor, [kTechDataMaxExtents] = Vector(Fade.XZExtents, Fade.YExtents, Fade.XZExtents), [kTechDataPointValue] = kFadePointValue},        
        { [kTechDataId] = kTechId.Onos,                  [kTechDataMapName] = Onos.kMapName, [kTechDataGestateName] = Onos.kMapName,                       [kTechDataGestateTime] = kOnosGestateTime, [kTechDataDisplayName] = "ONOS",   [kTechDataTooltipInfo] = "ONOS_TOOLTIP", [kTechDataModel] = Onos.kModelName,[kTechDataCostKey] = kOnosCost, [kTechDataMaxHealth] = Onos.kHealth, [kTechDataEngagementDistance] = kOnosEngagementDistance, [kTechDataMaxArmor] = Onos.kArmor, [kTechDataMaxExtents] = Vector(Onos.XExtents, Onos.YExtents, Onos.ZExtents), [kTechDataPointValue] = kOnosPointValue},
        { [kTechDataId] = kTechId.Embryo,                [kTechDataMapName] = Embryo.kMapName, [kTechDataGestateName] = Embryo.kMapName,                     [kTechDataDisplayName] = "EMBRYO", [kTechDataModel] = Embryo.kModelName, [kTechDataMaxExtents] = Vector(Embryo.kXExtents, Embryo.kYExtents, Embryo.kZExtents)},
        { [kTechDataId] = kTechId.AlienCommander,        [kTechDataMapName] = AlienCommander.kMapName, [kTechDataDisplayName] = "ALIEN COMMANDER", [kTechDataModel] = ""},
        
        { [kTechDataId] = kTechId.Hallucination,         [kTechDataMapName] = Hallucination.kMapName, [kTechDataDisplayName] = "HALLUCINATION", [kTechDataCostKey] = kHallucinationCost, [kTechDataEngagementDistance] = kPlayerEngagementDistance },
        
        // Lifeform purchases
        { [kTechDataId] = kTechId.Carapace,       [kTechDataCategory] = kTechId.CragHive,    [kTechDataDisplayName] = "CARAPACE",       [kTechDataSponitorCode] = "C",   [kTechDataCostKey] = kCarapaceCost, [kTechDataTooltipInfo] = "CARAPACE_TOOLTIP", },
        { [kTechDataId] = kTechId.Regeneration,   [kTechDataCategory] = kTechId.CragHive,    [kTechDataDisplayName] = "REGENERATION",   [kTechDataSponitorCode] = "R",   [kTechDataCostKey] = kRegenerationCost, [kTechDataTooltipInfo] = "REGENERATION_TOOLTIP", },
        { [kTechDataId] = kTechId.Silence,        [kTechDataCategory] = kTechId.ShadeHive,   [kTechDataDisplayName] = "SILENCE",        [kTechDataSponitorCode] = "S",   [kTechDataTooltipInfo] = "SILENCE_TOOLTIP", [kTechDataCostKey] = kSilenceCost },
        { [kTechDataId] = kTechId.Camouflage,     [kTechDataCategory] = kTechId.ShadeHive,   [kTechDataDisplayName] = "CAMOUFLAGE",     [kTechDataSponitorCode] = "M",   [kTechDataTooltipInfo] = "CAMOUFLAGE_TOOLTIP", [kTechDataCostKey] = kCamouflageCost },
        { [kTechDataId] = kTechId.Feint,          [kTechDataCategory] = kTechId.ShadeHive,   [kTechDataDisplayName] = "FEINT",          [kTechDataSponitorCode] = "F",   [kTechDataTooltipInfo] = "FEINT_TOOLTIP", [kTechDataCostKey] = kFeintCost },
        
        { [kTechDataId] = kTechId.Celerity,       [kTechDataCategory] = kTechId.ShiftHive,   [kTechDataDisplayName] = "CELERITY",       [kTechDataSponitorCode] = "L",   [kTechDataTooltipInfo] = "CELERITY_TOOLTIP", [kTechDataCostKey] = kCelerityCost },
        { [kTechDataId] = kTechId.Adrenaline,     [kTechDataCategory] = kTechId.ShiftHive,   [kTechDataDisplayName] = "ADRENALINE",     [kTechDataSponitorCode] = "A",   [kTechDataTooltipInfo] = "ADRENALINE_TOOLTIP", [kTechDataCostKey] = kAdrenalineCost },
        { [kTechDataId] = kTechId.HyperMutation,  [kTechDataCategory] = kTechId.ShiftHive,   [kTechDataDisplayName] = "HYPERMUTATION",  [kTechDataSponitorCode] = "H",   [kTechDataTooltipInfo] = "HYPERMUTATION_TOOLTIP", [kTechDataCostKey] = kHyperMutationCost },

        // Alien markers
        { [kTechDataId] = kTechId.ThreatMarker,            [kTechDataImplemented] = true,      [kTechDataDisplayName] = "MARK_THREAT", [kTechDataTooltipInfo] = "PHEROMONE_THREAT_TOOLTIP",},
        { [kTechDataId] = kTechId.NeedHealingMarker,       [kTechDataImplemented] = true,      [kTechDataDisplayName] = "NEED_HEALING_HERE", [kTechDataTooltipInfo] = "PHEROMONE_HEAL_TOOLTIP",},
        { [kTechDataId] = kTechId.WeakMarker,              [kTechDataImplemented] = true,      [kTechDataDisplayName] = "WEAK_HERE", [kTechDataTooltipInfo] = "PHEROMONE_HEAL_TOOLTIP",},
        { [kTechDataId] = kTechId.ExpandingMarker,         [kTechDataImplemented] = true,      [kTechDataDisplayName] = "EXPANDING_HERE", [kTechDataTooltipInfo] = "PHEROMONE_EXPANDING_TOOLTIP",},

        { [kTechDataId] = kTechId.NutrientMist, [kTechDataMapName] = NutrientMist.kMapName, [kTechDataAllowStacking] = true, [kTechDataIgnorePathingMesh] = true, [kTechDataCollideWithWorldOnly] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] = "NUTRIENT_MIST", [kTechDataCostKey] = kNutrientMistCost, [kTechDataTooltipInfo] =  "NUTRIENT_MIST_TOOLTIP"},
        { [kTechDataId] = kTechId.BoneWall, [kTechDataMaxExtents] = Vector(8, 1, 8), [kTechDataGhostModelClass] = "AlienGhostModel", [kTechDataModel] = BoneWall.kModelName, [kTechDataMapName] = BoneWall.kMapName, [kTechDataOverrideCoordsMethod] = AlignBoneWalls, [kTechDataMaxHealth] = kBoneWallHealth, [kTechDataMaxArmor] = kBoneWallArmor,  [kTechDataPointValue] = kBoneWallPointValue, [kTechDataCooldown] = kBoneWallCooldown, [kTechDataIgnorePathingMesh] = true, [kTechDataCollideWithWorldOnly] = true, [kTechDataRequiresInfestation] = true, [kTechDataDisplayName] = "INFESTATION_SPIKE", [kTechDataCostKey] = kBoneWallCost, [kTechDataTooltipInfo] =  "INFESTATION_SPIKE_TOOLTIP"},
        
        // Alerts
        { [kTechDataId] = kTechId.MarineAlertSentryUnderAttack,                 [kTechDataAlertSound] = Sentry.kUnderAttackSound,                           [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 0, [kTechDataAlertText] = "MARINE_ALERT_SENTRY_UNDERATTACK", [kTechDataAlertTeam] = false},
        { [kTechDataId] = kTechId.MarineAlertSoldierUnderAttack,                [kTechDataAlertSound] = MarineCommander.kSoldierUnderAttackSound,           [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 0, [kTechDataAlertText] = "MARINE_ALERT_SOLDIER_UNDERATTACK", [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.MarineAlertStructureUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 1, [kTechDataAlertText] = "MARINE_ALERT_STRUCTURE_UNDERATTACK", [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.MarineAlertExtractorUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 1, [kTechDataAlertText] = "MARINE_ALERT_EXTRACTOR_UNDERATTACK", [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true},          
        { [kTechDataId] = kTechId.MarineAlertCommandStationUnderAttack,         [kTechDataAlertSound] = CommandStation.kUnderAttackSound,                   [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 2, [kTechDataAlertText] = "MARINE_ALERT_COMMANDSTATION_UNDERAT",  [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true, [kTechDataAlertSendTeamMessage] = kTeamMessageTypes.CommandStationUnderAttack},
        { [kTechDataId] = kTechId.MarineAlertInfantryPortalUnderAttack,         [kTechDataAlertSound] = InfantryPortal.kUnderAttackSound,                   [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 1, [kTechDataAlertText] = "MARINE_ALERT_INFANTRYPORTAL_UNDERAT",  [kTechDataAlertTeam] = true, [kTechDataAlertSendTeamMessage] = kTeamMessageTypes.IPUnderAttack},

        { [kTechDataId] = kTechId.MarineAlertCommandStationComplete,            [kTechDataAlertSound] = MarineCommander.kCommandStationCompletedSoundName,  [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_COMMAND_STATION_COMPLETE", [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true,}, 
        { [kTechDataId] = kTechId.MarineAlertConstructionComplete,              [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,       [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_CONSTRUCTION_COMPLETE", [kTechDataAlertTeam] = false}, 
        { [kTechDataId] = kTechId.MarineCommanderEjected,                       [kTechDataAlertSound] = MarineCommander.kCommanderEjectedSoundName,         [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_COMMANDER_EJECTED",    [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.MarineAlertSentryFiring,                      [kTechDataAlertSound] = MarineCommander.kSentryFiringSoundName,             [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_SENTRY_FIRING"},
        { [kTechDataId] = kTechId.MarineAlertSoldierLost,                       [kTechDataAlertSound] = MarineCommander.kSoldierLostSoundName,              [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_SOLDIER_LOST",    [kTechDataAlertOthersOnly] = true},
        { [kTechDataId] = kTechId.MarineAlertAcknowledge,                       [kTechDataAlertSound] = MarineCommander.kSoldierAcknowledgesSoundName,      [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_ACKNOWLEDGE"},
        { [kTechDataId] = kTechId.MarineAlertNeedAmmo,      [kTechDataAlertIgnoreInterval] = true, [kTechDataAlertSound] = MarineCommander.kSoldierNeedsAmmoSoundName,         [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_AMMO"},
        { [kTechDataId] = kTechId.MarineAlertNeedMedpack,   [kTechDataAlertIgnoreInterval] = true, [kTechDataAlertSound] = MarineCommander.kSoldierNeedsHealthSoundName,       [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_MEDPACK"},
        { [kTechDataId] = kTechId.MarineAlertNeedOrder,     [kTechDataAlertIgnoreInterval] = true, [kTechDataAlertSound] = MarineCommander.kSoldierNeedsOrderSoundName,        [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_ORDER"},
        { [kTechDataId] = kTechId.MarineAlertUpgradeComplete,                   [kTechDataAlertSound] = MarineCommander.kUpgradeCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_UPGRADE_COMPLETE"},
        { [kTechDataId] = kTechId.MarineAlertResearchComplete,                  [kTechDataAlertSound] = MarineCommander.kResearchCompleteSoundName,         [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_RESEARCH_COMPLETE"},
        { [kTechDataId] = kTechId.MarineAlertManufactureComplete,               [kTechDataAlertSound] = MarineCommander.kManufactureCompleteSoundName,      [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_MANUFACTURE_COMPLETE"},
        { [kTechDataId] = kTechId.MarineAlertNotEnoughResources,                [kTechDataAlertSound] = Player.kNotEnoughResourcesSound,                    [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_NOT_ENOUGH_RESOURCES"},
        { [kTechDataId] = kTechId.MarineAlertMACBlocked,                        [kTechDataAlertType]  = kAlertType.Info,                                     [kTechDataAlertText] = "MARINE_ALERT_MAC_BLOCKED"},
        { [kTechDataId] = kTechId.MarineAlertOrderComplete,                     [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,       [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_ORDER_COMPLETE"},           
        { [kTechDataId] = kTechId.MACAlertConstructionComplete,                 [kTechDataAlertSound] = MarineCommander.kMACObjectiveCompletedSoundName,    [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_CONSTRUCTION_COMPLETE"},        
      
        { [kTechDataId] = kTechId.AlienAlertNeedMist,   [kTechDataAlertIgnoreInterval] = true, [kTechDataAlertSound] = AlienCommander.kSoldierNeedsMistSoundName,       [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "ALIEN_ALERT_NEED_MIST"},
        { [kTechDataId] = kTechId.AlienAlertNeedEnzyme,   [kTechDataAlertIgnoreInterval] = true, [kTechDataAlertSound] = AlienCommander.kSoldierNeedsEnzymeSoundName,       [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "ALIEN_ALERT_NEED_ENZYME"},
        { [kTechDataId] = kTechId.AlienAlertHiveUnderAttack,                    [kTechDataAlertSound] = Hive.kUnderAttackSound,                             [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 2, [kTechDataAlertText] = "ALIEN_ALERT_HIVE_UNDERATTACK",             [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true, [kTechDataAlertSendTeamMessage] = kTeamMessageTypes.HiveUnderAttack},
        { [kTechDataId] = kTechId.AlienAlertStructureUnderAttack,               [kTechDataAlertSound] = AlienCommander.kStructureUnderAttackSound,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertPriority] = 0, [kTechDataAlertText] = "ALIEN_ALERT_STRUCTURE_UNDERATTACK",        [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.AlienAlertHarvesterUnderAttack,               [kTechDataAlertSound] = AlienCommander.kHarvesterUnderAttackSound,          [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 1, [kTechDataAlertText] = "ALIEN_ALERT_HARVESTER_UNDERATTACK",        [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true},
        { [kTechDataId] = kTechId.AlienAlertLifeformUnderAttack,                [kTechDataAlertSound] = AlienCommander.kLifeformUnderAttackSound,           [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 0, [kTechDataAlertText] = "ALIEN_ALERT_LIFEFORM_UNDERATTACK",         [kTechDataAlertTeam] = true},

        { [kTechDataId] = kTechId.AlienAlertHiveDying,                          [kTechDataAlertSound] = Hive.kDyingSound,                                   [kTechDataAlertType] = kAlertType.Info,   [kTechDataAlertPriority] = 3, [kTechDataAlertText] = "ALIEN_ALERT_HIVE_DYING",                 [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true},        
        { [kTechDataId] = kTechId.AlienAlertHiveComplete,                       [kTechDataAlertSound] = Hive.kCompleteSound,                                [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_HIVE_COMPLETE",    [kTechDataAlertTeam] = true, [kTechDataAlertIgnoreDistance] = true},
        { [kTechDataId] = kTechId.AlienAlertUpgradeComplete,                    [kTechDataAlertSound] = AlienCommander.kUpgradeCompleteSoundName,           [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_UPGRADE_COMPLETE"},
        { [kTechDataId] = kTechId.AlienAlertResearchComplete,                   [kTechDataAlertSound] = AlienCommander.kResearchCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_RESEARCH_COMPLETE"},
        { [kTechDataId] = kTechId.AlienAlertManufactureComplete,                [kTechDataAlertSound] = AlienCommander.kManufactureCompleteSoundName,       [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_MANUFACTURE_COMPLETE"},
        { [kTechDataId] = kTechId.AlienAlertOrderComplete,                      [kTechDataAlertSound] = AlienCommander.kObjectiveCompletedSoundName,        [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_ORDER_COMPLETE"},        
        { [kTechDataId] = kTechId.AlienAlertGorgeBuiltHarvester,                [kTechDataAlertType] = kAlertType.Info,                                                                                 [kTechDataAlertText] = "ALIEN_ALERT_GORGEBUILT_HARVESTER"},
        { [kTechDataId] = kTechId.AlienAlertNotEnoughResources,                 [kTechDataAlertSound] = Alien.kNotEnoughResourcesSound,                     [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_NOTENOUGH_RESOURCES"},
        { [kTechDataId] = kTechId.AlienCommanderEjected,                        [kTechDataAlertSound] = AlienCommander.kCommanderEjectedSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_COMMANDER_EJECTED",    [kTechDataAlertTeam] = true},        

        { [kTechDataId] = kTechId.DeathTrigger,                                 [kTechDataDisplayName] = "DEATH_TRIGGER",                                   [kTechDataMapName] = DeathTrigger.kMapName, [kTechDataModel] = ""},

    }

    return techData

end

kTechData = nil

function LookupTechId(fieldData, fieldName)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if fieldName == nil or fieldName == "" then
    
        Print("LookupTechId(%s, %s) called improperly.", tostring(fieldData), tostring(fieldName))
        return kTechId.None
        
    end

    for index,record in ipairs(kTechData) do 
    
        local currentField = record[fieldName]
        
        if(fieldData == currentField) then
        
            return record[kTechDataId]
            
        end

    end
    
    //Print("LookupTechId(%s, %s) returned kTechId.None", fieldData, fieldName)
    
    return kTechId.None

end

// Table of fieldName tables. Each fieldName table is indexed by techId and returns data.
local cachedTechData = {}

function ClearCachedTechData()
    cachedTechData = {}
end

// Returns true or false. If true, return output in "data"
function GetCachedTechData(techId, fieldName)
    
    local entry = cachedTechData[fieldName]
    
    if entry ~= nil then
    
        return entry[techId]
        
    end
        
    return nil
    
end

function SetCachedTechData(techId, fieldName, data)

    local inserted = false
    
    local entry = cachedTechData[fieldName]
    
    if entry == nil then
    
        cachedTechData[fieldName] = {}
        entry = cachedTechData[fieldName]
        
    end
    
    if entry[techId] == nil then
    
        entry[techId] = data
        inserted = true
        
    end
    
    return inserted
    
end

// Call with techId and fieldname (returns nil if field not found). Pass optional
// third parameter to use as default if not found.
function LookupTechData(techId, fieldName, default)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if techId == nil or techId == 0 or fieldName == nil or fieldName == "" then
    
        /*    
        local techIdString = ""
        if type(tonumber(techId)) == "number" then            
            techIdString = EnumToString(kTechId, techId)
        end
        
        Print("LookupTechData(%s, %s, %s) called improperly.", tostring(techIdString), tostring(fieldName), tostring(default))
        */
        
        return default
        
    end

    local data = GetCachedTechData(techId, fieldName)
    
    if data == nil then
    
        for index,record in ipairs(kTechData) do 
        
            local currentid = record[kTechDataId]

            if(techId == currentid and record[fieldName] ~= nil) then
            
                data = record[fieldName]
                
                break
                
            end
            
        end        
        
        if data == nil then
            data = default
        end
        
        if not SetCachedTechData(techId, fieldName, data) then
            //Print("Didn't insert anything when calling SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        else
            //Print("Inserted new field with SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        end
    
    end
    
    return data

end

// Returns true if specified class name is used to attach objects to
function GetIsAttachment(className)
    return (className == "TechPoint") or (className == "ResourcePoint")
end

function GetRecycleAmount(techId, upgradeLevel)

    local amount = GetCachedTechData(techId, kTechDataCostKey)
    if techId == kTechId.AdvancedArmory then
        amount = GetCachedTechData(kTechId.Armory, kTechDataCostKey, 0) + GetCachedTechData(kTechId.AdvancedArmoryUpgrade, kTechDataCostKey, 0)
    end

    return amount
    
end
