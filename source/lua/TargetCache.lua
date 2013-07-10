// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TargetCache.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Allows for fast target selection for AI units such as hydras and sentries. 
// 
// Gains most of its speed by using the fact that the majority of potential targets don't move
// (static) while a minority is mobile. 
// 
// Possible targets must implement one of the StaticTargetMixin and MobileTargetMixin. Mobile targets
// can move freely, but StaticTargetMixins must call self:StaticTargetMoved() whenever they change
// their location. As its fairly expensive to deal with a static target (all AI shooters in range will
// trace to its location), it should not be done often (its intended to allow teleportation of
// structures).
//
// To speed things up even further, the concept of TargetType is used. Each TargetType maintains a
// dictionary of created entities that match its own type. This allows for a quick filtering away of
// uninterresting targets, without having to check their type or team.
//
// The static targets are kept in a per-attacker cache. Usually, this table is empty, meaning that
// 90% of all potential targets are ignored at zero cpu cost. The remaining targets are found by
// using the fast ranged lookup (Shared.GetEntitiesWithinRadius()) and then using the per type list
// to quickly ignore any non-valid targets, only then checking validity, range and visibility. 
//
// The TargetSelector is the main interface. It is configured, one per attacker, with the targeting
// requriements (max range, if targets must be visible, what targetTypes, filters and prioritizers).
//
// The TargetSelector is assumed NOT to move. If it starts moving, it must call selector:AttackerMoved()
// before its next acquire target, in order to invalidate all cached targeting information. 
//
// Once configured, new targets may be acquired using AcquireTarget or AcquireTargets, and the validity
// of a current target can be check by ValidateTarget().
//
// Filters are used to reject targets that are not to valid. 
//
// Prioritizers are used to prioritize among targets. The default prioritizer chooses targets that
// can damage the attacker before other targets.
// 
Script.Load("lua/StaticTargetMixin.lua") 
Script.Load("lua/MobileTargetMixin.lua") 

//
// TargetFilters are used to remove targets before presenting them to the prioritizers
// 

//
// Removes targets that are not inside the maxPitch
//
function PitchTargetFilter(attacker, minPitchDegree, maxPitchDegree)

    return function(target, targetPoint)
        local origin = GetEntityEyePos(attacker)
        local viewCoords = GetEntityViewAngles(attacker):GetCoords()
        local v = targetPoint - origin
        local distY = Math.DotProduct(viewCoords.yAxis, v)
        local distZ = Math.DotProduct(viewCoords.zAxis, v)
        local pitch = 180 * math.atan2(distY,distZ) / math.pi
        result = pitch >= minPitchDegree and pitch <= maxPitchDegree
        // Log("filter %s for %s, v %s, pitch %s, result %s (%s,%s)", target, attacker, v, pitch, result, minPitchDegree, maxPitchDegree)
        return result
    end
    
end

function CloakTargetFilter()

    return function(target, targetPoint)
      return not HasMixin(target, "Cloakable") or not target:GetIsCloaked()
    end
    
end 

//
// Only lets through damaged targets
//
function HealableTargetFilter(healer)
    return function(target, targetPoint) return target:AmountDamaged() > 0 end
end

//
function RangeTargetFilter(origin, sqRange)
    return function(target, targetPoint) return (targetPoint - origin):GetLengthSquared() end
end

//
// Prioritizers are used to prioritize one kind of target over others
// When selecting targets, the range-sorted list of targets are run against each supplied prioritizer in turn
// before checking if the target is visible. If the prioritizer returns true for the target, the target will
// be selected if it is visible (if required). If not visible, the selection process continues.
// 
// Once all user-supplied prioritizers have run, a final run through will select the closest visible target.
// 

//
// Selects target based on class
//
function IsaPrioritizer(className)
    return function(target) return target:isa(className) end
end

//
// Selects targets based on if they can hurt us
//
function HarmfulPrioritizer()
    return function(target) return target:GetCanGiveDamage() end
end

//
// Selects everything 
//
function AllPrioritizer()
    return function(target) return true end
end



//
// The target type is used to classify entities when they are created so we don't spend any
// time thinking about shooting at stuff that we shouldn't be thinking about. 
// Also, the static target type can be used to remove entities that cannot be hit because of
// range and LOS blocking. As this eliminates pretty much 90% of all potential targets, target
// selection speeds up by about 1000%
// 
class 'TargetType'

