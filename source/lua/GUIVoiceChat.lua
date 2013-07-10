// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIVoiceChat.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying names of players using voice chat.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIVoiceChat' (GUIScript)

local kBackgroundSize = Vector(GUIScale(250), GUIScale(28), 0)
local kBackgroundOffset = Vector(-kBackgroundSize.x , GUIScale(0), 0)
local kBackgroundYSpace = GUIScale(4)
local kBackgroundAlpha = 0.8

local kVoiceChatIconSize = kBackgroundSize.y
local kVoiceChatIconOffset = Vector(-kBackgroundSize.y * 2, -kVoiceChatIconSize / 2, 0)

local kNameFontSize = GUIScale(22)
local kNameOffsetFromChatIcon = -kBackgroundSize.y - GUIScale(6)

local kBackgroundTexture = "ui/%s_HUD_presbg.dds"

GUIVoiceChat.kCommanderFontColor = Color(1, 1, 0, 1)
GUIVoiceChat.kMarineFontColor = Color(147/255, 206/255, 1, 1)
GUIVoiceChat.kAlienFontColor = Color(207/255, 139/255, 41/255, 1)


function GUIVoiceChat:Initialize()
    self.chatBars = { }
end

local function DestroyChatBar(destroyBar)

    GUI.DestroyItem(destroyBar.Name)
    destroyBar.Name = nil
    
    GUI.DestroyItem(destroyBar.Icon)
    destroyBar.Icon = nil
    
    GUI.DestroyItem(destroyBar.Background)
    destroyBar.Background = nil

end

function GUIVoiceChat:Uninitialize()

    for i, bar in ipairs(self.chatBars) do
        DestroyChatBar(bar)
    end
    self.chatBars = { }
    
end

local function ClearAllBars(self)

    for i, bar in ipairs(self.chatBars) do
        bar.Background:SetIsVisible(false)
    end

end

local function CreateChatBar()

    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetAnchor(GUIItem.Right, GUIItem.Center)
    background:SetPosition(kBackgroundOffset)
    background:SetIsVisible(false)
    
    local chatIcon = GUIManager:CreateGraphicItem()
    chatIcon:SetSize(Vector(kVoiceChatIconSize, kVoiceChatIconSize, 0))
    chatIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    chatIcon:SetPosition(kVoiceChatIconOffset)
    chatIcon:SetTexture("ui/speaker.dds")
    background:AddChild(chatIcon)
    
    local nameText = GUIManager:CreateTextItem()
    nameText:SetFontSize(kNameFontSize)
    nameText:SetFontName("fonts/AgencyFB_small.fnt")
    nameText:SetAnchor(GUIItem.Right, GUIItem.Center)
    nameText:SetTextAlignmentX(GUIItem.Align_Max)
    nameText:SetTextAlignmentY(GUIItem.Align_Center)
    nameText:SetPosition(Vector(kNameOffsetFromChatIcon, 0, 0))
    chatIcon:AddChild(nameText)
    
    return { Background = background, Icon = chatIcon, Name = nameText }
    
end

local function GetFreeBar(self)

    for i, bar in ipairs(self.chatBars) do
    
        if not bar.Background:GetIsVisible() then
            return bar
        end
        
    end
    
    local newBar = CreateChatBar()
    table.insert(self.chatBars, newBar)
    
    return newBar

end

function GUIVoiceChat:Update(deltaTime)

    PROFILE("GUIVoiceChat:Update")

    ClearAllBars(self)
    
    local allPlayers = ScoreboardUI_GetAllScores()
    // How many items per player.
    local numPlayers = table.count(allPlayers)
    local currentBar = 0
    
    for i = 1, numPlayers do
    
        local playerName = allPlayers[i].Name
        local clientIndex = allPlayers[i].ClientIndex
        local clientTeam = allPlayers[i].EntityTeamNumber
        
        if clientIndex and ChatUI_GetIsClientSpeaking(clientIndex) then
        
            local chatBar = GetFreeBar(self)
            
            chatBar.Background:SetIsVisible(true)
            
            local textureSet = "marine"
            local fontColor = GUIVoiceChat.kMarineFontColor
            if PlayerUI_IsOnAlienTeam() then
                textureSet = "alien"
                fontColor = GUIVoiceChat.kAlienFontColor
            end    

            chatBar.Background:SetTexture(string.format(kBackgroundTexture, textureSet))
            
            chatBar.Name:SetText(playerName)
            chatBar.Name:SetColor( ConditionalValue(allPlayers[i].IsCommander, GUIVoiceChat.kCommanderFontColor, ConditionalValue(allPlayers[i].IsRookie, kNewPlayerColorFloat, fontColor) ) )
            chatBar.Icon:SetColor( ConditionalValue(allPlayers[i].IsCommander, GUIVoiceChat.kCommanderFontColor, fontColor ) )
            
            local currentBarPosition = Vector(0, (kBackgroundSize.y + kBackgroundYSpace) * currentBar, 0)
            chatBar.Background:SetPosition(kBackgroundOffset + currentBarPosition)
            
            currentBar = currentBar + 1
            
        end

    end

end

function GUIVoiceChat:SendKeyEvent(key, down, amount)

    if GetIsBinding(key, "VoiceChat") then
    
        if down and not ChatUI_EnteringChatMessage() then
            Client.VoiceRecordStart()
        else
            Client.VoiceRecordStop()
        end
        
    end
    
end