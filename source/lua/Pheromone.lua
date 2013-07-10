// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Pheromone.lua
//
// A way for the alien commander to communicate with his minions.
// 
// Goals
//   Create easy way for alien commander to communicate with his team without needing to click aliens and give orders. That wouldn’t fit.
//   Keep it feeling “bottom-up” so players can make their own choices
//   Have “orders” feel environmental
//
// First implementation
//   Create pheromones that act as a hive sight blip. Aliens can see pheromones like blips on their HUD. Examples: “Need healing”, “Need protection”, “Building here”, 
//   “Need infestation”, “Threat detected”, “Reinforce”. These are not orders, but informational. It’s up to aliens to decide what to do, if anything. 
//
//   Each time you create pheromones, it will create a new “signpost” at that location if there isn’t one nearby. Otherwise, if it is a new type, it will remove the 
//   old one and create the new one. If there is one of the same type nearby, it will intensify the current one to make it more important. In this way, each pheromone 
//   has an analog intensity which indicates the range at which it can be seen, as well as the alpha, font weight, etc. (how much it stands out to players).
//
//   Each time you click, a circle animates showing the new intensity (larger intensity shows a bigger circle). When creating pheromones, VAFX play slight gas sound and 
//   foggy bits pop out of the environment and coalesce, spinning, around the new sign post text.
//
//   When mousing over them, a “dismiss” button appears so the commander and manually delete them if no longer relevant. They also dissipate over time. 
// 
//   Pheromones are public property and have no owner. Any commander can dismiss, modify or grow any other pheromone cloud.
//
//   Show very faint/basic pheromone indicator to marines also. They have an idea that they are nearby, but don’t know what (perhaps just play faint sound when created, no visual).
//
//   Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Pheromone' (Entity)

Pheromone.kMapName = "pheromone"
local kAppearDistance = 20
local kThreatLifetime = 15
local kExpandingLifetime = 40
local kHurtLifetime = 30
local kMaxPheromones = 5
local kExistingPheromoneRange = 8

local networkVars =
{
    // "Threat detected", "Reinforce", etc.
    type = "enum kTechId",
    
    // timestamp when to kill the pheromone
    untilTime = "time",    
    
    createTime = "time",
}

function Pheromone:OnCreate()

    Entity.OnCreate(self)
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
    self.type = kTechId.None
    self.lifetime = 0
    self.createTime = 0
    
    if Server then
        self:SetUpdates(true)
    end
    
end

function Pheromone:Initialize(techId)

    self.type = techId
    
    local lifetime = 20
    if techId == kTechId.ExpandingMarker then
        lifetime = kExpandingLifetime
    elseif techId == kTechId.ThreatMarker then
        lifetime = kThreatLifetime
    elseif techId == NeedHealingMarker then
        lifetime = kHurtLifetime
    end
    
    self.untilTime = Shared.GetTime() + lifetime
    self.createTime = Shared.GetTime()
    
end

function Pheromone:GetType()
    return self.type
end

function Pheromone:GetBlipType()
    return kBlipType.Pheromone
end

function Pheromone:GetDisplayName()
    return GetDisplayNameForTechId(self.type, "<no pheromone name>")
end

function Pheromone:GetAppearDistance()
    return kAppearDistance
end

function Pheromone:GetCreateTime()
    return self.createTime
end

function Pheromone:UpdateRelevancy()

    self:SetRelevancyDistance(self:GetAppearDistance())
    
    if self.teamNumber == 1 then
        self:SetIncludeRelevancyMask(kRelevantToTeam1)
    else
        self:SetIncludeRelevancyMask(kRelevantToTeam2)
    end
    
end

if Server then

    local function DeletePheromonesInRange(techId, position, teamNumber, ignorePheromone)
    
        local deleted = false
        
        local pheromones = GetEntitiesWithinRange("Pheromone", position, kExistingPheromoneRange)
        for p = 1, #pheromones do
        
            local pheromone = pheromones[p]
            if pheromone:GetId() ~= ignorePheromone:GetId() then
            
                DestroyEntity(pheromone)                
                deleted = true
                
            end
            
        end
        
        return deleted
        
    end
    
    function CreatePheromone(techId, position, teamNumber)
    
        // Create new pheromone (hover off ground a little).
        local newPheromone = CreateEntity(Pheromone.kMapName, position + Vector(0, 0.5, 0), teamNumber)
        newPheromone:Initialize(techId)
        
        // Look for existing nearby pheromone with same type nearby and delete it
        if not DeletePheromonesInRange(techId, position, teamNumber, newPheromone) then
        
            // Check if there are too many Pheromones in play already.
            local existingPheromones = Shared.GetEntitiesWithClassname("Pheromone")
            if existingPheromones:GetSize() > kMaxPheromones then
            
                // Find the oldest and kill it
                local oldest = nil
                for p = 1, existingPheromones:GetSize() do
                
                    local current = existingPheromones:GetEntityAtIndex(p - 1)
                    
                    if oldest == nil or (current.untilTime < oldest.untilTime) then
                        oldest = current
                    end
                end
                
                assert(oldest ~= nil)
                DestroyEntity(oldest)
                
            end

        end
            
        // return new one we created
        return newPheromone
        
    end
    
    function Pheromone:OnUpdate(timePassed)
    
        // Expire pheromones after a time
        if self.untilTime <= Shared.GetTime() then
            DestroyEntity(self)
        end
        
    end
    
end

Shared.LinkClassToMap("Pheromone", Pheromone.kMapName, networkVars)