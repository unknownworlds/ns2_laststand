// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OrderSelfMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

OrderSelfMixin = { }
OrderSelfMixin.type = "OrderSelf"

local kFindStructureRange = 20
local kFindFriendlyPlayersRange = 15
local kTimeToDefendSinceTakingDamage = 5
// What percent of health an enemy structure is below when it is considered a priority for attacking.
local kPriorityAttackHealthScalar = 0.6
// How far away (squared) a move order location needs to be from the player's current location in
// order to copy it. We want to avoid copying move orders if they are close to the player as
// it is very likely the player has already completed nearby move orders and they are just
// continuously being copied between nearby players unless all of them complete the order
// at the same time.
local kMoveOrderDistSqRequiredForCopy = 15 * 15

OrderSelfMixin.expectedCallbacks = 
{
    GetTeamNumber = "Returns the team number this Entity is on." 
}

OrderSelfMixin.expectedConstants = 
{
    kPriorityAttackTargets = "Which target types to prioritize for attack orders after the low health priority has been considered." 
}

OrderSelfMixin.expectedMixins =
{
    Orders = ""
}

OrderSelfMixin.optionalCallbacks =
{
    OnOrderSelfComplete = "Called client side after the player has completed an order. Order type is passed."
}

OrderSelfMixin.networkVars =
{
    timeOfLastOrderComplete   = "private time",
    lastOrderType             = "private enum kTechId",
}

// How often to look for orders.
local kOrderSelfUpdateRate = 2

function OrderSelfMixin:__initmixin()

    self.timeOfLastOrderComplete = 0
    self.lastOrderType = kTechId.None
    
    if Server then
        self:AddTimedCallback(OrderSelfMixin._UpdateOrderSelf, kOrderSelfUpdateRate)
    elseif Client then
        self.clientTimeOrderComplete = 0
    end
    
end

local function FindPlayerOrdersToCopy(self, friendlyPlayersNearby)

    local closestPlayer = nil
    local closestPlayerDist = Math.infinity
    for i, player in ipairs(friendlyPlayersNearby) do
    
        if player:GetHasOrder() then
        
            local orderType = player:GetCurrentOrder():GetType()
            local orderDistSq = (self:GetOrigin() - player:GetCurrentOrder():GetLocation()):GetLengthSquared()
            local isMoveOrder = orderType == kTechId.Move
            if not isMoveOrder or orderDistSq >= kMoveOrderDistSqRequiredForCopy then
            
                local playerDist = (player:GetOrigin() - self:GetOrigin()):GetLengthSquared()
                if playerDist < closestPlayerDist then
                
                    closestPlayer = player
                    closestPlayerDist = playerDist
                    
                end
                
            end
            
        end
        
    end
    
    if closestPlayer then
    
        local playerOrder = closestPlayer:GetCurrentOrder()
        return kTechId.None ~= self:GiveOrder(playerOrder:GetType(), playerOrder:GetParam(), playerOrder:GetLocation(), playerOrder:GetOrientation())
        
    end
    
    return false

