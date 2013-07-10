// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\GUIAlienSpectatorHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays how much time is left until the alien spawns.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local timeWaveSpawnEnds = 0
local function OnSetTimeWaveSpawnEnds(message)
    timeWaveSpawnEnds = message.time
end
Client.HookNetworkMessage("SetTimeWaveSpawnEnds", OnSetTimeWaveSpawnEnds)

local function AlienUI_GetWaveSpawnTime()

    if timeWaveSpawnEnds > 0 then
        return timeWaveSpawnEnds - Shared.GetTime()
    end
    
    return 0
    
end

class 'GUIAlienSpectatorHUD' (GUIScript)

local kFontScale = GUIScale(Vector(1, 1, 0))
local kTextFontName = "fonts/AgencyFB_large.fnt"
local kFontColor = Color(1, 1, 1, 1)

local kEggSize = GUIScale(Vector(192, 96, 0) * 0.5)

local kPadding = GUIScale(32)
local kEggTopOffset = GUIScale(128)

local kNoEggsColor = Color(1, 0, 0, 1)
local kWhite = Color(1, 1, 1, 1)

local kEggTexture = "ui/Egg.dds"

local kSpawnInOffset = GUIScale(Vector(0, -125, 0))

function GUIAlienSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    self.spawnText:SetPosition(kSpawnInOffset)
    
    self.eggIcon = GUIManager:CreateGraphicItem()
    self.eggIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.eggIcon:SetPosition(Vector(-kEggSize.x * 0.75 - kPadding * 0.5, kEggTopOffset, 0))
    self.eggIcon:SetTexture(kEggTexture)
    self.eggIcon:SetSize(kEggSize)
    
    self.eggCount = GUIManager:CreateTextItem()
    self.eggCount:SetFontName(kTextFontName)
    self.eggCount:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.eggCount:SetPosition(Vector(kPadding * 0.5, 0, 0))
    self.eggCount:SetTextAlignmentX(GUIItem.Align_Min)
    self.eggCount:SetTextAlignmentY(GUIItem.Align_Center)
    self.eggCount:SetColor(kFontColor)
    self.eggCount:SetScale(kFontScale)
    self.eggCount:SetFontName(kTextFontName)
    
    self.eggIcon:AddChild(self.eggCount)
    
end

function GUIAlienSpectatorHUD:Uninitialize()

    assert(self.spawnText)
    
    GUI.DestroyItem(self.spawnText)
    self.spawnText = nil
    
    GUI.DestroyItem(self.eggIcon)
    self.eggIcon = nil
    eggCount = nil
    
end

function GUIAlienSpectatorHUD:Update(deltaTime)

    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()
    // Assume the UI should display when not controlling a player (spectating a player).
    local displayUI = not Client.GetIsControllingPlayer()
    
    // Do not display while not on the Alien team (on the spectator team).
    local clientTeam = Client.GetLocalClientTeamNumber()
    displayUI = displayUI and clientTeam == kTeam2Index
    
    local isVisible = not waitingForTeamBalance and displayUI
    self.spawnText:SetIsVisible(isVisible)
    self.eggIcon:SetIsVisible(isVisible)
    
    if isVisible then
    
        local timeToWave = math.max(0, math.floor(AlienUI_GetWaveSpawnTime()))
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
        local eggCount = AlienUI_GetEggCount()
        
        self.eggCount:SetText(string.format("x %s", ToString(eggCount)))
        
        local hasEggs = eggCount > 0
        self.eggCount:SetColor(hasEggs and kWhite or kNoEggsColor)
        self.eggIcon:SetColor(hasEggs and kWhite or kNoEggsColor)
        
    end
    
end