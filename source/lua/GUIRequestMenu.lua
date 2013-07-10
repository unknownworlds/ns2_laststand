// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIRequestMenu.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/VoiceOver.lua")
Script.Load("lua/BindingsDialog.lua")

class 'GUIRequestMenu' (GUIScript)

local kOpenSound = "sound/NS2.fev/common/checkbox_on"
Client.PrecacheLocalSound(kOpenSound)
local function OnShow_RequestMenu()
    StartSoundEffect(kOpenSound)
end

local kCloseSound = "sound/NS2.fev/common/checkbox_on"
Client.PrecacheLocalSound(kCloseSound)
local function OnHide_RequestMenu()
    // StartSoundEffect(kCloseSound)
end

local kClickSound = "sound/NS2.fev/common/button_enter"
Client.PrecacheLocalSound(kClickSound)
local function OnClick_RequestMenu()
    StartSoundEffect(kClickSound)
end

// make this part of UI bindings
local function GetIsRequestMenuKey(key)
    return key == InputKey.X
end

local gTimeLastMessageSend = 0
local function GetCanSendRequest(id)

    local player = Client.GetLocalPlayer()
    local isAlive = player ~= nil and (not HasMixin(player, "Live") or player:GetIsAlive())
    local allowWhileDead = id == kVoiceId.VoteConcede or id == kVoiceId.VoteEject
    
    return (isAlive or allowWhileDead) and gTimeLastMessageSend + 2 < Shared.GetTime()
    
end

local kBackgroundSize = GUIScale(Vector(190, 48, 0))
local kKeyBindXOffset = GUIScale(16)

local kPadding = GUIScale(0)

local kFontName = "fonts/AgencyFB_small.fnt"
local kFontScale = GUIScale(1)

local scaleVector = Vector(1, 1, 1) * kFontScale

local kMenuSize = GUIScale(Vector(256, 256, 0))

// moves button towards the center
local kButtonClipping = GUIScale(32)

local kButtonMaxXOffset = GUIScale(32)

local kMenuTexture =
{
    [kMarineTeamType] = "ui/marine_request_menu.dds",
    [kAlienTeamType] = "ui/alien_request_menu.dds",
    [kNeutralTeamType] = "ui/neutral_request_menu.dds",
}

local kBackgroundTexture = 
{
    [kMarineTeamType] = "ui/marine_request_button.dds",
    [kAlienTeamType] = "ui/alien_request_button.dds",
    [kNeutralTeamType] = "ui/neutral_request_button.dds",
}

local kBackgroundTextureHighlight = 
{
    [kMarineTeamType] = "ui/marine_request_button_highlighted.dds",
    [kAlienTeamType] = "ui/alien_request_button_highlighted.dds",
    [kNeutralTeamType] = "ui/neutral_request_button_highlighted.dds",
}

local function CreateEjectButton(self, teamType)

    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(kBackgroundTexture[teamType])
    background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    background:SetPosition(Vector(-kBackgroundSize.x * .5, -kBackgroundSize.y - kPadding, 0))
    
    local commanderName = GetGUIManager():CreateTextItem()
    commanderName:SetTextAlignmentX(GUIItem.Align_Center)
    commanderName:SetTextAlignmentY(GUIItem.Align_Center)
    commanderName:SetFontName(kFontName)
    commanderName:SetScale(scaleVector)
    commanderName:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    self.background:AddChild(background)
    background:AddChild(commanderName)
    
    return { Background = background, CommanderName = commanderName }

end

local function CreateConcedeButton(self, teamType)

    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(kBackgroundTexture[teamType])
    background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    background:SetPosition(Vector(-kBackgroundSize.x * .5, kPadding, 0))
    
    local concedeText = GetGUIManager():CreateTextItem()
    concedeText:SetTextAlignmentX(GUIItem.Align_Center)
    concedeText:SetTextAlignmentY(GUIItem.Align_Center)
    concedeText:SetFontName(kFontName)
    concedeText:SetScale(scaleVector)
    concedeText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    concedeText:SetText(Locale.ResolveString("VOTE_CONCEDE"))
    
    self.background:AddChild(background)
    background:AddChild(concedeText)
    
    return { Background = background, ConcedeText = concedeText }

end

