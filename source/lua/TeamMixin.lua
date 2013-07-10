// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TeamMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * TeamMixin has functionality for an Entity to be on a team.
 */
TeamMixin = CreateMixin( TeamMixin )
TeamMixin.type = "Team"

TeamMixin.networkVars =
{
    // Never set this directly, call SetTeamNumber()
    teamNumber = string.format("integer (-1 to %d)", kSpectatorIndex)
}

function TeamMixin:__initmixin()
    self.teamNumber = -1
end

if Client then

    function TeamMixin:OnGetIsVisible(visibleTable, viewerTeamNumber)
    
        local player = Client.GetLocalPlayer()
        
        if player and player:isa("Commander") and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) and HasMixin(self, "LOS") and not self:GetIsSighted() then
            visibleTable.Visible = false
        end
        
    end
    
end

local kTeamIndexToType = { }
kTeamIndexToType[kTeamInvalid] = kNeutralTeamType
kTeamIndexToType[kTeamReadyRoom] = kNeutralTeamType
kTeamIndexToType[kTeam1Index] = kTeam1Type
kTeamIndexToType[kTeam2Index] = kTeam2Type
kTeamIndexToType[kSpectatorIndex] = kNeutralTeamType

function TeamMixin:GetTeamType()
    return kTeamIndexToType[self.teamNumber]
end

function TeamMixin:GetTeamNumber()
    return self.teamNumber
end

function TeamMixin:SetTeamNumber(teamNumber)

    self.teamNumber = teamNumber
    
    if self.OnTeamChange then
        self:OnTeamChange()
    end
    
end

function TeamMixin:OnInitialized()

    local teamNumber = GetAndCheckValue(self.teamNumber, 0, 3, "teamNumber", 0, true)
    self:SetTeamNumber(teamNumber)
    
end

/**
 * The team object only exists on the Server.
 */
function TeamMixin:GetTeam()

    assert(Server)
    
    if not GetHasGameRules() then
        return nil
    end
    
    return GetGamerules():GetTeam(self:GetTeamNumber())
    
end

function TeamMixin:GetEffectParams(tableParams)

    if not tableParams[kEffectFilterIsMarine] then
        tableParams[kEffectFilterIsMarine] = (self:GetTeamType() == kMarineTeamType)
    end
    
    if not tableParams[kEffectFilterIsAlien] then
        tableParams[kEffectFilterIsAlien] = (self:GetTeamType() == kAlienTeamType)
    end
    
end

/**
 * This function is called from OwnerMixin when ownership of this
 * object changes.
 */
function TeamMixin:OnOwnerChanged(oldOwner, newOwner)

    if newOwner and HasMixin(newOwner, "Team") then
    
        // Only allow team members to own this object.
        if newOwner:GetTeamNumber() ~= self:GetTeamNumber() then
            self:SetOwner(nil)
        end
        
    end
    
end

function TeamMixin:GetCanBeUsed(player, useSuccessTable)

    if GetAreEnemies(player, self) then
        useSuccessTable.useSuccess = false
    end

end