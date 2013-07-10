//=============================================================================
//
// lua\Cyst_Server.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se) and 
// Charlie Cleveland (charlie@unknownworlds.com)
// 
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//============================================================================

Cyst.kThinkTime = 1

// How long we can be without a confirmation impulse before we disconnect
Cyst.kImpulseDisconnectTime = 15

function Cyst:SetCystParent(parent)

    assert(parent ~= self)
    
    self.parentId = parent:GetId()
    parent:AddChildCyst(self)
    
end

function Cyst:GetCanAutoBuild()

    local parent = self:GetCystParent()
    return parent and parent:GetIsBuilt()

end

/**
 * Return true if we are ACTUALLY connected, ie our ultimate parent is a Hive. 
 *
 * Note: this is valid only on the server, as the client may not (probably does not)
 * have all the entities in the chain to the hive loaded.
 * 
 * the GetIsConnected() method used the connect bit, which may not reflect the actual connection status.
 */
function Cyst:GetIsActuallyConnected()
    
    // Always in dev mode, for making movies and testing
    if Shared.GetDevMode() then
        return true
    end
    
    local parent = self:GetCystParent()
    if parent and parent ~= start then
    
        if parent:isa("Hive") then
            return true
        end
        return parent:GetIsActuallyConnected()
        
    end
    
    return false
    
end

function Cyst:OnKill()

    self:TriggerEffects("death")
    self.connected = false
    self:SetModel(nil)
    
    for key,id in pairs(self.children) do
    
        local cyst = Shared.GetEntity(id)
        if cyst then
            cyst.parentId = Entity.invalidId
            cyst.connected = false
        end
    
    end
    
end   

function Cyst:GetSendDeathMessageOverride()
    return false
end

function Cyst:OnEntityChange(entityId, newEntityId)
    
    if self.parentId == entityId then
        self.parentId = newEntityId or Entity.invalidId
    end

end

/**
 * If we can track to our new parent, use it instead
 */
function Cyst:TryNewCystParent(parent)

    local path = CreateBetweenEntities(self, parent)
    
    if path then
    
        local pathLength = GetPointDistance(path)
        if pathLength <= parent:GetCystParentRange() then
        
            self:ReplaceParent(parent)
            return true
            
        end
    
    end
    
    return false
    
end

/**
 * Try to find an actually connected parent. Connect to the closest entity (but bias hives).
 */
function Cyst:TryToFindABetterParent()

    local parent, path = GetCystParentFromPoint(self:GetOrigin(), self:GetCoords().yAxis, "GetIsActuallyConnected", self)
    
    if parent and path then
    
        self:ReplaceParent(parent)
        return true
        
    end
    
    return false
    
end

/**
 * Reconnect any other cysts to me
 */
function Cyst:ReconnectOthers()

    local cysts = GetEntitiesWithinRange("Cyst", self:GetOrigin(), self:GetCystParentRange())

    for _, cyst in ipairs(cysts) do
    
        // when working on the server side, always use the actually connected rather than the connected bit
        // the connected 
        if not cyst:GetIsActuallyConnected() then
            cyst:TryNewCystParent(self)
        end
        
    end
    
end

function Cyst:TriggerDamage()

    if self:GetCystParent() == nil then
    
        // Increase damage over time the longer it hasn't been connected if alien "islands" are 
        // being kept alive undesirably long by Crags, Gorges and such
        local damage = kCystUnconnectedDamage * Cyst.kThinkTime
        self:DeductHealth(damage)
        
    end
  
end

function Cyst:ReplaceParent(newParent)

    // make the peer our child and tell it to make us its parent via the given track
    newParent:AddChildCyst(self)
    self:ChangeParent(newParent)
    
end


function Cyst:ChangeParent(newParent)

    local oldParent = self:GetCystParent()
    self.children[""..newParent:GetId()] = nil    
    self:SetCystParent(newParent)    
    if oldParent then        
        oldParent:ChangeParent(self)        
    end 
    
end

function Cyst:FireImpulses(now)

    local removals = {}
    for key,id in pairs(self.children) do
    
        local child = Shared.GetEntity(id)
        if child == nil then
            removals[key] = true
        else
        
            // We ask the children to trigger the impulse to themselves
            if child.TriggerImpulse then
                child:TriggerImpulse(now)
            end
            
        end
        
    end
    
    for key,_ in pairs(removals) do
        self.children[key] = nil
    end
    
end

/**
 * Trigger an impulse to us along the track. 
 */
function Cyst:TriggerImpulse(now)

    if not self.impulseActive then
    
        self.impulseStartTime = now
        self.impulseActive = true   
        
    end
    
end

function Cyst:AddChildCyst(child)

    // Children can die; tragic; so only keep the id around
    self.children["" .. child:GetId()] = child:GetId()
    
end

function Cyst:OnTakeDamage(damage, attacker, doer, point)

    // When we take disconnection damage, don't play alerts or effects, just expire silently
    if doer ~= self then
        local team = self:GetTeam()
        if team.TriggerAlert then
            team:TriggerAlert(kTechId.AlienAlertStructureUnderAttack, self)
        end
    end
    
end