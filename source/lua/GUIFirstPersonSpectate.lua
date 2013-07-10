// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIFirstPersonSpectate.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIFirstPersonSpectate' (GUIScript)

local kSize = Vector(220, 60, 0)
local kFont = "fonts/AgencyFB_small.fnt"
local kBackgroundColor = Color(0, 0, 0, 0.5)
local kTextColor = Color(1, 1, 1, 1)

function GUIFirstPersonSpectate:Initialize()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetSize(kSize)
    self.background:SetPosition(Vector(-kSize.x/2,0,0))
    self.background:SetColor(kBackgroundColor)
    
    self.followingText = GUIManager:CreateTextItem()
    self.followingText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.followingText:SetFontName(kFont)
    self.followingText:SetTextAlignmentX(GUIItem.Align_Center)
    self.followingText:SetTextAlignmentY(GUIItem.Align_Min)
    self.followingText:SetColor(kTextColor)
    self.background:AddChild(self.followingText)
    
    self.killsText = GUIManager:CreateTextItem()
    self.killsText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.killsText:SetFontName(kFont)
    self.killsText:SetTextAlignmentX(GUIItem.Align_Min)
    self.killsText:SetTextAlignmentY(GUIItem.Align_Max)
    self.killsText:SetColor(kTextColor)
    self.background:AddChild(self.killsText)
    
    self.deathsText = GUIManager:CreateTextItem()
    self.deathsText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.deathsText:SetFontName(kFont)
    self.deathsText:SetTextAlignmentX(GUIItem.Align_Center)
    self.deathsText:SetTextAlignmentY(GUIItem.Align_Max)
    self.deathsText:SetColor(kTextColor)
    self.background:AddChild(self.deathsText)
    
    self.scoreText = GUIManager:CreateTextItem()
    self.scoreText:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.scoreText:SetFontName(kFont)
    self.scoreText:SetTextAlignmentX(GUIItem.Align_Max)
    self.scoreText:SetTextAlignmentY(GUIItem.Align_Max)
    self.scoreText:SetColor(kTextColor)
    self.background:AddChild(self.scoreText)
    
end

function GUIFirstPersonSpectate:Uninitialize()

    GUI.DestroyItem(self.background)
    
end

function GUIFirstPersonSpectate:SendKeyEvent(key, down)

    if down and GetIsBinding(key, "PrimaryAttack") then
        Client.SendNetworkMessage("SwitchFirstPersonSpectatePlayer", { forward = true }, true)
    elseif down and GetIsBinding(key, "SecondaryAttack") then
        Client.SendNetworkMessage("SwitchFirstPersonSpectatePlayer", { forward = false }, true)
    elseif down and GetIsBinding(key, "Jump") then
        Client.SendNetworkMessage("SwitchFromFirstPersonSpectate", { mode = kSpectatorMode.FreeLook }, true)
    elseif down and GetIsBinding(key, "Weapon1") then
        Client.SendNetworkMessage("SwitchFromFirstPersonSpectate", { mode = kSpectatorMode.FreeLook }, true)
    elseif down and GetIsBinding(key, "Weapon2") then
        Client.SendNetworkMessage("SwitchFromFirstPersonSpectate", { mode = kSpectatorMode.Overhead }, true)
    end
    
end

function GUIFirstPersonSpectate:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    if player then
    
        local playerRecord = Scoreboard_GetPlayerRecord(player:GetClientIndex())
        if playerRecord then
        
            local score = playerRecord.Score
            local kills = playerRecord.Kills
            local deaths = playerRecord.Deaths
            
            local followText = StringReformat(Locale.ResolveString("FOLLOWING_NAME"), { name = player:GetName() })
            self.followingText:SetText(followText)
            
            self.killsText:SetText(string.format("Kills: %d", kills))
            self.deathsText:SetText(string.format("Deaths: %d", deaths))
            self.scoreText:SetText(string.format("Score: %d", score))
            
        end
        
        self.background:SetIsVisible(playerRecord ~= nil)
        
    end
    
end