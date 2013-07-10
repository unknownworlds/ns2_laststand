// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MaterialUtility.lua")

Alien.kEnzymedViewMaterialName = "cinematics/vfx_materials/enzyme_view.material"
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/enzyme_view.surface_shader")

Alien.kEnzymedMaterialName = "cinematics/vfx_materials/enzyme_view.material"
Alien.kEnzymedThirdpersonMaterialName = "cinematics/vfx_materials/enzyme.material"
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/enzyme.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/enzyme_view.surface_shader")

Alien.kCelerityViewCinematic = PrecacheAsset("cinematics/alien/high_speed_1p.cinematic")
local kRegenerationViewCinematic = PrecacheAsset("cinematics/alien/regeneration_1p.cinematic")
Alien.kFirstPersonDeathEffect = PrecacheAsset("cinematics/alien/death_1p_alien.cinematic")

local kAlienFirstPersonHitEffectName = PrecacheAsset("cinematics/alien/hit_1p.cinematic")

local kEnzymeEffectInterval = 0.2

function PlayerUI_GetNumHives()

    for _, ent in ientitylist(Shared.GetEntitiesWithClassname("AlienTeamInfo")) do
        return ent:GetNumHives()
    end
    
    return 0

end

// array of totalPower, minPower, xoff, yoff, visibility (boolean), hud slot
function GetActiveAbilityData(secondary)

    local data = { }
    
    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local ability = player:GetActiveWeapon()
        
        if ability ~= nil and ability:isa("Ability") then
        
            if not secondary or secondary and ability:GetHasSecondary(player) then
                data = ability:GetInterfaceData(secondary, false)
            end
            
        end
        
    end
    
    return data
    
end

function AlienUI_GetHasAdrenaline()

    local player = Client.GetLocalPlayer()
    local hasAdrenaline = false
    
    if player then
        hasAdrenaline = GetHasAdrenalineUpgrade(player)
    end
    
    return hasAdrenaline == true

end

function AlienUI_GetInUmbra()

    local player = Client.GetLocalPlayer()
    if player ~= nil and HasMixin(player, "Umbra") then
        return player:GetHasUmbra()
    end

    return false

end

function AlienUI_GetAvailableUpgrades()

    local techTree = GetTechTree()

    local upgrades = {}
    local localPlayer = Client.GetLocalPlayer()
    
    if techTree and localPlayer then

        for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllAliens)) do
        
            local upgradeNode = techTree:GetTechNode(upgradeId)
            local hiveType = GetHiveTypeForUpgrade(upgradeId)

            if upgradeNode:GetAvailable() and not localPlayer:GetHasUpgrade(upgradeId) then
            
                if not upgrades[hiveType] then
                    upgrades[hiveType] = {}
                end
            
                table.insert(upgrades[hiveType], upgradeNode:GetTechId())
            end
        
        end
    
    end
    
    return upgrades

end

function AlienUI_HasSameTypeUpgrade(selectedIds, techId)

    local desiredHiveType = GetHiveTypeForUpgrade(techId)
    for _, selectedId in ipairs(selectedIds) do
    
        if GetHiveTypeForUpgrade(selectedId) == desiredHiveType then
            return true
        end
    
    end
    
    return false

end

function AlienUI_GetEggCount()

    local eggCount = 0
    
    local teamInfo = GetTeamInfoEntity(kTeam2Index)
    if teamInfo then
        eggCount = teamInfo:GetEggCount()
    end
    
    return eggCount
    
end

/**
 * For current ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function PlayerUI_GetAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        table.addtable(GetActiveAbilityData(false), data)

    end
    
    return data
    
end

/**
 * For secondary ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean)
 */
function PlayerUI_GetSecondaryAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        
        table.addtable(GetActiveAbilityData(true), data)
        
    end
    
    return data
    
end

/**
 * Return boolean value indicating if inactive powers should be visible
 */
function PlayerUI_GetInactiveVisible()
    local player = Client.GetLocalPlayer()
    return player:isa("Alien") and player:GetInactiveVisible()
end

// Loop through child weapons that aren't active and add all their data into one array
function PlayerUI_GetInactiveAbilities()

    local data = {}
    
    local player = Client.GetLocalPlayer()

    if player and player:isa("Alien") then    
    
        local inactiveAbilities = player:GetHUDOrderedWeaponList()
        
        // Don't show selector if we only have one ability
        if table.count(inactiveAbilities) > 1 then
        
            for index, ability in ipairs(inactiveAbilities) do
            
                if ability:isa("Ability") then
                    local abilityData = ability:GetInterfaceData(false, true)
                    if table.count(abilityData) > 0 then
                        table.addtable(abilityData, data)
                    end
                end
                    
            end
            
        end
        
    end
    
    return data
    
