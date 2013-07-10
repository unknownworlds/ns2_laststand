// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Sponitor2.lua
//
//    Created by:   Steven An (steve@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSponitor2Url = "http://sponitor2.herokuapp.com/api/send/"

local gDebugAlwaysPost = false

local kPlayerCountCheckPeriod = 60.0    // Update player count stats every N seconds

local kPerfCheckPeriod = 1.0    // Every 1 second, we MIGHT report performance if the throttle-check passes

//----------------------------------------
//  Utility functions
//----------------------------------------

local function CollectActiveModIds()

    modIds = {}
    for modNum = 1, Server.GetNumActiveMods() do
        modIds[modNum] = Server.GetActiveModId(modNum)
    end
    return modIds

end

local function TechIdToString(techId)

    return LookupTechData( techId, kTechDataDisplayName, string.format("techId=%d", techId) )

end

local function TechIdToUpgradeCode(techId)

    return LookupTechData( techId, kTechDataSponitorCode, string.format("%d", techId) )

end

local function GetUpgradeAttribsString(ent)

    local out = ""

    if HasMixin( ent, "Upgradable" ) then

        local ups = ent:GetUpgradeList()

        for i = 1,#ups do
            out = out .. TechIdToUpgradeCode(ups[i])
        end
    end

    if ent:isa("Marine") then
        out = out .. string.format("W%dA%d", ent:GetWeaponLevel(), ent:GetArmorLevel() )
    end

    return out

end

//----------------------------------------
//   
//----------------------------------------
class 'ServerSponitor'

//----------------------------------------
//  'game' should be NS2Gamerules
//----------------------------------------
function ServerSponitor:Initialize( game )

    self.game = game

    self.matchId = nil
    self.reportDetails = false
    self.teamStats = {}
    self.sincePlayerCountCheck = 0.0
    self.serverPerfThrottle = 0.0005
    self.sincePerfCheck = 0.0

end

//----------------------------------------
//  
//----------------------------------------
local function ResetTeamStats(stats, team)
    stats.pvpKills = 0
    stats.team = team
    stats.minNumPlayers = team:GetNumPlayers()
    stats.maxNumPlayers = stats.minNumPlayers
    stats.avgNumPlayersSum = 0
    stats.avgNumRookiesSum = 0
    stats.numPlayerCountSamples = 0
    stats.currNumPlayers = 0

end

//----------------------------------------
//  
//----------------------------------------
function ServerSponitor:ListenToTeam(team)

    team:AddListener("OnResearchComplete",
            function(structure, researchId)

                local node = team:GetTechTree():GetTechNode(researchId)

                if node:GetIsResearch() or node:GetIsUpgrade() then
                    self:OnTechEvent("DONE "..TechIdToString(researchId))
                end

            end )

    team:AddListener("OnCommanderAction",
            function(techId)
                self:OnTechEvent("CMDR "..TechIdToString(techId))
            end )

    team:AddListener("OnConstructionComplete",
            function(structure)
                self:OnTechEvent("BUILT "..TechIdToString(structure:GetTechId()))
            end )

    team:AddListener("OnEvolved",
            function(techId)
                self:OnTechEvent("EVOL "..TechIdToString(techId))
            end )
    
    team:AddListener("OnBought",
            function(techId)
                self:OnTechEvent("BUY "..TechIdToString(techId))
            end )

    self.teamStats[team:GetTeamType()] = {}
    ResetTeamStats( self.teamStats[ team:GetTeamType() ], team )

end

//----------------------------------------
//   
//----------------------------------------
function ServerSponitor:OnMatchStartResponse(response)

    local data, pos, err = json.decode(response)
    
    if err then
        Shared.Message("Could not parse match start response. Error: " .. ToString(err) .. ". Response: " .. response)
    else
    
        if IsNumber(data.matchId) then
            self.matchId = data.matchId
        else
            self.matchId = nil
        end
        
        if IsBoolean(data.reportDetails) then
            self.reportDetails = data.reportDetails
        else
            self.reportDetails = false
        end

        if IsNumber(data.serverPerfThrottle) then
            self.serverPerfThrottle = data.serverPerfThrottle
            // We don't necessarily expect this, so don't reset to default if it was not provided
        end

    end

end