//
// An entity belongs to a TargetType if it 
// 1. matches the team
// 2. HasMixin(tag) 
//
function TargetType:Init(name, teamType, tag)
    self.name = name
    self.teamType = teamType
    self.tag = tag
    
    // Log("Init %s: %s, %s", name, teamType, tag)

    // the entities that have been selected by their TargetType. A proper hashtable, not a list.
    self.entityIdMap = {}
    
    // wonder how much this slows down lookups? 
    self.teamFilterFunction = function (entity) return entity:GetTeamType() == teamType end
        
    return self
end


/**
 * Notification that a new entity id has been added
 */
function TargetType:EntityAdded(entity)
    if self:ContainsType(entity) and not self.entityIdMap[entity:GetId()] then
        // Log("%s: added %s", self.name, entity) 
        self.entityIdMap[entity:GetId()] = true
        self:OnEntityAdded(entity)
    end
end

/**
 * Notification that a new entity id has been added
 */
function TargetType:EntityMoved(entity)
    if self:ContainsType(entity) and self.entityIdMap[entity:GetId()] then
        self:OnEntityMoved(entity)
    end
end

/**
 * Notification that an entity id has been removed. 
 */
function TargetType:EntityRemoved(entity)
    if entity and self.entityIdMap[entity:GetId()] then
        self.entityIdMap[entity:GetId()] = nil
        // Log("%s: removed %s", self.name, entity) 
        self:OnEntityRemoved(entity)    
    end
end


/**
 * True if we the entity belongs to our TargetType
 */
function TargetType:ContainsType(entity)
    return HasMixin(entity, self.tag) and entity:GetTeamType() == self.teamType
end


/**
 * Attach a target selector to this TargetType. 
 * 
 * The returned object must be supplied whenever an acquire target is made 
 */
function TargetType:AttachSelector(selector)
    assert(false, "Attach must be overridden")
end

/**
 * Detach a selector from this target type
 */
function TargetType:DetachSelector(selector)
    assert(false, "Detach must be overridden")
end

/**
 * Return all possible targets for this target type inside the given range. 
 * Note: for performance reasons, we don't filter team type here because its
 * more expensive to do it from inside the GetEntitiesXxx
 */
function TargetType:GetAllPossibleTargets(origin, range)
    return Shared.GetEntitiesWithTagInRange(self.tag, origin, range)
end

/**
 * Allow subclasses to react to the adding of a new entity id
 */
function TargetType:OnEntityAdded(id)
end

/**
 * Allow subclasses to react to the adding of a new entity id. 
 */
function TargetType:OnEntityRemoved(id)
end

/**
 * Handle static targets
 */
class 'StaticTargetType' (TargetType)

function StaticTargetType:Init(name, teamType, tag)
    self.cacheMap = {}
    return TargetType.Init(self, name, teamType, tag)
end

function StaticTargetType:AttachSelector(selector)
    // each selector gets its own cache of non-moving entities. The selector must be detached when the owning entitiy dies
    self.cacheMap[selector] = StaticTargetCache():Init(self, selector)
    return self.cacheMap[selector]
end

// detach the selector. Must be called when the entity owning the selector dies
function StaticTargetType:DetachSelector(selector)
    self.cacheMap[selector] = nil
end

function StaticTargetType:OnEntityAdded(entity)
    for id,cache in pairs(self.cacheMap) do
        cache:OnEntityAdded(entity)
    end
end

function StaticTargetType:OnEntityMoved(entity)
    for id,cache in pairs(self.cacheMap) do
        cache:OnEntityMoved(entity) 
    end
end

function StaticTargetType:OnEntityRemoved(entity)
    for id,cache in pairs(self.cacheMap) do
        cache:OnEntityRemoved(entity)
    end
end

class 'StaticTargetCache'

function StaticTargetCache:Init(targetType, selector)
    self.targetType = targetType
    self.selector = selector
    self.targetIdToRangeMap = nil 

    return self
end

function StaticTargetCache:Log(formatString, ...)
    if self.selector.debug then
        formatString = "%s[%s]: " .. formatString
        Log(formatString, self.selector.attacker, self.targetType.name, ...)
    end
end

function StaticTargetCache:OnEntityAdded(entity)
    if self.targetIdToRangeMap then
        self:MaybeAddTarget(entity, self.selector.attacker:GetEyePos())
    end
