// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIChat.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages chat messages that players send to each other.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIChat' (GUIScript)

local kOffset = Vector(100, -430, 0)
local kInputModeOffset = Vector(-5, 0, 0)
local kInputOffset = Vector(0, -10, 0)
local kBackgroundColor = Color(0.4, 0.4, 0.4, 0.0)
// This is the buffer x space between a player name and their chat message.
local kChatTextBuffer = 5
local kTimeStartFade = 6
local kTimeEndFade = 7

local kFontName = { marine = "fonts/AgencyFB_small.fnt", alien = "fonts/AgencyFB_small.fnt" }

function GUIChat:Initialize()

    self.messages = { }
    self.reuseMessages = { }
    
    // Input mode (Team/All) indicator text.
    self.inputModeItem = GUIManager:CreateTextItem()
    self.inputModeItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.inputModeItem:SetTextAlignmentX(GUIItem.Align_Max)
    self.inputModeItem:SetTextAlignmentY(GUIItem.Align_Center)
    self.inputModeItem:SetIsVisible(false)
    self.inputModeItem:SetLayer(kGUILayerChat)
    
    // Input text item.
    self.inputItem = GUIManager:CreateTextItem()
    self.inputItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.inputItem:SetPosition((kOffset * GUIScale(1)) + (kInputOffset * GUIScale(1)))
    self.inputItem:SetTextAlignmentX(GUIItem.Align_Min)
    self.inputItem:SetTextAlignmentY(GUIItem.Align_Center)
    self.inputItem:SetIsVisible(false)
    self.inputItem:SetLayer(kGUILayerChat)
    
end

function GUIChat:Uninitialize()

    GUI.DestroyItem(self.inputModeItem)
    self.inputModeItem = nil
    
    GUI.DestroyItem(self.inputItem)
    self.inputItem = nil
    
    for index, message in ipairs(self.messages) do
        GUI.DestroyItem(message["Background"])
    end
    self.messages = nil
    
    for index, message in ipairs(self.reuseMessages) do
        GUI.DestroyItem(message["Background"])
    end
    self.reuseMessages = nil
    
end

local function GetStyle()
    return PlayerUI_IsOnMarineTeam() and "marine" or "alien"
end

function GUIChat:Update(deltaTime)

    local style = GetStyle()
    
    local addChatMessages = ChatUI_GetMessages()
    local numberElementsPerMessage = 8
    local numberMessages = table.count(addChatMessages) / numberElementsPerMessage
    local currentIndex = 1
    
    while numberMessages > 0 do
    
        local playerColor = addChatMessages[currentIndex]
        local playerName = addChatMessages[currentIndex + 1]
        local messageColor = addChatMessages[currentIndex + 2]
        local messageText = addChatMessages[currentIndex + 3]
        self:AddMessage(playerColor, playerName, messageColor, messageText)
        currentIndex = currentIndex + numberElementsPerMessage
        numberMessages = numberMessages - 1
        
    end
    
    local removeMessages = { }
    local totalMessageHeight = 0
    // Update existing messages.
    for i, message in ipairs(self.messages) do
    
        local messageHeight = message["Message"]:GetTextHeight(message["Message"]:GetText())
        local currentPosition = Vector(message["Background"]:GetPosition())
        currentPosition.y = GUIScale(kOffset.y) + totalMessageHeight
        totalMessageHeight = totalMessageHeight + messageHeight
        
        message["Background"]:SetPosition(currentPosition)
        message["Time"] = message["Time"] + deltaTime
        
        if message["Time"] >= kTimeStartFade then
        
            local timePassed = kTimeEndFade - message["Time"]
            local timeToFade = kTimeEndFade - kTimeStartFade
            local fadeAmount = timePassed / timeToFade
            local currentColor = message["Player"]:GetColor()
            currentColor.a = fadeAmount
            message["Player"]:SetColor(currentColor)
            currentColor = message["Message"]:GetColor()
            currentColor.a = fadeAmount
            message["Message"]:SetColor(currentColor)
            
            if message["Time"] >= kTimeEndFade then
                table.insert(removeMessages, message)
            end
            
        end
        
    end
    
    // Remove faded out messages.
    for i, removeMessage in ipairs(removeMessages) do
    
        removeMessage["Background"]:SetIsVisible(false)
        table.insert(self.reuseMessages, removeMessage)
        table.removevalue(self.messages, removeMessage)
        
    end
    
    // Handle showing/hiding the input item.
    if ChatUI_EnteringChatMessage() then
    
        if not self.inputItem:GetIsVisible() then
        
            self.inputModeItem:SetFontName(kFontName[style])
            self.inputItem:SetFontName(kFontName[style])
            
            local textWidth = self.inputModeItem:GetTextWidth(ChatUI_GetChatMessageType())
            self.inputModeItem:SetText(ChatUI_GetChatMessageType())
            self.inputModeItem:SetPosition((kOffset * GUIScale(1)) + (kInputOffset * GUIScale(1)) + (kInputModeOffset * GUIScale(1)))
            self.inputModeItem:SetIsVisible(true)
            self.inputItem:SetIsVisible(true)
            
        end
        
    else
    
        if self.inputItem:GetIsVisible() then
        
            self.inputModeItem:SetIsVisible(false)
            self.inputItem:SetIsVisible(false)
            
        end
        
    end
    
