// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======		
//		
// lua\BalanceHealth.lua		
//		
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)		
//		
// Auto-generated. Copy and paste from balance spreadsheet.		
//		
// ========= For more information, visit us at http://www.unknownworlds.com =====================		
		
// HEALTH AND ARMOR		
kMarineHealth = 100	kMarineArmor = 30	kMarinePointValue = 5
kJetpackHealth = 100	kJetpackArmor = 30	kJetpackPointValue = 10
kExosuitHealth = 100	kExosuitArmor = 400	kExosuitPointValue = 20
		
kSkulkHealth = 70	kSkulkArmor = 10	kSkulkPointValue = 5
kGorgeHealth = 150	kGorgeArmor = 70	kGorgePointValue = 7
kLerkHealth = 125	kLerkArmor = 50	kLerkPointValue = 15
kFadeHealth = 250	kFadeArmor = 50	kFadePointValue = 20
kOnosHealth = 1300	kOnosArmor = 500	kOnosPointValue = 30

kMarineWeaponHealth = 400
		
kEggHealth = 350	kEggArmor = 0	kEggPointValue = 2
kMatureEggHealth = 350	kMatureEggArmor = 25

kBabblerHealth = 30	kBabblerArmor = 5	kBabblerPointValue = 0
kBabblerEggHealth = 300	kBabblerEggArmor = 0	kBabblerEggPointValue = 0
		
kArmorPerUpgradeLevel = 20
kExosuitArmorPerUpgradeLevel = 60
kArmorHealScalar = 1 // 0.75

kBuildPointValue = 5
kRecyclePaybackScalar = 0.75
kRepairMarineArmorPointValue = 1

kSkulkArmorFullyUpgradedAmount = 30
kGorgeArmorFullyUpgradedAmount = 150
kLerkArmorFullyUpgradedAmount = 75
kFadeArmorFullyUpgradedAmount = 100
kOnosArmorFullyUpgradedAmount = 900

kHealthPointsPerArmorScalarHive1 = 1
kHealthPointsPerArmorScalarHive2 = 1
kHealthPointsPerArmorScalarHive3 = 1

kExosuitAbsorption = 0.95
kBalanceInfestationHurtPercentPerSecond = 2

// used for structures
kStartHealthScalar = 0.3

kArmoryHealth = 1800	kArmoryArmor = 300	kArmoryPointValue = 10
kAdvancedArmoryHealth = 3000	kAdvancedArmoryArmor = 500	kAdvancedArmoryPointValue = 40
kCommandStationHealth = 3000	kCommandStationArmor = 1500	kCommandStationPointValue = 25
kObservatoryHealth = 1700	kObservatoryArmor = 0	kObservatoryPointValue = 15
kPhaseGateHealth = 2700	kPhaseGateArmor = 450	kPhaseGatePointValue = 20
kRoboticsFactoryHealth = 2800	kRoboticsFactoryArmor = 1000	kRoboticsFactoryPointValue = 20
kARCRoboticsFactoryHealth = 2800	kARCRoboticsFactoryArmor = 1000	kARCRoboticsFactoryPointValue = 20
kPrototypeLabHealth = 3200	kPrototypeLabArmor = 400	kPrototypeLabPointValue = 20
kInfantryPortalHealth = 2250	kInfantryPortalArmor = 125	kInfantryPortalPointValue = 15
kArmsLabHealth = 2200	kArmsLabArmor = 225	kArmsLabPointValue = 20
kPowerPackHealth = 1200	kPowerPackArmor = 400	kPowerPackPointValue = 15
kSentryBatteryHealth = 600	kSentryBatteryArmor = 200	kSentryPointValue = 5

// 5000/1000 is good average (is like 7,000 health from NS1, but protects somewhat from shotguns)
// Hives start out about -21% and go to +25%
kHiveHealth = 4000	kHiveArmor = 750	kHivePointValue = 30
kMatureHiveHealth = 6000 kMatureHiveArmor = 1400
		
kDrifterHealth = 300	kDrifterArmor = 0	kDrifterPointValue = 2
kMACHealth = 300	kMACArmor = 150	kMACPointValue = 5
kMineHealth = 80	kMineArmor = 10	kMinePointValue = 2
		
kExtractorHealth = 3500	kExtractorArmor = 500	kExtractorPointValue = 15

// Harvesters start at 84% of NS1 value and go to 110% (1500/500 = 2500 = NS1)
kHarvesterHealth = 1300	kHarvesterArmor = 400	kHarvesterPointValue = 15
kMatureHarvesterHealth = 1750 kMatureHarvesterArmor = 500 -- NS1

kSentryHealth = 500	kSentryArmor = 100	kSentryPointValue = 10
kARCHealth = 2000	kARCArmor = 500	kARCPointValue = 20
kARCDeployedHealth = 2000	kARCDeployedArmor = 0	kARCPointValue = 20
		
kShellHealth = 900	kShellArmor = 200	kShellPointValue = 10
kMatureShellHealth = 1100	kMatureShellArmor = 300	kShellPointValue = 10

kCragHealth = 450	kCragArmor = 150	kCragPointValue = 10
kMatureCragHealth = 600	kMatureCragArmor = 250	kMatureCragPointValue = 15
		
kWhipHealth = 650	kWhipArmor = 175	kWhipPointValue = 10
kMatureWhipHealth = 720	kMatureWhipArmor = 240	kMatureWhipPointValue = 15
		
kSpurHealth = 900	kSpurArmor = 0	kSpurPointValue = 10
kMatureSpurHealth = 1000 kMatureSpurArmor = 200 kMatureSpurPointValue = 10

kShiftHealth = 500	kShiftArmor = 50	kShiftPointValue = 10
kMatureShiftHealth = 800	kMatureShiftArmor = 100	kMatureShiftPointValue = 15

kVeilHealth = 900	kVeilArmor = 0	kVeilPointValue = 10
kMatureVeilHealth = 1000	kMatureVeilArmor = 150	kVeilPointValue = 10

kShadeHealth = 500	kShadeArmor = 0	kShadePointValue = 10
kMatureShadeHealth = 1000	kMatureShadeArmor = 0	kMatureShadePointValue = 15

kHydraHealth = 350	kHydraArmor = 10	kHydraPointValue = 5
kMatureHydraHealth = 450	kMatureHydraArmor = 50	kMatureHydraPointValue = 5

kClogHealth = 250  kClogArmor = 0 kClogPointValue = 0

kCystHealth = 50	kCystArmor = 0	kCystPointValue = 5
kMatureCystHealth = 550	kMatureCystArmor = 0	kCystPointValue = 2

kBoneWallHealth = 300 kBoneWallArmor = 300 kBoneWallPointValue = 5

kPowerPointHealth = 2000	kPowerPointArmor = 1000	kPowerPointPointValue = 15
kDoorHealth = 2000	kDoorArmor = 1000	kDoorPointValue = 15

kTunnelEntranceHealth = 1400	kTunnelEntranceArmor = 100	kTunnelEntrancePointValue = 15
kMatureTunnelEntranceHealth = 1600	kMatureTunnelEntranceArmor = 200

// Hide armor
kLerkHideArmor = 0
kOnosHideArmor = 0