end

function PlayerUI_GetPlayerEnergy()

    local player = Client.GetLocalPlayer()
    if player and player.GetEnergy then
        return player:GetEnergy()
    end
    return 0
    
end

function PlayerUI_GetPlayerMaxEnergy()

    local player = Client.GetLocalPlayer()
    if player and player.GetEnergy then
        return player:GetMaxEnergy()
    end
    return kAbilityMaxEnergy
    
end

function Alien:OnKillClient()

    Player.OnKillClient(self)
    
    self:DestroyGUI()
    
end

function Alien:UpdateEnzymeEffect(isLocal)

    if self.enzymedClient ~= self.enzymed then

        if isLocal then
        
            local viewModel= nil        
            if self:GetViewModelEntity() then
                viewModel = self:GetViewModelEntity():GetRenderModel()  
            end
                
            if viewModel then
   
                if self.enzymed then
                    self.enzymedViewMaterial = AddMaterial(viewModel, Alien.kEnzymedViewMaterialName)
                else
                
                    if RemoveMaterial(viewModel, self.enzymedViewMaterial) then
                        self.enzymedViewMaterial = nil
                    end
  
                end
            
            end
        
        end
        
        local thirdpersonModel = self:GetRenderModel()
        if thirdpersonModel then
        
            if self.enzymed then
                self.enzymedMaterial = AddMaterial(thirdpersonModel, Alien.kEnzymedThirdpersonMaterialName)
            else
            
                if RemoveMaterial(thirdpersonModel, self.enzymedMaterial) then
                    self.enzymedMaterial = nil
                end

            end
        
        end
        
        self.enzymedClient = self.enzymed
        
    end

    // update cinemtics
    if self.enzymed then

        if not self.lastEnzymedEffect or self.lastEnzymedEffect + kEnzymeEffectInterval < Shared.GetTime() then
        
            self:TriggerEffects("enzymed")
            self.lastEnzymedEffect = Shared.GetTime()
        
        end

    end 

end

function Alien:GetDarkVisionEnabled()
    return self.darkVisionOn
end

function Alien:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    // If we are dead, close the evolve menu.
    if isLocal and not self:GetIsAlive() and self:GetBuyMenuIsDisplaying() then
        self:CloseMenu()
    end
    
    self:UpdateEnzymeEffect(isLocal)
    
    if isLocal and self:GetIsAlive() then
    
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        local darkVisionPulseTime = 4
        
        if not self.darkVisionOn then
            darkVisionFadeAmount = math.max(1 - (Shared.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0)
        end
        
        if Player.screenEffects.darkVision then
        
            Player.screenEffects.darkVision:SetActive(self.darkVisionOn or darkVisionFadeAmount > 0)
            
            Player.screenEffects.darkVision:SetParameter("startTime", self.darkVisionTime)
            Player.screenEffects.darkVision:SetParameter("time", Shared.GetTime())
            Player.screenEffects.darkVision:SetParameter("amount", darkVisionFadeAmount)
            
        end
        
        // Blur alien vision if they are using the buy menu or are stunned.
        local stunned = HasMixin(self, "Stun") and self:GetIsStunned()
        self:SetBlurEnabled(self:GetBuyMenuIsDisplaying() or stunned or self:GetIsMinimapVisible())
        
        //self:UpdateCelerityEffect()
        self:UpdateRegenerationEffect()
        
    end
    
end

function Alien:GetFirstPersonDeathEffect()
    return Alien.kFirstPersonDeathEffect
end

function Alien:UpdateCelerityEffect()

    if Player.screenEffects.celerityFX then
    
        local celeritySpeedScalar = self.celeritySpeedScalar
        Player.screenEffects.celerityFX:SetActive(GetHasCelerityUpgrade(self))
        Player.screenEffects.celerityFX:SetParameter("amount", celeritySpeedScalar / 2)
        
    end
    
end

function Alien:UpdateRegenerationEffect()

    if not self:GetIsInCombat() and GetHasRegenerationUpgrade(self) and not ClientUI.GetScript("GUIRegenerationFeedback"):GetIsAnimating() then
    
        if self.lastHealth then
        
            if self.lastHealth < self:GetHealth() then
            
                ClientUI.GetScript("GUIRegenerationFeedback"):TriggerRegenEffect()
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kRegenerationViewCinematic)
                
            end
            
        end
        
        self.lastHealth = self:GetHealth()
        
    end
    
