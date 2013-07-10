// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechPoint_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function TechPoint:GetCanTakeDamageOverride()
    return false
end

function TechPoint:GetCanDieOverride()
    return false
end

function TechPoint:OnAttached(entity)
    self.occupiedTeam = entity:GetTeamNumber()
end

function TechPoint:OnDetached()
    self.showObjective = false
    self.occupiedTeam = 0
end

function TechPoint:Reset()
    
    self:OnInitialized()
    
    self:ClearAttached()
    
end

function TechPoint:SetAttached(structure)

    if structure and structure:isa("CommandStation") then
        self.smashed = false
        self.smashScouted = false
    end
    ScriptActor.SetAttached(self, structure)
    
end 

// Spawn command station or hive on tech point
function TechPoint:SpawnCommandStructure(teamNumber)

    local alienTeam = (GetGamerules():GetTeam(teamNumber):GetTeamType() == kAlienTeamType)
    local techId = ConditionalValue(alienTeam, kTechId.Hive, kTechId.CommandStation)
    
    return CreateEntityForTeam(techId, Vector(self:GetOrigin()), teamNumber)
    
end

function TechPoint:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if self.smashed and not self.smashScouted then
        local attached = self:GetAttached()
        if attached and attached:GetIsSighted() then
            self.smashScouted = true
        end
    end    
    
end    