end

// just clear any info we might have had on that id
function StaticTargetCache:InvalidateDataFor(entity)
    if self.targetIdToRangeMap then
        self.targetIdToRangeMap[entity:GetId()] = nil
    end
end

function StaticTargetCache:OnEntityMoved(entity)
    self:InvalidateDataFor(entity)
end

function StaticTargetCache:OnEntityRemoved(entity)
    self:InvalidateDataFor(entity)
end

//
// Make sure the cache is valid before using it
//
function StaticTargetCache:ValidateCache()
    if not self.targetIdToRangeMap then 
        self.targetIdToRangeMap = {}
        local eyePos = self.selector.attacker:GetEyePos()
        local targets = self.targetType:GetAllPossibleTargets(eyePos, self.selector.range)
        for _, target in ipairs(targets) do
            if target:GetTeamType() == self.targetType.teamType then
                self:MaybeAddTarget(target, eyePos)
            end
        end
    end
end

/**
 * Append possible targets, range pairs to the targetList
 */
function StaticTargetCache:AddPossibleTargets(selector, result)
    PROFILE("StaticTargetCache:AddPossibleTargets")
    
    self:ValidateCache(selector)

    local count = 0
    for targetId, range in pairs(self.targetIdToRangeMap) do
        PROFILE("StaticTargetCache:AddPossibleTargets/loop")
        local target = Shared.GetEntity(targetId)
        
            if target and target:GetIsAlive() and target:GetCanTakeDamage() then 
                PROFILE("StaticTargetCache:AddPossibleTargets/_ApplyFilters")
                if selector:_ApplyFilters(target, target:GetEngagementPoint()) then
                    table.insert(result,target)
                    //Log("%s: static target %s at range %s", selector.attacker, target, range)
                end
            end
    end

end

/**
 * If the attacker moves, the cache has to be invalidated. 
 */
function StaticTargetCache:AttackerMoved()
    self.targetIdToRangeMap = nil    
end

/**
 * Check if the target is a possible target for us
 *
 * Make sure its id is in our map, and that its inside range
 */
function StaticTargetCache:PossibleTarget(target, origin, range)
    self:ValidateCache()
    local r = self.targetIdToRangeMap[target:GetId()]
    return r and r <= range
end

function StaticTargetCache:MaybeAddTarget(target, origin)
    local inRange = nil
    local visible = nil
    local range = -1    
    local rightType = self.targetType.entityIdMap[target:GetId()]
    if rightType then
        local targetPoint = target:GetEngagementPoint()
        range = (origin - targetPoint):GetLength()
        inRange = range <= self.selector.range
        if inRange then
            visible = true
            if (self.selector.visibilityRequired) then
                // trace as a bullet, but ignore everything but the target.
                local trace = Shared.TraceRay(origin, targetPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOnly(target))
//                self:Log("f %s, e %s", trace.fraction, trace.entity)       
                visible = trace.entity == target or trace.fraction == 1
                if visible and trace.entity == target then
                    range = range * trace.fraction
                end
            end
        end          
    end
    if inRange and visible then 
        // save the target and the range to it
        self.targetIdToRangeMap[target:GetId()] = range
//        self:Log("%s added at range %s", target, range)
    else
        if not rightType then
  //          self:Log("%s rejected, wrong type", target) 
        else
    //        self:Log("%s rejected, range %s, inRange %s, visible %s", target, range, inRange, visible)
        end
    end  
end


function StaticTargetCache:Debug(selector, full)
    Log("%s :", self.targetType.name)
    self:ValidateCache(selector)
    local origin = GetEntityEyePos(selector.attacker)
    // go through all static targets, showing range and curr
    for targetId,_ in pairs(self.targetType.entityIdMap) do
        local target = Shared.GetEntity(targetId)
        if target then
            local targetPoint = target:GetEngagementPoint()
            local range = (origin - targetPoint):GetLength()
            local inRange = range <= selector.range
            if full or inRange then
                local valid = target:GetIsAlive() and target:GetCanTakeDamage()
                local unfiltered = selector:_ApplyFilters(target, targetPoint)
                local visible = selector.visibilityRequired and GetCanAttackEntity(selector.attacker, target) or "N/A"
                local inCache = self.targetIdToRangeMap[targetId] ~= nil
                local shouldBeInCache = inRange and (visible ~= false) 
                local cacheTxt = (inCache == shouldBeInCache and "") or (string.format(", CACHE %s != shouldBeInCache %s!", ToString(inCache), ToString(shouldBeInCache)))
                Log("%s: in range %s, valid %s, unfiltered %s, visible %s%s", target, inRange, valid, unfiltered, visible, cacheTxt)
            end
        end
    end
