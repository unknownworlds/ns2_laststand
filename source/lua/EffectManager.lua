// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\EffectManager.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Play sounds, cinematics or animations through a simple trigger. Decouples script from 
// artist, sound designer, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SharedDecal.lua")
Script.Load("lua/RelevancyMixin.lua")

class 'EffectManager'

// Set to true to use triggering entity's coords
kEffectHostCoords = "effecthostcoords"
kEffectSurface = "surface"

// Set to class name to display debug info for objects of that class, to "" to display everything, 
// or nil to disable
gEffectDebugClass = nil

// Graphical debug text (table of GUIDebugText objects)
gDebugTextList = { }

//////////////////////
// Public functions //
//////////////////////
function GetEffectManager()

    if not gEffectManager then
    
        gEffectManager = EffectManager()
        
        // speed up access to kEffectFilters
        gEffectManager.effectFilterMap = { }
        for _,v in ipairs(kEffectFilters) do
            gEffectManager.effectFilterMap[v] = true
        end
        
    end
    
    return gEffectManager
    
end

// Returns true if this effect should be displayed to the log
function EffectManager:GetDisplayDebug(effectTable, triggeringEntity)

    local debug = false
    
    if Shared.GetDevMode() and not Shared.GetIsRunningPrediction() then

        if (effectTable == nil or not (effectTable[kEffectParamSilent] == true)) then
    
            if (gEffectDebugClass == "") or (gEffectDebugClass and triggeringEntity and triggeringEntity:isa(gEffectDebugClass)) then
                debug = true
            else
            
                // Special-case view models for convenience
                if effectTable[kViewModelCinematicType] and triggeringEntity and triggeringEntity.GetViewModelEntity then
                
                    local viewModelEntity = triggeringEntity:GetViewModelEntity()
                    
                    if viewModelEntity and gEffectDebugClass and viewModelEntity:isa(gEffectDebugClass) then
                        debug = true
                    end
                
                end
                
            end
            
        end 
       
    end
    
    return debug
    
end

// Print debug info to log whenever about to trigger an effect. stringParam will be an asset name or animation name.
function EffectManager:DisplayDebug(stringParam, effectTable, triggeringParams, triggeringEntity)

    if self:GetDisplayDebug(effectTable, triggeringEntity) then
    
        local effectType = "unknown"
        for index, type in ipairs(kEffectTypes) do
            if effectTable[type] then
                effectType = type
                break
            end
        end
    
        local triggeringEntityText = ""
        if triggeringEntity then
            triggeringEntityText = string.format(" on %s", SafeClassName(triggeringEntity))
        end
        
        Print("  Playing %s \"%s\": %s%s", effectType, ToString(stringParam), ToString(triggeringParams), triggeringEntityText)
        
        // Create rising graphical text at world position when debug is on
        local debugText = string.format("%s '%s' (%s)", effectType, ToString(stringParam), GetClientServerString())
        local debugOrigin = triggeringEntity:GetOrigin()
        
        if Client then
            self:AddDebugText(debugText, debugOrigin, triggeringEntity)
        else
            // Send console message to all nearby clients
            for index, toPlayer in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                if (toPlayer:GetOrigin() - debugOrigin):GetLength() < 25 then
                    local entIdString = ""
                    if triggeringEntity then
                        entIdString = ToString(triggeringEntity:GetId())
                    end
                    Server.SendCommand(toPlayer, string.format("debugtext \"%s\" %s %s", debugText, EncodePointInString(debugOrigin), entIdString))
                end
            end
        end        
    end    
    
end

if Client then

    function EffectManager:AddDebugText(debugText, origin, ent)
    
        local messageOffset = 0
        if ent then
        
            // Count number of debug messages entity already has so we can offset
            // message when drawing it (to avoid overlap)
            for index, debugPair in ipairs(gDebugTextList) do
            
                if debugPair[2] == ent then
                    messageOffset = messageOffset + 1
                end
                
            end
            
        end
        
        local debugTextObject = GetGUIManager():CreateGUIScript("GUIDebugText")
        debugTextObject:SetDebugInfo(debugText, origin, messageOffset)
        table.insert(gDebugTextList, {debugTextObject, ent})
        
    end
    
end

function EffectManager:AddEffectData(identifier, data)

    assert(identifier)
    assert(data)
    
    self.effectTables = self.effectTables or { }
    self.decalList = self.decalList or { }
    
    self.effectTables[identifier] = data
    
end