local function CreateMenuButton(self, teamType, voiceId, align, index, numEntries)

    voiceId = voiceId or kVoiceId.None
    index = index + (kMaxRequestsPerSide - numEntries) *.5
    local keyBind = GetVoiceKeyBind(voiceId)
    
    align = align or GUIItem.Left

    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(kBackgroundTexture[teamType])
    background:SetAnchor(align, GUIItem.Top)
    background:SetLayer(kGUILayerPlayerHUDForeground1)
    
    local position = Vector(0,0,0)
    local shiftDirection = -1    
    if align == GUIItem.Left then        
        position.x =  -kBackgroundSize.x
        shiftDirection = 1
    end
    
    position.y = (index-1) * (kBackgroundSize.y + kPadding)
    local xOffset = math.cos(Clamp( (index-1) / (kMaxRequestsPerSide-1), 0, 1) * math.pi * 2) * kButtonMaxXOffset + kButtonClipping
    position.x = position.x + shiftDirection * xOffset
    
    background:SetPosition(position)

    local keyBindText = GetGUIManager():CreateTextItem()
    keyBindText:SetPosition(Vector(kKeyBindXOffset, 0, 0))
    keyBindText:SetAnchor(GUIItem.Left, GUIItem.Center)
    keyBindText:SetTextAlignmentY(GUIItem.Align_Center)
    keyBindText:SetFontName(kFontName)
    keyBindText:SetScale(scaleVector)
    keyBindText:SetColor(Color(1, 1, 0, 1))
    
    local description = GetGUIManager():CreateTextItem()
    description:SetAnchor(GUIItem.Middle, GUIItem.Center)
    description:SetTextAlignmentX(GUIItem.Align_Center)
    description:SetTextAlignmentY(GUIItem.Align_Center)
    description:SetFontName(kFontName)
    description:SetScale(scaleVector)
    description:SetText(GetVoiceDescriptionText(voiceId))

    self.background:AddChild(background)
    background:AddChild(description)
    background:AddChild(keyBindText)
    
    return { Background = background, Description = description, KeyBindText = keyBindText, KeyBind = keyBind, VoiceId = voiceId }

end

local function OnEjectCommanderClicked()

    if GetCanSendRequest(kVoiceId.VoteEject) then

        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(kVoiceId.VoteEject), true)        
        gTimeLastMessageSend = Shared.GetTime()
        return true
        
    end
    
    return false

end

local function OnConcedeButtonClicked()

    if GetCanSendRequest(kVoiceId.VoteConcede) then

        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(kVoiceId.VoteConcede), true)        
        gTimeLastMessageSend = Shared.GetTime()
        return true
        
    end
    
    return false

end

local function SendRequest(self, voiceId)

    if GetCanSendRequest(voiceId) then

        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(voiceId), true)
        gTimeLastMessageSend = Shared.GetTime()
        return true
        
    end
    
    return false

end

local function GetBindedVoiceId(playerClass, key)

    local requestMenuLeft = GetRequestMenu(LEFT_MENU, playerClass)
    for i = 1, #requestMenuLeft do
    
        local soundData = GetVoiceSoundData(requestMenuLeft[i])
        if soundData and soundData.KeyBind then
            
            if GetIsBinding(key, soundData.KeyBind) then
                return requestMenuLeft[i]
            end
            
        end
    
    end
    
    local requestMenuRight = GetRequestMenu(RIGHT_MENU, playerClass)
    for i = 1, #requestMenuRight do
    
        local soundData = GetVoiceSoundData(requestMenuRight[i])
        if soundData and soundData.KeyBind then
            
            if GetIsBinding(key, soundData.KeyBind) then
                return requestMenuRight[i]
            end
            
        end
    
    end

end

function GUIRequestMenu:Initialize()

    self.teamType = PlayerUI_GetTeamType()
    self.playerClass = PlayerUI_GetPlayerClassName()

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetSize(kMenuSize)
    self.background:SetPosition(-kMenuSize * .5)
    self.background:SetTexture(kMenuTexture[self.teamType])
    self.background:SetIsVisible(false)
    
    self.menuButtons = {}
    
    self.ejectCommButton = CreateEjectButton(self, self.teamType)
    self.voteConcedeButton = CreateConcedeButton(self, self.teamType)

    local leftMenu = GetRequestMenu(LEFT_MENU, self.playerClass)
    local numLeftEntries = #leftMenu
    local rightMenu = GetRequestMenu(RIGHT_MENU, self.playerClass)
    local numRightEntries = #rightMenu
    
    for i = 1, numLeftEntries do
    
        if i > kMaxRequestsPerSide then
            break
        end
        
        local voiceId = leftMenu[i]
        table.insert(self.menuButtons, CreateMenuButton(self, self.teamType, voiceId, GUIItem.Left, i, numLeftEntries))
    
    end
    
    for i = 1, numRightEntries do
    
        if i > kMaxRequestsPerSide then
            break
        end
        
        local voideId = rightMenu[i]
        table.insert(self.menuButtons, CreateMenuButton(self, self.teamType, voideId, GUIItem.Right, i, numRightEntries))
    
    end

end

function GUIRequestMenu:Uninitialize()

    self:SetIsVisible(false)

    if self.background then    
        GUI.DestroyItem(self.background)        
    end
    
    self.background = nil
    self.ejectCommButton = nil
    self.voteConcedeButton = nil
    self.menuButtons = {}

end

local function GetCanOpenRequestMenu(self)
    return PlayerUI_GetCanDisplayRequestMenu()
end

function GUIRequestMenu:SetIsVisible(isVisible)

    if self.background then
    
        local wasVisible = self.background:GetIsVisible()
        if wasVisible ~= isVisible then
        
            if isVisible and GetCanOpenRequestMenu(self) then
                OnShow_RequestMenu()
                MouseTracker_SetIsVisible(true)
                self.background:SetIsVisible(true)
            else
                OnHide_RequestMenu()
                MouseTracker_SetIsVisible(false)
                self.background:SetIsVisible(false)
            end    
        
        end

    end
    
