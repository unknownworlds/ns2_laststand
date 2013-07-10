// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local function UpdateUnitStatusPercentage(self, target)

    if HasMixin(target, "Construct") and not target:GetIsBuilt() then
        self:SetUnitStatusPercentage(target:GetBuiltFraction() * 100)
    elseif HasMixin(target, "Weldable") then
        self:SetUnitStatusPercentage(target:GetWeldPercentage() * 100)
    end

end

function Marine:OnConstructTarget(target)
    UpdateUnitStatusPercentage(self, target)
end

function Marine:OnWeldTarget(target)
    UpdateUnitStatusPercentage(self, target)
end

function Marine:SetUnitStatusPercentage(percentage)
    self.unitStatusPercentage = Clamp(math.round(percentage), 0, 100)
    self.timeLastUnitPercentageUpdate = Shared.GetTime()
end

function Marine:OnTakeDamage(damage, attacker, doer, point)

    if doer and doer:isa("Gore") and not self:GetIsVortexed() then
    
        self.interruptAim = true
        self.interruptStartTime = Shared.GetTime()
        
    end

    /*
    if damage > 50 and (not self.timeLastDamageKnockback or self.timeLastDamageKnockback + 1 < Shared.GetTime()) then    
    
        self:AddPushImpulse(GetNormalizedVectorXZ(self:GetOrigin() - point) * damage * 0.1 * self:GetSlowSpeedModifier())
        self.timeLastDamageKnockback = Shared.GetTime()
        
    end
    */

end

function Marine:GetDamagedAlertId()
    return kTechId.MarineAlertSoldierUnderAttack
end

function Marine:SetPoisoned(attacker)

    self.poisoned = true
    self.timePoisoned = Shared.GetTime()
    
    if attacker then
        self.lastPoisonAttackerId = attacker:GetId()
    end
    
end

function Marine:ApplyCatPack()

    self.catpackboost = true
    self.timeCatpackboost = Shared.GetTime()
    
end

function Marine:OnEntityChange(oldId, newId)

    Player.OnEntityChange(self, oldId, newId)

    if oldId == self.lastPoisonAttackerId then
    
        if newId then
            self.lastPoisonAttackerId = newId
        else
            self.lastPoisonAttackerId = Entity.invalidId
        end
        
    end
 
end

function Marine:SetRuptured()

    self.timeRuptured = Shared.GetTime()
    self.ruptured = true
    
end

function Marine:OnSprintStart()

    if self:GetIsAlive() then
        /*StartSoundEffectOnEntity(Marine.kSprintStart, self)
        if self.loopingSprintSound then
            self.loopingSprintSound:Start()
        end*/
    end

end

function Marine:OnSprintEnd()

    /*if self:GetTiredScalar() >= 0.7 then
        StartSoundEffectOnEntity(Marine.kSprintTiredEnd, self)
    end
    
    if self.loopingSprintSound then
        self.loopingSprintSound:Stop()
    end*/

end

function Marine:OnUpdateSprint(sprinting)

    /*if self.loopingSprintSound and self.loopingSprintSound:GetIsPlaying() and self:GetTiredScalar() == 0 and not sprinting then
        self.loopingSprintSound:Stop()
    end*/
    
end

function Marine:InitWeapons()

    Player.InitWeapons(self)
    
    self:GiveItem(Rifle.kMapName)
    self:GiveItem(Pistol.kMapName)
    self:GiveItem(Axe.kMapName)
    self:GiveItem(Builder.kMapName)
    
    self:SetActiveWeapon(Rifle.kMapName)

end

local function GetHostSupportsTechId(host, techId)

    if Shared.GetCheatsEnabled() then
        return true
    end
    
    local techFound = false
    
    if host.GetItemList then
    
        for index, supportedTechId in ipairs(host:GetItemList()) do
        
            if supportedTechId == techId then
            
                techFound = true
                break
                
            end
            
        end
        
    end
    
    return techFound
    
end

local function PlayerIsFacingHostStructure(player, host)
    return true
end