end

function Alien:UpdateMisc(input)

    Player.UpdateMisc(self, input)
    
    if not Shared.GetIsRunningPrediction() then

        // Close the buy menu if it is visible when the Alien moves.
        if input.move.x ~= 0 or input.move.z ~= 0 then
            self:CloseMenu()
        end
        
    end
    
end

function Alien:CloseMenu()

    if self.buyMenu then
    
        self.buyMenu:OnClose()
        
        GetGUIManager():DestroyGUIScript(self.buyMenu)
        self.buyMenu = nil
        
        MouseTracker_SetIsVisible(false)
        
        // Quick work-around to not fire weapon when closing menu.
        self.timeClosedMenu = Shared.GetTime()
        
        return true
        
    end
    
    return false
    
end

// Bring up evolve menu
function Alien:Buy()

    // Don't allow display in the ready room, or as phantom
    if self:GetIsLocalPlayer() then
    
        // The Embryo cannot use the buy menu in any case.
        if self:GetTeamNumber() ~= 0 and not self:isa("Embryo") then
        
            if not self.buyMenu then
            
                self.buyMenu = GetGUIManager():CreateGUIScript("GUIAlienBuyMenu")
                MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)
                
            else
                self:CloseMenu()
            end
            
        else
            self:PlayEvolveErrorSound()
        end
        
    end
    
end

function Alien:PlayEvolveErrorSound()

    if not self.timeLastEvolveErrorSound then
        self.timeLastEvolveErrorSound = Shared.GetTime()
    end

    if self.timeLastEvolveErrorSound + 0.5 < Shared.GetTime() then

         self:TriggerInvalidSound()
         self.timeLastEvolveErrorSound = Shared.GetTime()

    end

end

function Alien:OnCountDown()

    Player.OnCountDown(self)
    
    ClientUI.GetScript("GUIAlienHUD"):SetIsVisible(false)
    
end

function Alien:OnCountDownEnd()

    Player.OnCountDownEnd(self)
    
    ClientUI.GetScript("GUIAlienHUD"):SetIsVisible(true)
    
end

function Alien:GetPlayFootsteps()
    return Player.GetPlayFootsteps(self) and not GetHasSilenceUpgrade(self) and not self:GetIsCloaked()
end

function Alien:GetFirstPersonHitEffectName()
    return kAlienFirstPersonHitEffectName
end 

function AlienUI_GetPersonalUpgrades()

    local upgrades = {}
    
    local techTree = GetTechTree()
    
    if techTree then
    
        for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllAliens)) do
            table.insert(upgrades, {TechId = upgradeId, Category = GetHiveTypeForUpgrade(upgradeId)})
        end
    
    end
    
    return upgrades

end

function AlienUI_GetUpgradesForCategory(category)

    local upgrades = {}
    
    local techTree = GetTechTree()
    
    if techTree then
    
        for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllAliens)) do
        
            if GetHiveTypeForUpgrade(upgradeId) == category then        
                table.insert(upgrades, upgradeId)
            end
            
        end
    
    end
    
    return upgrades

end

// create some blood on the ground below
local kGroundDistanceBlood = Vector(0, 1, 0)
local kGroundBloodStartOffset = Vector(0, 0.2, 0)
function Alien:OnTakeDamageClient(damage, doer, position)

    if not self.timeLastGroundBloodDecal then
        self.timeLastGroundBloodDecal = 0
    end
    
    if self.timeLastGroundBloodDecal + 0.5 < Shared.GetTime() then
    
        local trace = Shared.TraceRay(self:GetOrigin() + kGroundBloodStartOffset, self:GetOrigin() - kGroundDistanceBlood, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
        
            local coords = Coords.GetIdentity()
            coords.origin = trace.endPoint
            coords.yAxis = trace.normal
            coords.zAxis = coords.yAxis:GetPerpendicular()
            coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        
            self:TriggerEffects("alien_blood_ground", {effecthostcoords = coords})
            
        end
        
        self.timeLastGroundBloodDecal = Shared.GetTime()
        
    end
    
end