local function InternalPrecacheEffectTable(self, globalEffectTable)

    for currentEffectName, currentEffectTable in pairs(globalEffectTable) do
    
        for effectBlockDescription, effectBlockTable in pairs(currentEffectTable) do
        
            for effectTableIndex, effectTable in ipairs(effectBlockTable) do
            
                // Get asset file name from effect data
                local assetEntry = GetAssetNameFromType(effectTable)
                
                // nil allowed - means we can stop processing
                if assetEntry == nil then
                elseif effectTable[kDecalType] then
                    
                    if type(assetEntry) == "table" then
                    
                        for index, assetNameEntry in ipairs(assetEntry) do
                            Shared.RegisterDecalMaterial(assetNameEntry[2])
                        end
                        
                    else
                        Shared.RegisterDecalMaterial(assetEntry)
                    end
                    
                elseif type(assetEntry) == "string" then
                
                    if string.find(assetEntry, "%%") ~= nil then
                        PrecacheMultipleAssets(assetEntry, kSurfaceList)
                    else
                        PrecacheAsset(assetEntry)
                    end
                    
                elseif type(assetEntry) == "table" then
                
                    for index, assetNameEntry in ipairs(assetEntry) do
                        PrecacheAsset(assetNameEntry[2])
                    end
                    
                elseif not effectTable[kRagdollType] then
                    Print("No asset name found in block \"%s\"", ToString(effectTable))
                end
                
            end
            
        end
        
    end
    
end

function EffectManager:PrecacheEffects()

    // Loop through effect tables and precache all assets.
    for id, data in pairs(self.effectTables) do
        InternalPrecacheEffectTable(self, data)
    end
    
end

function EffectManager:GetQueuedText()
    return ConditionalValue(self.locked, " (queued)", "")
end

--[[
- Loop through all filters specified and see if they equal ones specified.
--]]
local function InternalGetEffectMatches(self, triggeringEntity, assetEntry, tableParams)

    PROFILE("EffectManager:InternalGetEffectMatches")
    
    for filterName, filterValue in pairs(assetEntry) do
    
        if self.effectFilterMap[filterName] then
        
            if not tableParams then
                return false
            end
            
            local triggerFilterValue = tableParams[filterName]
            
            -- Check class and doer names via :isa
            if filterName == kEffectFilterDoerName then
            
                -- Check the class hierarchy
                if triggerFilterValue == nil or not classisa(triggerFilterValue, filterValue) then
                    return false
                end
                
            elseif filterName == kEffectFilterClassName then
            
                if triggeringEntity and triggeringEntity:isa("ViewModel") and triggeringEntity:GetWeapon() and triggeringEntity:GetWeapon():isa(filterValue) then
                
                    // Allow view models to trigger animations for weapons
                    
                elseif not triggeringEntity or ((not triggerFilterValue and not triggeringEntity:isa(filterValue)) or (triggerFilterValue and not classisa(triggerFilterValue, filterValue))) then
                    return false
                end
                
            else
            
                // Otherwise makes sure specified parameters match
                if filterValue ~= triggerFilterValue then
                    return false
                end
                
            end
            
        end
        
    end
    
    return true
    
end

local function InternalTriggerEffect(self, effectTable, triggeringParams, triggeringEntity)

    local success = false
    
    // Do not trigger certain effects when running prediction.
    if not Shared.GetIsRunningPrediction() then
        if effectTable[kCinematicType] or effectTable[kWeaponCinematicType] or effectTable[kViewModelCinematicType] or
            effectTable[kPlayerCinematicType] or effectTable[kParentedCinematicType] or
            effectTable[kLoopingCinematicType] or effectTable[kStopCinematicType] or
            effectTable[kStopViewModelCinematicType] then
        
            success = self:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)
            
        elseif effectTable[kSoundType] or effectTable[kParentedSoundType] or effectTable[kPrivateSoundType] or effectTable[kStopSoundType] or effectTable[kPlayerSoundType] then
        
            success = self:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)

        elseif effectTable[kStopEffectsType] then
        
            success = self:InternalStopEffects(effectTable, triggeringParams, triggeringEntity)
            
        elseif effectTable[kDecalType] then
        
            success = self:InternalTriggerDecal(effectTable, triggeringParams, triggeringEntity)

        end
    end
    
    if not success and self:GetDisplayDebug(effectTable, triggeringEntity) then
        Print("InternalTriggerEffect(%s) - didn't trigger effect (%s).", ToString(effectTable), SafeClassName(triggeringEntity))
    end
    
    return success
    
end

