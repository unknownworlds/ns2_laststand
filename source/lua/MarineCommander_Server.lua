// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander_Server.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * sends notification to all players (new research complete, structure created, etc)
 */
 
function MarineCommander:ProcessSuccessAction(techId)

    local team = self:GetTeam()
    local cost = GetCostForTech(techId)
    
    if cost and cost ~= 0 then
        team:AddTeamResources(-cost)
    end

end

function MarineCommander:TriggerScan(position, trace)

    if trace.fraction ~= 1 then

        CreateEntity(Scan.kMapName, position, self:GetTeamNumber())
        StartSoundEffectAtOrigin(Observatory.kScanSound, position)
        
        // create custom sound for marine commander
        StartSoundEffectForPlayer(Observatory.kCommanderScanSound, self)
        self:ProcessSuccessAction(kTechId.Scan)

        return true
    
    else
        self:TriggerInvalidSound()
        return false
    end

end

local function GetDroppackSoundName(techId)

    if techId == kTechId.MedPack then
        return MedPack.kHealthSound
    elseif techId == kTechId.AmmoPack then
        return AmmoPack.kPickupSound
    elseif techId == kTechId.CatPack then
        return CatPack.kPickupSound
    end 
   
end

function MarineCommander:TriggerDropPack(position, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)

    if mapName then
    
        local droppack = CreateEntity(mapName, position, self:GetTeamNumber())
        StartSoundEffectForPlayer(GetDroppackSoundName(techId), self)
        self:ProcessSuccessAction(techId)
        success = true
        
    end

    return success

end

local function GetIsEquipment(techId)

    return techId == kTechId.DropWelder or techId == kTechId.DropMines or techId == kTechId.DropShotgun or techId == kTechId.DropGrenadeLauncher or
           techId == kTechId.DropFlamethrower or techId == kTechId.DropJetpack or techId == kTechId.DropExosuit

end

function MarineCommander:TriggerNanoShield(position)    

    local success = false
    
    local nanoShield = CreateEntity(NanoShield.kMapName, position, self:GetTeamNumber())
    
    if nanoShield:GetWasSuccess() then
    
        StartSoundEffectAtOrigin(CommandStation.kTriggerNanoShieldSound3d, position)
        StartSoundEffectForPlayer(CommandStation.kTriggerNanoShieldSound, commander)
        self:ProcessSuccessAction(kTechId.NanoShield)
        success = true
        
    else
        self:TriggerInvalidSound()
    end

    return success

end

local function GetIsDroppack(techId)
    return techId == kTechId.MedPack or techId == kTechId.AmmoPack or techId == kTechId.CatPack
end

// check if a notification should be send for successful actions
function MarineCommander:ProcessTechTreeActionForEntity(techNode, position, normal, pickVec, orientation, entity, trace, targetId)

    local techId = techNode:GetTechId()
    local success = false
    local keepProcessing = false
    
    if techId == kTechId.Scan then
        success = self:TriggerScan(position, trace)
        keepProcessing = false
        
    elseif techId == kTechId.NanoShield then
        success = self:TriggerNanoShield(position)   
        keepProcessing = false
     
    elseif GetIsDroppack(techId) then
    
        // use the client side trace.entity here
        local clientTargetEnt = Shared.GetEntity(targetId)
        if clientTargetEnt and clientTargetEnt:isa("Marine") then
            position = clientTargetEnt:GetOrigin() + Vector(0, 0.05, 0)
        end
    
        success = self:TriggerDropPack(position, techId)
        keepProcessing = false
        
    elseif GetIsEquipment(techId) then
    
        success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false, entity)
    
        if success then
            self:ProcessSuccessAction(techId)
            self:TriggerEffects("spawn_weapon", { effecthostcoords = Coords.GetTranslation(position) })
        end    
            
        keepProcessing = false

    else
        success, keepProcessing = Commander.ProcessTechTreeActionForEntity(self, techNode, position, normal, pickVec, orientation, entity, trace, targetId)
    end

    if success then

        local location = GetLocationForPoint(position)
        local locationName = location and location:GetName() or ""
        self:TriggerNotification(Shared.GetStringIndex(locationName), techId)
    
    end   
    
    return success, keepProcessing

end