function GetHostStructureFor(entity, techId)

    local hostStructures = {}
    table.copy(GetEntitiesForTeamWithinRange("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange), hostStructures, true)
    table.copy(GetEntitiesForTeamWithinRange("PrototypeLab", entity:GetTeamNumber(), entity:GetOrigin(), PrototypeLab.kResupplyUseRange), hostStructures, true)
    
    if table.count(hostStructures) > 0 then
    
        for index, host in ipairs(hostStructures) do
        
            // check at first if the structure is hostign the techId:
            if GetHostSupportsTechId(host, techId) and PlayerIsFacingHostStructure(player, host) then
                return host
            end    
        
        end
            
    end
    
    return nil

end

function Marine:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to unbuilt friendly structures should be construct orders
    if(order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Construct)
        
    elseif(order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) and self:GetWeapon(Welder.kMapName) then
    
        order:SetType(kTechId.Weld)
        
    elseif order:GetType() == kTechId.Default and GetOrderTargetIsDefendTarget(order, self:GetTeamNumber()) then
    
        order:SetType(kTechId.Defend)

    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
    
        order:SetType(kTechId.Attack)

    elseif order:GetType() == kTechId.Default then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.Move)
        
    end
    
end

local function BuyExo(self, techId)

    assert(false)   // LS

end

local kIsExoTechId = { [kTechId.Exosuit] = true, [kTechId.DualMinigunExosuit] = true,
                       [kTechId.ClawRailgunExosuit] = true, [kTechId.DualRailgunExosuit] = true }
function Marine:AttemptToBuy(techIds)

    local techId = techIds[1]
    
    local hostStructure = GetHostStructureFor(self, techId)
    
    if hostStructure then
    
        local mapName = LookupTechData(techId, kTechDataMapName)
        
        if mapName then
        
            Shared.PlayPrivateSound(self, Marine.kSpendResourcesSoundName, nil, 1.0, self:GetOrigin())
            
            if self:GetTeam() and self:GetTeam().OnBought then
                self:GetTeam():OnBought(techId)
            end
            
            if techId == kTechId.Jetpack then

                // Need to apply this here since we change the class.
                self:AddResources(-GetCostForTech(techId))
                self:GiveJetpack()
                
            elseif kIsExoTechId[techId] then
                BuyExo(self, techId)    
            else
            
                // Make sure we're ready to deploy new weapon so we switch to it properly.
                if self:GiveItem(mapName) then
                
                    StartSoundEffectAtOrigin(Marine.kGunPickupSound, self:GetOrigin())                    
                    return true
                    
                end
                
            end
            
            return false
            
        end
        
    end
    
    return false
    
end

// special threatment for mines and welders
function Marine:GiveItem(itemMapName)

    local newItem = nil

    if itemMapName then
        
        local continue = true
        local setActive = true
        
        if itemMapName == LayMines.kMapName then
        
            local mineWeapon = self:GetWeapon(LayMines.kMapName)
            
            if mineWeapon then
                mineWeapon:Refill(kNumMines)
                continue = false
                setActive = false
            end
            
        elseif itemMapName == Welder.kMapName then
        
            // since axe cannot be dropped we need to delete it before adding the welder (shared hud slot)
            local switchAxe = self:GetWeapon(Axe.kMapName)
            
            if switchAxe then
                self:RemoveWeapon(switchAxe)
                DestroyEntity(switchAxe)
                continue = true
            else
                continue = false // don't give a second welder
            end
        
        end
        
        if continue == true then
            return Player.GiveItem(self, itemMapName, setActive)
        end
        
    end
    
    return newItem
    
end

function Marine:DropAllWeapons()

    local weaponSpawnCoords = self:GetAttachPointCoords(Weapon.kHumanAttachPoint)
    local weaponList = self:GetHUDOrderedWeaponList()
    for w = 1, #weaponList do
    
        local weapon = weaponList[w]
        if weapon:GetIsDroppable() and LookupTechData(weapon:GetTechId(), kTechDataCostKey, 0) > 0 then
            self:Drop(weapon, true, true)
        end
        
    end
    
end

function Marine:OnKill(attacker, doer, point, direction)

    // drop all weapons which cost resources
    self:DropAllWeapons()

    // destroy remaining weapons
    self:DestroyWeapons()
    
    Player.OnKill(self, attacker, doer, point, direction)
    self:PlaySound(Marine.kDieSoundName)
    
    // Don't play alert if we suicide
    if attacker ~= self then
        self:GetTeam():TriggerAlert(kTechId.MarineAlertSoldierLost, self)
    end
    
    // Note: Flashlight is powered by Marine's beating heart. Eco friendly.
    self:SetFlashlightOn(false)
    self.originOnDeath = self:GetOrigin()
    
end

function Marine:GetCanPhase()
    return not GetIsVortexed(self) and self:GetIsAlive() and (not self.timeOfLastPhase or (Shared.GetTime() > (self.timeOfLastPhase + Marine.kPlayerPhaseDelay)))
end

function Marine:SetTimeOfLastPhase(time)
    self.timeOfLastPhase = time
end

function Marine:GetOriginOnDeath()
    return self.originOnDeath
end

function Marine:GiveJetpack()

    local activeWeapon = self:GetActiveWeapon()
    local activeWeaponMapName = nil
    local health = self:GetHealth()
    local armor = self:GetArmor()
    
    if activeWeapon ~= nil then
        activeWeaponMapName = activeWeapon:GetMapName()
    end
    
    local jetpackMarine = self:Replace(JetpackMarine.kMapName, self:GetTeamNumber(), true, Vector(self:GetOrigin()))
    
    jetpackMarine:SetActiveWeapon(activeWeaponMapName)
    jetpackMarine:SetHealth(health)
    jetpackMarine:SetArmor(armor)
    
end

function Marine:GiveExo(spawnPoint, layout, oldArmor)

    self:DropAllWeapons()
    self:Replace(Exo.kMapName, self:GetTeamNumber(), false, spawnPoint,
            {
            layout = layout,
            oldArmor = oldArmor,
            driverHealth = self:GetHealth(),
            driverArmor = self:GetArmor()
            })
    
end

function Marine:MakeSpecialEdition()
    self:SetModel(Marine.kBlackArmorModelName, Marine.kMarineAnimationGraph)
end

function Marine:MakeDeluxeEdition()
    self:SetModel(Marine.kSpecialEditionModelName, Marine.kMarineAnimationGraph)
end