end

function GUIChat:SendKeyEvent(key, down)

    if ChatUI_EnteringChatMessage() and down then
    
        if key == InputKey.Return then
        
            ChatUI_SubmitChatMessageBody(self.inputItem:GetText())
            self.inputItem:SetText("")
            
        elseif key == InputKey.Back then
        
            // Only remove text if there is more to remove.
            local currentText = self.inputItem:GetWideText()
            local currentTextLength = currentText:length()
            
            if currentTextLength > 0 then
            
                currentText = currentText:sub(1, currentTextLength - 1)
                self.inputItem:SetWideText(currentText)
                
            end
            
        elseif key == InputKey.Escape then
        
            ChatUI_SubmitChatMessageBody("")
            self.inputItem:SetText("")
            
        end
        
        return true
        
    end
    
    return false
    
end

function GUIChat:SendCharacterEvent(character)

    local enteringChatMessage = ChatUI_EnteringChatMessage()
    
    if Shared.GetTime() ~= ChatUI_GetStartedChatTime() and enteringChatMessage then
    
        local currentText = self.inputItem:GetWideText()
        if currentText:length() < kMaxChatLength then
        
            self.inputItem:SetWideText(currentText .. character)
            return true
            
        end
        
    end
    
    return false
    
end

function GUIChat:AddMessage(playerColor, playerName, messageColor, messageText)

    local style = GetStyle()
    
    local insertMessage = { Background = nil, Player = nil, Message = nil, Time = 0 }
    
    // Check if we can reuse an existing message.
    if table.count(self.reuseMessages) > 0 then
    
        insertMessage = self.reuseMessages[1]
        insertMessage["Time"] = 0
        insertMessage["Background"]:SetIsVisible(true)
        table.remove(self.reuseMessages, 1)
        
    end
    
    if insertMessage["Player"] == nil then
        insertMessage["Player"] = GUIManager:CreateTextItem()
    end
    
    insertMessage["Player"]:SetFontName(kFontName[style])
    insertMessage["Player"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Player"]:SetTextAlignmentX(GUIItem.Align_Min)
    insertMessage["Player"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Player"]:SetColor(ColorIntToColor(playerColor))
    insertMessage["Player"]:SetText(playerName)
    
    if insertMessage["Message"] == nil then
        insertMessage["Message"] = GUIManager:CreateTextItem()
    end
    
    insertMessage["Message"]:SetFontName(kFontName[style])
    insertMessage["Message"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Message"]:SetTextAlignmentX(GUIItem.Align_Max)
    insertMessage["Message"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Message"]:SetColor(messageColor)
    insertMessage["Message"]:SetText(messageText)
    
    local playerTextWidth = insertMessage["Player"]:GetTextWidth(playerName)
    local messageTextWidth = insertMessage["Message"]:GetTextWidth(messageText)
    local textWidth = playerTextWidth + messageTextWidth
    
    if insertMessage["Background"] == nil then
    
        insertMessage["Background"] = GUIManager:CreateGraphicItem()
        insertMessage["Background"]:SetLayer(kGUILayerChat)
        insertMessage["Background"]:AddChild(insertMessage["Player"])
        insertMessage["Background"]:AddChild(insertMessage["Message"])
        
    end
    
    insertMessage["Background"]:SetSize(Vector(textWidth + kChatTextBuffer, insertMessage["Message"]:GetTextHeight(messageText), 0))
    insertMessage["Background"]:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    insertMessage["Background"]:SetPosition(kOffset * GUIScale(1))
    insertMessage["Background"]:SetColor(kBackgroundColor)
    
    table.insert(self.messages, insertMessage)
    
end