local function GetCachedEffectTable(self, inputEffectTable, effectName)

    self.cachedMatchingEffects = self.cachedMatchingEffects or { }
    self.cachedMatchingEffects[inputEffectTable] = self.cachedMatchingEffects[inputEffectTable] or { }
    self.cachedMatchingEffects[inputEffectTable][effectName] = self.cachedMatchingEffects[inputEffectTable][effectName] or { }
    return self.cachedMatchingEffects[inputEffectTable][effectName]
    
end

local function AddCachedMatchingEffect(self, inputEffectTable, effectName, cachedTableParams, triggeringEntityClassName, assetEntry)

    local effectNameTable = GetCachedEffectTable(self, inputEffectTable, effectName)
    
    -- triggeringEntityClassName is not always used when triggering effects, default to "" as a catch all.
    triggeringEntityClassName = triggeringEntityClassName or ""
    effectNameTable[triggeringEntityClassName] = effectNameTable[triggeringEntityClassName] or { }
    
    local classNameTable = effectNameTable[triggeringEntityClassName]
    classNameTable[cachedTableParams] = classNameTable[cachedTableParams] or { }
    table.insert(classNameTable[cachedTableParams], assetEntry)
    
end

--[[
- The matching effects for an effect name are cached off based on the
- table params and the triggering entity class name.
--]]
local function FindCachedMatchingEffects(self, inputEffectTable, effectName, cachedTableParams, triggeringEntityClassName)

    local effectNameTable = GetCachedEffectTable(self, inputEffectTable, effectName)
    
    -- triggeringEntityClassName is not always used when triggering effects, default to "" as a catch all.
    triggeringEntityClassName = triggeringEntityClassName or ""
    effectNameTable[triggeringEntityClassName] = effectNameTable[triggeringEntityClassName] or { }
    
    return effectNameTable[triggeringEntityClassName][cachedTableParams]
    
end

local function InternalTriggerMatchingEffects(self, inputEffectTable, triggeringEntity, effectName, tableParams, cachedTableParams)

    PROFILE("EffectManager:InternalTriggerMatchingEffects")
    
    local triggeringEntityClassName = triggeringEntity and triggeringEntity:GetClassName() or nil
    local cachedMatchingEffects = FindCachedMatchingEffects(self, inputEffectTable, effectName, cachedTableParams, triggeringEntityClassName)
    if cachedMatchingEffects then
    
        for e = 1, #cachedMatchingEffects do
            InternalTriggerEffect(self, cachedMatchingEffects[e], tableParams, triggeringEntity)
        end
        
    else
    
        local currentEffectBlockTable = inputEffectTable[effectName]
        
        if currentEffectBlockTable then
        
            for effectTableIndex, effectTable in pairs(currentEffectBlockTable) do
            
                local keepProcessing = true
                
                for assetEntryIndex, assetEntry in ipairs(effectTable) do
                
                    if keepProcessing then
                    
                        if InternalGetEffectMatches(self, triggeringEntity, assetEntry, tableParams) then
                        
                            if self:GetDisplayDebug(assetEntry, triggeringEntity) then
                                Print("Triggering effect \"%s\" on %s (%s)", effectName, SafeClassName(triggeringEntity), ToString(assetEntry))
                            end
                            
                            // Trigger effect
                            InternalTriggerEffect(self, assetEntry, tableParams, triggeringEntity)
                            
                            AddCachedMatchingEffect(self, inputEffectTable, effectName, cachedTableParams, triggeringEntityClassName, assetEntry)
                            
                            // Stop processing this block "done" specified
                            if assetEntry[kEffectParamDone] == true then
                                keepProcessing = false
                            end
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

local function GetCachedTableParams(tableParams)

    local sortedParams = { }
    for name, value in pairs(tableParams) do
    
        if name ~= "effecthostcoords" then
            table.insert(sortedParams, name .. ToString(value))
        end
        
    end
    
    table.sort(sortedParams)
    
    local cachedTableParams = ""
    for i = 1, #sortedParams do
        cachedTableParams = cachedTableParams .. sortedParams[i]
    end
    
    return cachedTableParams
    
end

function EffectManager:TriggerEffects(effectName, tableParams, triggeringEntity)

    ASSERT(self.effectTables)
    
    local cachedTableParams = GetCachedTableParams(tableParams)
    
    for id, data in pairs(self.effectTables) do
        InternalTriggerMatchingEffects(self, data, triggeringEntity, effectName, tableParams, cachedTableParams)
    end
    
end

