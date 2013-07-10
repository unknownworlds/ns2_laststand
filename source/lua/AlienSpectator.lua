// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienSpectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Alien spectators can choose their upgrades and lifeform while dead.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamSpectator.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/LSAlienDeck.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'AlienSpectator' (TeamSpectator)

AlienSpectator.kMapName = "alienspectator"

local networkVars =
{
    alien1 = "integer",
    alien2 = "integer",
    alien3 = "integer"        
}

local function TechIdToString(techId)

    return LookupTechData( techId, kTechDataDisplayName, string.format("techId=%d", techId) )

end

function AlienSpectator:OnCreate()

    TeamSpectator.OnCreate(self)
    
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    if Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
        
end

function AlienSpectator:OnInitialized()

    self:SetIsRespawning(true)
    
    TeamSpectator.OnInitialized(self)

    self:SetTeamNumber(2)
    self.choice = nil
        
    if Server then
    
        aliens = self:GetTeam():RollAliens()
        self.alien1 = aliens[1]
        self.alien2 = aliens[2]
        self.alien3 = aliens[3]
        
    end
    
    self.spawnMenu = nil
    if Client then
        MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true) 
    end    
end

function AlienSpectator:OnDestroy()
    if Client then
        Print("Destroying spawn menu!")
        if self.spawnMenu ~= nil then
            self.spawnMenu:OnClose()        
            GetGUIManager():DestroyGUIScript(self.spawnMenu)
            self.spawnMenu = nil
        end    
        
        MouseTracker_SetIsVisible(false)        
    end
end

function AlienSpectator:OnProcessMove(input)

    TeamSpectator.OnProcessMove(self, input)
    
    if Client then
        if self.spawnMenu == nil and gGameRules.gameState == kGameState.Started then
            self.spawnMenu = GetGUIManager():CreateGUIScript("LSGUIAlienSpawnMenu")
            self.spawnMenu:SetAliens({self.alien1, self.alien2, self.alien3})
        end
    end
    
    if Server then
        if self.choice ~= nil then
            self:SpawnPlayer(self.choice)
            self.choice = nil
        end
        
        if not self.waitingToSpawnMessageSent then
        
            SendPlayersMessage({ self }, kTeamMessageTypes.SpawningWait)
            self.waitingToSpawnMessageSent = true
            
        end
        
    end
    
end

function AlienSpectator:OnSpawnAlien(choice)
    self.choice = choice
end

function AlienSpectator:SpawnPlayer(choice)
    
    local aliens = {self.alien1, self.alien2, self.alien3}
    local alien = kAlienDeck[aliens[choice]]

    local team = self:GetTeam()
    local spawnOrigin = GetGroundAtPosition(team:GetSpawnPosition(), nil, PhysicsMask.AllButPCs)
    local spawnAngles = team:GetSpawnAngles()
    
    local spawnClass = LookupTechData(alien.class, kTechDataMapName)
    local success, player = team:ReplaceRespawnPlayer(self, spawnOrigin, spawnAngles, spawnClass)
    
    for i =  1, #alien.abilities do
        Print('Granting ability %s', TechIdToString(alien.abilities[i]))
        player:GiveUpgrade(alien.abilities[i])
    end
    player:InitWeapons()
    player:UpdateArmorAmount()
    
    player:SetCameraDistance(0)
    // It is important that the player was spawned at 6the spot we specified.
    assert(player:GetOrigin() == spawnOrigin)    

end

// Same as Skulk so his view height is right when spawning in
function AlienSpectator:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

/**
 * Prevent the camera from penetrating into the world when waiting to spawn at an Egg.
 */
function AlienSpectator:GetPreventCameraPenetration()

    local followTarget = Shared.GetEntity(self:GetFollowTargetId())
    return followTarget and followTarget:isa("Egg")
    
end

function AlienSpectator:GetTargetsToFollow(includeCommandStructure)
    return {}
end


Shared.LinkClassToMap("AlienSpectator", AlienSpectator.kMapName, networkVars)