function ServerSponitor:OnServerPerfResponse(response)

    local data, pos, err = json.decode(response)
    
    if err then
        Shared.Message("Could not parse server perf response. Error: " .. ToString(err) .. ". Response: " .. response)
    else
    
        // We don't necessarily expect this, so don't reset to default if it was not provided.
        if IsNumber(data.serverPerfThrottle) then
            self.serverPerfThrottle = data.serverPerfThrottle
        end
        
    end
    
end

//----------------------------------------
//   
//----------------------------------------
function ServerSponitor:OnStartMatch()

    local jsonData = json.encode(
    {
        startTime      = Shared.GetGMTString(false),
        version        = Shared.GetBuildNumber(),
        map            = Shared.GetMapName(),
        serverIp       = IPAddressToString(Server.GetIpAddress()),
        isRookieServer = Server.GetIsRookieFriendly(),
        modIds         = CollectActiveModIds(),
    })
    
    Shared.SendHTTPRequest( kSponitor2Url.."matchStart", "POST", {data=jsonData},
        function(response) self:OnMatchStartResponse(response) end )

    // Reset check timers
    self.sincePlayerCountCheck = kPlayerCountCheckPeriod
    self.sincePerfCheck = kPerfCheckPeriod

end

//----------------------------------------
//  
//----------------------------------------
function ServerSponitor:OnJoinTeam( player, team )

    // We were gonna track unique steam IDs here, but could not figure out how to

end

//----------------------------------------
//   
//----------------------------------------
function ServerSponitor:OnEndMatch(winningTeam)

    if self.matchId or gDebugAlwaysPost then

        local startHiveTech = "None"

        if self.game.initialHiveTechId then
            startHiveTech = EnumToString(kTechId, self.game.initialHiveTechId)
        end

        local stats1 = self.teamStats[kMarineTeamType]
        local stats2 = self.teamStats[kAlienTeamType]

        local jsonData = json.encode(
        {
            matchId             = self.matchId,
            endTime             = Shared.GetGMTString(false),
            winner              = winningTeam:GetTeamType(),
            start_location1     = self.game.startingLocationNameTeam1,
            start_location2     = self.game.startingLocationNameTeam2,
            start_path_distance = self.game.startingLocationsPathDistance,
            start_hive_tech     = startHiveTech,

            pvpKills1           = stats1.pvpKills,
            pvpKills2           = stats2.pvpKills,
            minPlayers1         = stats1.minNumPlayers,
            minPlayers2         = stats2.minNumPlayers,
            maxPlayers1         = stats1.maxNumPlayers,
            maxPlayers2         = stats2.maxNumPlayers,
            avgPlayers1         = stats1.avgNumPlayersSum / stats1.numPlayerCountSamples,
            avgPlayers2         = stats2.avgNumPlayersSum / stats2.numPlayerCountSamples,
            avgRookies1         = stats1.avgNumRookiesSum / stats1.numPlayerCountSamples,
            avgRookies2         = stats2.avgNumRookiesSum / stats2.numPlayerCountSamples,
            totalTResMined1     = stats1.team:GetTotalTeamResourcesFromTowers(),
            totalTResMined2     = stats2.team:GetTotalTeamResourcesFromTowers(),
        })
        
        Shared.SendHTTPRequest( kSponitor2Url.."matchEnd", "POST", {data=jsonData} )

        self.matchId = nil

    end

    // Reset team stats here instead of OnStartMatch. This is because there is data we want to track
    // before the match actually starts, such as players joining the team.
    for teamType, stats in pairs(self.teamStats) do
        ResetTeamStats( stats, stats.team )
    end

end