///////////////////////
// Private functions //
///////////////////////
function GetAssetNameFromType(effectTable)

    for index, assetName in ipairs(kEffectTypes) do
    
        if effectTable[assetName] then
        
            return effectTable[assetName]
            
        end
        
    end
    
    return nil

end

// Find string representing animation or choose random animation from table if specified
// Pass surface to substitute in for first %s, if any.
function EffectManager:ChooseAssetName(effectTable, surfaceValue, triggeringEntity)

    local assetName = GetAssetNameFromType(effectTable)   
    if assetName then
    
        if type(assetName) == "table" then
            assetName = chooseWeightedEntry(assetName)
        end

    else
        assetName = ""
    end
    
    if string.find(assetName, "%%s") then
    
        if surfaceValue and surfaceValue ~= "" then
            assetName = string.format(assetName, surfaceValue)
        elseif self:GetDisplayDebug(effectTable, triggeringEntity) then
            Print("EffectManager:ChooseAssetName(): Trying to trigger \"%s\" but surface is \"%s\".", assetName, ToString(surfaceValue))
        end
        
    end
    
    return assetName
    
end

function EffectManager:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)

    local cinematicName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)
    if cinematicName == "" then
        return
    end

    local coords  = triggeringParams[kEffectHostCoords]    
    local player  = GetPlayerFromTriggeringEntity(triggeringEntity)
    local success = false
    local effectEntity = nil
    
    // World cinematics
    if effectTable[kCinematicType] then
    
        effectEntity = Shared.CreateEffect(nil, cinematicName, nil, coords)
        success = true

    // World positioned shared cinematics
    elseif effectTable[kPlayerCinematicType] then
    
        effectEntity = Shared.CreateEffect(player, cinematicName, nil, coords)
        success = true        

    // Parent effect to triggering entity
    elseif effectTable[kParentedCinematicType] then
    
        local inWorldSpace = effectTable[kEffectParamWorldSpace]
        local attachPoint = effectTable[kEffectParamAttachPoint] 
        if attachPoint then
            effectEntity = Shared.CreateAttachedEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity(), attachPoint, false, inWorldSpace == true)
        else
            effectEntity = Shared.CreateEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity())
        end
        
        success = true
        
    // Third-person weapon cinematics
    elseif effectTable[kWeaponCinematicType] then

        if Server then
        
            local inWorldSpace = effectTable[kEffectParamWorldSpace]
            local attachPoint = effectTable[kEffectParamAttachPoint] 
            if attachPoint then
                
                if player then
                
                    effectEntity = Shared.CreateAttachedEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity(), attachPoint, false, inWorldSpace == true)
                    success = true
                    
                else
                    Print("InternalTriggerCinematic(%s, weapon_cinematic): Couldn't find parent for entity (%s).%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
                end
                
            else
               Print("InternalTriggerCinematic(%s, weapon_cinematic): No attach point specified.%s", cinematicName, self:GetQueuedText()) 
            end
            
        else
            success = true            
        end

    // View model cinematics            
    elseif effectTable[kViewModelCinematicType] then
    
        if Client then
        
            local inWorldSpace = effectTable[kEffectParamWorldSpace]
            local attachPoint = effectTable[kEffectParamAttachPoint]
            
            if player then
            
                local viewModel = player:GetViewModelEntity()
                if viewModel and not player:GetIsThirdPerson() then
                
                    effectEntity = Shared.CreateAttachedEffect(player, cinematicName, viewModel, Coords.GetIdentity(), attachPoint or "", true, inWorldSpace == true)    
                    success = true
                    
                else
                    Print("InternalTriggerCinematic(%s, viewmodel_cinematic): No view model entity found for entity %s.%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
                end

            else
                Print("InternalTriggerCinematic(%s): Couldn't find parent for entity %s.%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
            end    
            
        else
            success = true
        end        

    elseif effectTable[kLoopingCinematicType] then
        
        if triggeringEntity and triggeringEntity.AttachEffect then
        
            success = triggeringEntity:AttachEffect(cinematicName, coords, Cinematic.Repeat_Endless)            
            
        end

    elseif effectTable[kStopCinematicType] then
        
        if triggeringEntity and triggeringEntity.RemoveEffect then
            success = triggeringEntity:RemoveEffect(cinematicName)
        end

    elseif effectTable[kStopViewModelCinematicType] then
    
        if player then
        
            local viewModel = player:GetViewModelEntity()
            if viewModel then
                if viewModel.RemoveEffect then
                    success = viewModel:RemoveEffect(cinematicName)
                end
            end
            
        end
    
    end
    
    if success then
        self:DisplayDebug(ToString(cinematicName), effectTable, triggeringParams, triggeringEntity)
    end
    
    CopyRelevancyMask(triggeringEntity, effectEntity)
    
    return success
    
end

// Assumes triggering entity is either a player, or a weapon who's owner is a player
function GetPlayerFromTriggeringEntity(triggeringEntity)

    if triggeringEntity then
        
        if triggeringEntity:isa("Player") then
            return triggeringEntity
        else
            local parent = triggeringEntity:GetParent()
            if parent then
                return parent
            end
        end
        
    end

    return nil
    
end         

// Returns false if an error was encountered (returns true even if sound was supposed to have stopped when not playing
function EffectManager:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)

    local success = false
    local soundAssetName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)
    local coords = triggeringParams[kEffectHostCoords]    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local volume = ConditionalValue(triggeringParams[kEffectParamVolume], triggeringParams[kEffectParamVolume], 1.0)
    local inWorldSpace = effectTable[kEffectParamWorldSpace]
    local soundEffect = nil
    
    if soundAssetName == '' then
        // DL: WHAAAT?
        return false
    end
    
    self:DisplayDebug(ToString(soundAssetName), effectTable, triggeringParams, triggeringEntity)
    
    // Play world sound
    if effectTable[kSoundType] then
    
        if player and inWorldSpace ~= true and inWorldSpaceExceptPlayer ~= true then
        
            // Shared player sound
            soundEffectEntity = StartSoundEffectOnEntity(soundAssetName, player, volume)
            success = true
            
        else
        
            // World sound (don't send to the player if inWorldSpaceExceptPlayer is true).
            soundEffectEntity = StartSoundEffectAtOrigin(soundAssetName, coords.origin, volume)
            success = true
            
        end
        
    elseif effectTable[kPlayerSoundType] then
        
        soundEffectEntity = StartSoundEffectOnEntity(soundAssetName, player, volume, player)
        success = true
        
    // Play parented sound
    elseif effectTable[kParentedSoundType] then
    
        soundEffectEntity = StartSoundEffectOnEntity(soundAssetName, player, volume, nil)
        success = true
        
    elseif effectTable[kPrivateSoundType] then
    
        soundEffectEntity = StartSoundEffectForPlayer(soundAssetName, player, volume)
        success = true
        
    elseif effectTable[kStopSoundType] then
    
        // Passes in "" if we are to stop all sounds
        // Stop sounds on the triggering entity.
        Shared.StopSound(player, soundAssetName, triggeringEntity)
        // Make sure sounds are stopped for this player too.
        Shared.StopSound(player, soundAssetName)
        
        success = true
        
    end
    
    CopyRelevancyMask(triggeringEntity, soundEffectEntity)
    
    return success
    
end

function EffectManager:InternalStopEffects(effectTable, triggeringParams, triggeringEntity)

    local success = false
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    
    self:DisplayDebug("all", effectTable, triggeringParams, triggeringEntity)

    // Passes in "" if we are to stop all sounds
    Shared.StopSound(player, "", triggeringEntity)
    
    success = true
    
    return success
    
end

function EffectManager:InternalTriggerDecal(effectTable, triggeringParams, triggeringEntity)

    local success = false
    
    if effectTable[kDecalType] then
    
        // Read specified material
        local materialName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)    
        if materialName then
        
            local ignorePlayer = nil // TODO: figure out player to ignore
            local scale = ConditionalValue(type(effectTable[kEffectParamScale]) == "number", effectTable[kEffectParamScale], 1)
            success = Shared.CreateTimeLimitedDecal(materialName, triggeringParams[kEffectHostCoords], scale, ignorePlayer)
        
        end
        
    end
    
    return success
    
end

// Destroy expired decals and remove from list.
local function removeExpiredDecal(decalPair)

    if decalPair[2] < 0 then
    
        //Print("Decal expired")
        Client.DestroyRenderDecal( decalPair[1] )
        return true
        
    end
    
    return false
    
end

function EffectManager:UpdateDecals(deltaTime)

    if self.decalList and Client then
    
        // Reduce lifetime of decals.
        for d = 1, #self.decalList do
        
            local decalPair = self.decalList[d]
            decalPair[2] = decalPair[2] - deltaTime
            
        end
        
        table.removeConditional(self.decalList, removeExpiredDecal)
        
    end
    
end

function EffectManager:OnUpdate(deltaTime)

    PROFILE("EffectManager:OnUpdate")
    
    self:UpdateDecals(deltaTime)
    
end