end
AddFunctionContract(FindPlayerOrdersToCopy, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

/**
 * Find closest structure with health less than the kPriorityAttackHealthScalar, otherwise just closest matching kPriorityAttackTargets, otherwise closest structure.
 */
local function FindBuildOrder(self, structuresNearby)

    if self.GetCheckForAutoConstructOrder and not self:GetCheckForAutoConstructOrder() then
        return false
    end    

    local closestStructure = nil
    local closestStructureDist = Math.infinity

    for i, structure in ipairs(structuresNearby) do
    
        local verticalDist = structure:GetOrigin().y - self:GetOrigin().y
    
        if verticalDist < 3 then
    
            local structureDist = (structure:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            local closerThanClosest = structureDist < closestStructureDist

           if closerThanClosest and not structure:GetIsBuilt() and structure:GetCanConstruct(self) then
           
               closestStructure = structure
               closestStructureDist = structureDist
               
            end
        
         end
        
    end
    
    if closestStructure then
        return kTechId.None ~= self:GiveOrder(kTechId.Construct, closestStructure:GetId(), closestStructure:GetOrigin(), nil, true, false)
    end
    
    return false

end
AddFunctionContract(FindBuildOrder, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

/**
 * Find closest structure with health less than the kPriorityAttackHealthScalar, otherwise just closest matching kPriorityAttackTargets, otherwise closest structure.
 */
local function FindWeldOrder(self, entitiesNearby)

    local closestStructure = nil
    local closestStructureDist = Math.infinity
    
    if self:isa("Marine") and not self:GetWeapon(Welder.kMapName) then
        return
    end
    
    // Do not give weld orders during combat.
    if GetAnyNearbyUnitsInCombat(self:GetOrigin(), 12, self:GetTeamNumber()) then
        return
    end
    
    for i, entity in ipairs(entitiesNearby) do
    
        if entity ~= self then
        
            local entityDist = (entity:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            local closerThanClosest = entityDist < closestStructureDist
            
            local weldAble = false
            
            if self:isa("Marine") then
            
                // Weld friendly players if their armor is below 75%.
                // Weld non-players when they are below 50%.
                weldAble = HasMixin(entity, "Weldable")
                weldAble = weldAble and (((entity:isa("Player") and not entity:isa("Spectator")) and entity:GetArmorScalar() < 0.75) or
                           (not entity:isa("Player") and entity:GetArmorScalar() < 0.5))
                
            end
            
            if self:isa("Gorge") then
                weldAble = entity:GetHealthScalar() < 1 and entity:isa("Player")
            end
            
            if HasMixin(entity, "Construct") and not entity:GetIsBuilt() then
                weldAble = false
            end
            
            if entity.GetCanBeHealed and not entity:GetCanBeHealed() then
                weldAble = false
            end    
            
            if closerThanClosest and weldAble then
            
                closestStructure = entity
                closestStructureDist = entityDist
               
            end
            
        end
        
    end
    
    if closestStructure then
    
        local orderTechId = kTechId.AutoWeld
        if self:isa("Gorge") then
            orderTechId = kTechId.AutoHeal
        end
    
        return kTechId.None ~= self:GiveOrder(orderTechId, closestStructure:GetId(), closestStructure:GetOrigin(), nil, true, false)
    end
    
    return false

end
AddFunctionContract(FindWeldOrder, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

local function GetCanOverwriteOrderType(orderType)
    return orderType == kTechId.AutoHeal or orderType == kTechId.AutoWeld
end

function OrderSelfMixin:_UpdateOrderSelf()

    local alive = not HasMixin(self, "Live") or self:GetIsAlive()
    if alive and (not self:GetHasOrder() or GetCanOverwriteOrderType(self:GetCurrentOrder():GetType()) ) then
    
        local friendlyStructuresNearby = GetEntitiesWithMixinForTeamWithinRange("Construct", self:GetTeamNumber(), self:GetOrigin(), kFindStructureRange)  
        local hasOrderNow = FindBuildOrder(self, friendlyStructuresNearby)
        
        if not hasOrderNow and not self:GetHasOrder() then
        
            local weldableNearby = GetEntitiesWithMixinForTeamWithinRange("Live", self:GetTeamNumber(), self:GetOrigin(), kFindStructureRange)  
            FindWeldOrder(self, weldableNearby)
            
        end
        
    end
    
    // Continue forever.
    return true
    
end
AddFunctionContract(OrderSelfMixin._UpdateOrderSelf, { Arguments = { "Entity" }, Returns = { "boolean" } })

if Server then

    function OrderSelfMixin:OnOrderComplete(currentOrder)

        self.timeOfLastOrderComplete = Shared.GetTime()
        self.lastOrderType = currentOrder:GetType()
    
    end

elseif Client then

    function OrderSelfMixin:OnProcessMove(input)
    
        if not Shared.GetIsRunningPrediction() and self.OnOrderSelfComplete then
        
            if self.timeOfLastOrderComplete ~= self.clientTimeOrderComplete then            
                self.clientTimeOrderComplete = self.timeOfLastOrderComplete
                self:OnOrderSelfComplete(self.lastOrderType)
            end
        
        end 
    
    end

end