end


function GUIRequestMenu:Update(deltaTime)

    if self.playerClass ~= PlayerUI_GetPlayerClassName() then

        self:Uninitialize()
        self:Initialize()
        
    end

    if self.background:GetIsVisible() then
    
        local commanderName = PlayerUI_GetCommanderName()
        self.ejectCommButton.Background:SetIsVisible(commanderName ~= nil)
        self.voteConcedeButton.Background:SetIsVisible(PlayerUI_GetGameStartTime() + kMinTimeBeforeConcede < Shared.GetTime())
        if commanderName then
            self.ejectCommButton.CommanderName:SetText(string.format("%s %s", Locale.ResolveString("EJECT"), string.upper(commanderName)))
        end
        
        local mouseX, mouseY = Client.GetCursorPosScreen()
        
        if GUIItemContainsPoint(self.ejectCommButton.Background, mouseX, mouseY) then
            self.ejectCommButton.Background:SetTexture(kBackgroundTextureHighlight[self.teamType])
        else
            self.ejectCommButton.Background:SetTexture(kBackgroundTexture[self.teamType])
        end
        
        if GUIItemContainsPoint(self.voteConcedeButton.Background, mouseX, mouseY) then
            self.voteConcedeButton.Background:SetTexture(kBackgroundTextureHighlight[self.teamType])
        else
            self.voteConcedeButton.Background:SetTexture(kBackgroundTexture[self.teamType])
        end
        
        for i = 1, #self.menuButtons do
        
            local button = self.menuButtons[i]

            local keyBindString = (button.KeyBind and BindingsUI_GetInputValue(button.KeyBind)) or ""
            if keyBindString ~= nil and keyBindString ~= "" then
                keyBindString = "[" .. string.sub(keyBindString, 1, 1) .. "]"
            end
            
            button.KeyBindText:SetText(keyBindString)
            
            if GUIItemContainsPoint(button.Background, mouseX, mouseY) then
                button.Background:SetTexture(kBackgroundTextureHighlight[self.teamType])
            else
                button.Background:SetTexture(kBackgroundTexture[self.teamType])
            end
        
        end
        
        if not PlayerUI_GetCanDisplayRequestMenu() then
            self:SetIsVisible(false)
        end
    
    end

end

function GUIRequestMenu:SendKeyEvent(key, down)

    // Spectators cannot use this menu.
    if not Client.GetIsControllingPlayer() then
        return false
    end
    
    local hitButton = false
    
    if ChatUI_EnteringChatMessage() then
    
        self:SetIsVisible(false)
        return false
        
    end
    
    if down then
    
        local bindedVoiceId = GetBindedVoiceId(self.playerClass, key)
        if bindedVoiceId then
            SendRequest(self, bindedVoiceId)
            self:SetIsVisible(false)
            return true
        end
    
    end
    
    local mouseX, mouseY = Client.GetCursorPosScreen()

    if self.background:GetIsVisible() then

        if key == InputKey.MouseButton0 or (not down and GetIsBinding(key, "RequestMenu")) then
        
            if self.ejectCommButton.Background:GetIsVisible() and GUIItemContainsPoint(self.ejectCommButton.Background, mouseX, mouseY) then            
                if OnEjectCommanderClicked() then
                    OnClick_RequestMenu()
                end
                hitButton = true
                
            elseif self.voteConcedeButton.Background:GetIsVisible() and GUIItemContainsPoint(self.voteConcedeButton.Background, mouseX, mouseY) then            
                if OnConcedeButtonClicked() then
                    OnClick_RequestMenu()
                end
                hitButton = true
                
            else
        
                for i = 1, #self.menuButtons do
                
                    local button = self.menuButtons[i]
                    if GUIItemContainsPoint(button.Background, mouseX, mouseY) then
                        if SendRequest(self, button.VoiceId) then
                            OnClick_RequestMenu()
                        end
                        hitButton = true
                        break
                    end
                
                end
                
            end
        
        end
        
        // make sure that the menu is not conflicting when the player wants to attack
        if (not hitButton and key == InputKey.MouseButton0) or key == InputKey.MouseButton1 then
            self:SetIsVisible(false)
            return false
        end
    
    end

    local success = false
    
    if GetIsBinding(key, "RequestMenu") then
    
        if self.requestMenuKeyDown ~= down then
            self:SetIsVisible(down)
        end    
        self.requestMenuKeyDown = down
        
        return true
    end
    
    // return true only when the player clicked on a button, so you wont start attacking accidentally
    if hitButton then
    
        if down then
        
            if not self.background:GetIsVisible() and PlayerUI_GetCanDisplayRequestMenu() then
                self:SetIsVisible(true)
            else
            
                self:SetIsVisible(false)
                PlayerUI_OnRequestSelected()
                
            end
            
        end
        
        success = true

    end
    
    return success

end