//----------------------------------------
//   
//----------------------------------------
function ServerSponitor:OnEntityKilled(target, attacker, weapon)

    if not attacker or not target or not weapon then
        return
    end

    if (self.matchId and self.reportDetails) or gDebugAlwaysPost then

        local targetWeapon = "None"

        if target.GetActiveWeapon and target:GetActiveWeapon() then
            targetWeapon = target:GetActiveWeapon():GetClassName()
        end

        local attackerOrigin = attacker:GetOrigin()
        local targetOrigin = target:GetOrigin()
        local attackerTeamType = ((HasMixin(attacker, "Team") and attacker:GetTeamType()) or kNeutralTeamType)

        local jsonData, jsonError = json.encode(
        {
            matchId        = self.matchId,
            time           = Shared.GetGMTString(false),
            attackerClass  = attacker:GetClassName(),
            attackerTeam   = attackerTeamType,
            attackerWeapon = weapon:GetClassName(),
            attackerX      = string.format("%.2f", attackerOrigin.x),
            attackerY      = string.format("%.2f", attackerOrigin.y),
            attackerZ      = string.format("%.2f", attackerOrigin.z),
            attackerAttrs  = GetUpgradeAttribsString(attacker),
            targetClass    = target:GetClassName(),
            targetTeam     = target:GetTeamType(),
            targetWeapon   = targetWeapon,
            targetX        = string.format("%.2f", targetOrigin.x),
            targetY        = string.format("%.2f", targetOrigin.y),
            targetZ        = string.format("%.2f", targetOrigin.z),
            targetAttrs    = GetUpgradeAttribsString(target),
            targetLifeTime = string.format("%.2f", ((target.GetCreationTime and Shared.GetTime() - target:GetCreationTime()) or 0)),
        })

        if jsonData then

            Shared.SendHTTPRequest( kSponitor2Url.."kill", "POST", {data=jsonData} )

        else

            // the encoder returned nil, so there was an error. Post it to Spon2.
            jsonData = json.encode(
            {
                launchId = -1,
                time = Shared.GetGMTString(false),
                type = "server killpost",
                text = jsonError,
            })
            Shared.SendHTTPRequest( kSponitor2Url.."error", "POST", {data=jsonData} )

        end

        if attacker:isa("Player") and target:isa("Player") then
        
            local tstats = self.teamStats[attackerTeamType]

            if tstats then
                tstats.pvpKills = tstats.pvpKills + 1
            end

        end

    end

end

//----------------------------------------
//   
//----------------------------------------
function ServerSponitor:OnTechEvent(name)

    if (self.matchId and self.reportDetails) or gDebugAlwaysPost then

        local jsonData = json.encode(
        {
            matchId = self.matchId,
            time = Shared.GetGMTString(false),
            name = name,
        })

        Shared.SendHTTPRequest( kSponitor2Url.."tech", "POST", {data=jsonData} )

    end

end

//----------------------------------------
//  
//----------------------------------------
local function UpdatePerformanceReporting(self, dt)

    if self.matchId or gDebugAlwaysPost then
   
        self.sincePerfCheck = self.sincePerfCheck + dt

        if self.sincePerfCheck >= kPerfCheckPeriod then

            self.sincePerfCheck = 0.0

            if math.random() < self.serverPerfThrottle then

                local totalNumPlayers = 0

                for teamType, stats in pairs(self.teamStats) do
                    totalNumPlayers = totalNumPlayers + stats.currNumPlayers
                end

                local jsonData = json.encode(
                {
                    matchId = self.matchId,
                    time = Shared.GetGMTString(false),
                    tickRate = Server.GetFrameRate(),
                    numEntities = Shared.GetEntitiesWithClassname("Entity"):GetSize(),
                    numPlayers = totalNumPlayers
                })

                Shared.SendHTTPRequest( kSponitor2Url.."serverPerformance", "POST", {data=jsonData},
                    function(response) self:OnServerPerfResponse(response) end )

            end

        end

    end

end

//----------------------------------------
//  
//----------------------------------------
function ServerSponitor:Update(dt)

    if self.matchId or gDebugAlwaysPost then

        //----------------------------------------
        //  Update player count stats
        //----------------------------------------

        self.sincePlayerCountCheck = self.sincePlayerCountCheck + dt

        if self.sincePlayerCountCheck >= kPlayerCountCheckPeriod then

            self.sincePlayerCountCheck = 0.0

            for teamType, stats in pairs(self.teamStats) do
                local numPlayers, numRookies = stats.team:GetNumPlayers()   // only call this once - it does some computation
                stats.currNumPlayers = numPlayers
                stats.minNumPlayers = math.min( stats.minNumPlayers, numPlayers )
                stats.maxNumPlayers = math.max( stats.maxNumPlayers, numPlayers )
                stats.avgNumPlayersSum = stats.avgNumPlayersSum + numPlayers
                stats.avgNumRookiesSum = stats.avgNumRookiesSum + numRookies
                stats.numPlayerCountSamples = stats.numPlayerCountSamples + 1
            end
        end

        UpdatePerformanceReporting(self, dt)

    end

end