end

/**
 * Handle mobile targets
 */
class 'MobileTargetType' (TargetType)

function MobileTargetType:AttachSelector(selector)
    // we don't do any caching on a per-selector basis, so just return ourselves
    return self
end

function MobileTargetType:DetachSelector(select)
    // do nothing
end


function MobileTargetType:AddPossibleTargets(selector, result)
    PROFILE("MobileTargetType:AddPossibleTargets")
    local origin = GetEntityEyePos(selector.attacker)
    local entityIds = {}
    local targets = self:GetAllPossibleTargets(origin, selector.range)
    
    for _, target in ipairs(targets) do
        if target:GetTeamType() == self.teamType then
            local targetPoint = target:GetEngagementPoint()
       
            if target:GetIsAlive() and target:GetCanTakeDamage() and selector:_ApplyFilters(target, targetPoint) then
                table.insert(result, target)
            end
        end
    end
end

function MobileTargetType:AttackerMoved()  
    // ignore: no caching
end

function MobileTargetType:PossibleTarget(target, origin, range)
    local r = nil
    if self.entityIdMap[target:GetId()] then
        r = (origin - target:GetEngagementPoint()):GetLength()
    end
    return r and r <= range
end


function MobileTargetType:Debug(selector, full)
    // go through all mobile targets, showing range and curr
    local origin = GetEntityEyePos(selector.attacker)
    local targets = self:GetAllPossibleTargets(origin, selector.range)

    Log("%s : %s entities (%s) inside %s range (%s)", self.name, #targets, self.tag, selector.range, targets)
    
    for _, target in ipairs(targets) do
        if target:GetTeamType() == self.teamType then
            local targetPoint = target:GetEngagementPoint()
            local range = (origin - targetPoint):GetLength()      
            local valid = target:GetIsAlive() and target:GetCanTakeDamage()
            local unfiltered = selector:_ApplyFilters(target, targetPoint)
            local visible = selector.visibilityRequired and GetCanAttackEntity(selector.attacker, target) or "N/A"
            local inRadius = table.contains(targets, target)
            Log("%s, in range %s (%s), in radius %s, valid %s, unfiltered %s, visible %s", target, range, inRange, inRadius, valid, unfiltered, visible)
        end
    end
end

//
// Note that we enumerate each individual instantiated class here. Adding new structures means that these must be updated.
//
/** Static targets for marines. The Whip is exluded because it can move. */
kMarineStaticTargets = StaticTargetType():Init( "MarineStatic", kAlienTeamType, StaticTargetMixin.type )
/** Mobile targets for marines */
kMarineMobileTargets = MobileTargetType():Init( "MarineMobile", kAlienTeamType, MobileTargetMixin.type )
/** Static targets for aliens */
kAlienStaticTargets = StaticTargetType():Init( "AlienStatic", kMarineTeamType, StaticTargetMixin.type )
/** Mobile targets for aliens */
kAlienMobileTargets = MobileTargetType():Init( "AlienMobile", kMarineTeamType, MobileTargetMixin.type )
/** Alien static heal targets */
kAlienStaticHealTargets = kMarineStaticTargets
/** Alien mobile heal targets */
kAlienMobileHealTargets = kMarineMobileTargets


// Used as final step if all other prioritizers fail
TargetType.kAllPrioritizer = AllPrioritizer()

// List all target class
TargetType.kAllTargetTypes = {
    kMarineStaticTargets, 
    kMarineMobileTargets,
    kAlienStaticTargets, 
    kAlienMobileTargets
}

    
//
// called by XxxTargetMixin when targetable units are created or destroyed
//
function TargetType.OnDestroyEntity(entity)
    for _,tc in ipairs(TargetType.kAllTargetTypes) do
        tc:EntityRemoved(entity)
    end
end

function TargetType.OnCreateEntity(entity)
    for _,tc in ipairs(TargetType.kAllTargetTypes) do
        tc:EntityAdded(entity)
    end
end

function TargetType.OnTargetMoved(entity)
    for _,tc in ipairs(TargetType.kAllTargetTypes) do
        tc:EntityMoved(entity)
    end
end


//
// ----- TargetSelector - simplifies using the TargetCache. --------------------
//
// It wraps the static list handling and remembers how targets are selected so you can acquire and validate
// targets using the same rules. 
//
// After creating a target selector in the initialization of the attacker, you only then need to call the AcquireTarget()
// to scan for a new target and ValidateTarget(target) to validate it.
// While the TargetSelector assumes that you don't move, if you do move, you must call AttackerMoved().
//

class "TargetSelector"

//
// Setup a target selector.
//
// A target selector allows one attacker to acquire and validate targets. 
//
// The attacker should stay in place. If the attacker moves, the AttackerMoved() method MUST be called.
//
// Arguments: 
// - attacker - the attacker.
//
// - range - the maximum range of the attack. 
//
// - visibilityRequired - true if the target must be visible to the attacker
//
// - targetTypeList - list of targetTypees to use
//
// - filters - a list of filter functions (nil ok), used to remove alive and in-range targets. Each filter will
//             be called with the target and the targeted point on that target. If any filter returns true, then the target is inadmissable.
//
// - prioritizers - a list of selector functions, used to prioritize targets. The range-sorted, filtered
//               list of targets is run through each selector in turn, and if a selector returns true the
//               target is then checked for visibility (if visibilityRequired), and if seen, that target is selected.
//               Finally, after all prioritizers have been run through, the closest visible target is choosen.
//               A nil prioritizers will default to a single HarmfulPrioritizer
//

local function DestroyTargetSelector(targetSelector)

    for targetType,_ in pairs(targetSelector.targetTypeMap) do
        targetType:DetachSelector(targetSelector)
    end
    
end

function TargetSelector:Init(attacker, range, visibilityRequired, targetTypeList, filters, prioritizers)

    assert(HasMixin(attacker, "TargetCache"))
    
    self.attacker = attacker
    self.range = range
    self.visibilityRequired = visibilityRequired
    self.filters = filters
    self.prioritizers = prioritizers or { HarmfulPrioritizer() }
    
    self.targetTypeMap = { }
    for _, targetType in ipairs(targetTypeList) do
        self.targetTypeMap[targetType] = targetType:AttachSelector(self)
    end
    
    // This will allow target selectors to be cleaned up when the attack is destroyed.
    // targetSelectorsToDestroy comes from TargetCacheMixin.
    table.insert(attacker.targetSelectorsToDestroy, function() DestroyTargetSelector(self) end)
    
    self.debug = false 
    
    return self
    
end

//
// Acquire maxTargets targets inside the given rangeOverride.
//
// both may be left out, in which case maxTargets defaults to 1000 and rangeOverride to standard range
//
// The rangeOverride, if given, must be <= the standard range for this selector
// If originOverride is set, the range filter will filter from this point
// Note that no targets can be selected outside the fixed target selector range.
//
function TargetSelector:AcquireTargets(maxTargets, rangeOverride, originOverride)
    local savedFilters = self.filters
    if rangeOverride then
        local filters = {}
        if self.filters then
            table.copy(self.filters, filters)
        end
        local origin = originOverride or GetEntityEyePos(self.attacker)
        table.insert(filters, RangeTargetFilter(origin, rangeOverride))
        self.filters = filters
    end

    // 1000 targets should be plenty ...
    maxTargets = maxTargets or 1000

    local targets = self:_AcquireTargets(maxTargets)
    return targets
end

//
// Return true if the target is acceptable to all filters
//
function TargetSelector:_ApplyFilters(target, targetPoint)
    //Log("%s: _ApplyFilters on %s, %s", self.attacker, target, targetPoint)
    if self.filters then
        for _, filter in ipairs(self.filters) do
            if not filter(target, targetPoint) then
                //Log("%s: Reject %s", self.attacker, target)
                return false
            end
            //Log("%s: Accept %s", self.attacker, target)
        end
    end
    return true
end

//
// Check if the target is possible. 
//
function TargetSelector:_PossibleTarget(target)
    if target and self.attacker ~= target and (target.GetIsAlive and target:GetIsAlive()) and target:GetCanTakeDamage() then
        local origin = self.attacker:GetEyePos()
        
        local possible = false
        for tc,tcCache in pairs(self.targetTypeMap) do
            possible = possible or tcCache:PossibleTarget(target, origin, self.range) 
        end
        if possible then
            local targetPoint = target:GetEngagementPoint()
            if self:_ApplyFilters(target, targetPoint) then
                return true
            end
        end
    end            
    return false
end

function TargetSelector:ValidateTarget(target)
    local result = false
    if target then
        result = self:_PossibleTarget(target)
        if result and self.visibilityRequired then
            result = GetCanAttackEntity(self.attacker, target)
        end
//        self:Log("validate %s -> %s", target, result)
    end
    return result       
end


//
// AcquireTargets with maxTarget set to 1, and returning the selected target
//
function TargetSelector:AcquireTarget()
    return self:_AcquireTargets(1)[1]
end

//
// Acquire a certain number of targets using filters to reject targets and prioritizers to prioritize them
//
// Arguments: See TargetCache:CreateSelector for missing argument descriptions
// - maxTarget - maximum number of targets to acquire
//
// Return:
// - the chosen targets
//
function TargetSelector:_AcquireTargets(maxTargets)
    PROFILE("TargetSelector:_AcquireTargets")
    local targets = self:_GetRawTargetList() 

    local result = {}
    local checkedTable = {} // already checked entities
    local finalRange = nil
    
    // go through the prioritizers until we have filled up on targets
    if self.prioritizers then 
        for _, prioritizer in ipairs(self.prioritizers) do
            self:_InsertTargets(result, checkedTable, prioritizer, targets, maxTargets)
            if #result >= maxTargets then
                break
            end
        end
    end
    
    // final run through with an all-selector
    if #result < maxTargets then
        self:_InsertTargets(result, checkedTable, TargetType.kAllPrioritizer, targets, maxTargets)
    end
  
    /*
    if #result > 0 then
        Log("%s: found %s targets (%s)", self.attacker, #result, result[1])
    end
    /**/
    return result
end


/**
 * Return a sorted list of alive and GetCanTakeDamage'able targets, sorted by range. 
 */
function TargetSelector:_GetRawTargetList()
    PROFILE("TargetSelector:_GetRawTargetList")
    local result = {}

    // get potential targets from all targetTypees
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:AddPossibleTargets(self, result)
    end

    if (true) then
       PROFILE("TargetSelector:_GetRawTargetList")
       Shared.SortEntitiesByDistance(self.attacker:GetEyePos(),result)
    end
    
    return result
end 

//
// Insert valid target into the resultTable until it is full.
// 
// Let a selector work on a target list. If a selector selects a target, a trace is made 
// and if successful, that target and range is inserted in the resultsTable.
// 
// Once the results size reaches maxTargets, the method returns. 
//
function TargetSelector:_InsertTargets(foundTargetsList, checkedTable, prioritizer, targets, maxTargets)
    PROFILE("TargetSelector:_InsertTargets")
    for _, target in ipairs(targets) do
        // Log("%s: check %s, ct %s, prio %s", self.attacker, target, checkedTable[target], prioritizer(target))
        local include = false
        if not checkedTable[target] and prioritizer(target) then
            if self.visibilityRequired then 
                include = GetCanAttackEntity(self.attacker, target) 
            else
                include = true
            end
            checkedTable[target] = true
        end            
        if include then
            //Log("%s targets %s", self.attacker, target)
            table.insert(foundTargetsList,target)
            if #foundTargetsList >= maxTargets then
                break
            end
        end                       
    end
end


//
// if the location of the unit doing the target selection changes, its static target list
// must be invalidated. 
//
function TargetSelector:AttackerMoved()
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:AttackerMoved()
    end
end

//
// Dump debugging info for this TargetSelector
//
function TargetSelector:Debug(cmd)
    local full = cmd == "full" // list all possible targets, even those out of range
    self.debug = cmd == "log" and not self.debug or self.debug // toggle logging for this selector only
    if cmd == "reset" then
        self:AttackerMoved()
    end
    Log("%s @ %s: target debug (full=%s, log=%s)", self.attacker, self.attacker:GetOrigin(), full, self.debug)
    for tc,tcCache in pairs(self.targetTypeMap) do
        tcCache:Debug(self, full)
    end
end

function TargetSelector:Log(formatString, ...)
    if self.debug then
        formatString = "%s: " .. formatString
        Log(formatString, self.attacker, ...)
    end
end