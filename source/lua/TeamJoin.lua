// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TeamJoin.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Trigger.lua")

class 'TeamJoin' (Trigger)

TeamJoin.kMapName = "team_join"

local networkVars =
{
    teamNumber = string.format("integer (-1 to %d)", kSpectatorIndex),
    teamIsFull = "boolean",
    playerCount = "integer (0 to " .. kMaxPlayers - 1 .. ")"
}

function TeamJoin:OnCreate()

    Trigger.OnCreate(self)
    
    self.teamIsFull = false
    self.playerCount = 0
    
    if Server then
        self:SetUpdates(true)
    end
    
end

function TeamJoin:OnInitialized()

    Trigger.OnInitialized(self)
    
    // self:SetPropagate(Actor.Propagate_Never)
    self:SetPropagate(Entity.Propagate_Always)
    
    self:SetIsVisible(false)
    
    self:SetTriggerCollisionEnabled(true)
    
end

if Server then

    function TeamJoin:OnUpdate()
    
        local team1PlayerCount = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
        local team2PlayerCount = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
        if self.teamNumber == kTeam1Index then
        
            self.teamIsFull = team1PlayerCount > team2PlayerCount
            self.playerCount = team1PlayerCount
            
        elseif self.teamNumber == kTeam2Index then
        
            self.teamIsFull = team2PlayerCount > team1PlayerCount
            self.playerCount = team2PlayerCount
            
        end
        
    end
    
    function JoinRandomTeam(player)

        // Join team with less players or random.
        local team1Players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
        local team2Players = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
        
        // Join team with least.
        if team1Players < team2Players then
            Server.ClientCommand(player, "jointeamone")
        elseif team2Players < team1Players then
            Server.ClientCommand(player, "jointeamtwo")
        else
        
            // Join random otherwise.
            if math.random() < 0.5 then
                Server.ClientCommand(player, "jointeamone")
            else
                Server.ClientCommand(player, "jointeamtwo")
            end
            
        end
        
    end

    function TeamJoin:OnTriggerEntered(enterEnt, triggerEnt)

        if enterEnt:isa("Player") then
        
            if self.teamNumber == kTeamReadyRoom then
                Server.ClientCommand(enterEnt, "spectate")
            elseif self.teamNumber == kTeam1Index then
                Server.ClientCommand(enterEnt, "jointeamone")
            elseif self.teamNumber == kTeam2Index then
                Server.ClientCommand(enterEnt, "jointeamtwo")
            elseif self.teamNumber == kRandomTeamType then
                JoinRandomTeam(enterEnt)
            end
            
        end
            
    end

end

Shared.LinkClassToMap("TeamJoin", TeamJoin.kMapName, networkVars)