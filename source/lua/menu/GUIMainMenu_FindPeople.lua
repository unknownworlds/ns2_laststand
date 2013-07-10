// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu_Mods.lua
//
//    Created by:   Marc Delorme (marc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/LogView.lua")
local kState = enum({"LookForGroup", "WaitingPlayer", "Starting"})

local UpdateText = function(self)

    local text

    if self.state == kState.LookForGroup then
        text = "Looking for a group"
    elseif self.state == kState.WaitingPlayer then

        text = "" .. self.group.region .. ", " .. self.group.playerCount .. " players\n"
        
    elseif self.state == kState.Starting then
        text = "Game will start in " .. self.remainingTime
    end

    self.logText:SetText(text)

end

local RefreshGroup = function(self)

    UpdateText(self)

    if self.group.hasStarted then

        self.state = kState.Starting
        self.startTime = Client.GetTime()

    end

end

local OnUpdateGroup = function(self, response)

    local obj, pos, err = json.decode(response, 1, nil)

    if err or obj.status == "ERROR" then
        Shared.Message(response)
        return
    end

    self.group = obj.group

    RefreshGroup(self)

    if obj.messages and #obj.messages > 0 then

        for i, m in ipairs(obj.messages) do
            if m.isNotification then
                self.logView:AddText(m.message)
            else
                self.logView:AddText("" .. m.author .. ": " .. m.message, "chat")
            end
        end

    end

    self.count = 0

end

local UpdateGroup = function(self)

    local params = {
        steamID = "" .. Client.GetSteamId()
    }

    Shared.SendHTTPRequest(kCatalyzURL .. "/update", "GET", params, function(response)
        OnUpdateGroup(self, response)
    end)

    self.count = 0

end

local SendMessage = function(self, message)

    local params = {
        steamID = "" .. Client.GetSteamId(),
        message = message
    }

    Shared.SendHTTPRequest(kCatalyzURL .. "/update", "GET", params, function(response)
        OnUpdateGroup(self, response)
    end)

    self.count = 0

    Print(params.message)

end

local OnRegister = function(self, response)

    local obj, pos, err = json.decode(response, 1, nil)

    if err or obj.status == "ERROR" then
        self.tryRegister = false
        Shared.Message(response)
        return
    end

    self.group = obj.group
    self.state = kState.WaitingPlayer

    RefreshGroup(self)

end

local findBestServer = function()

    local bestServerAddress = "localhost:27015"
    local bestServerNumPlayers = -1
    local bestServerMaxPlayers = -1
    local bestServerPing = -1

    for s = 0, Client.GetNumServers() - 1 do
        
        if not Client.GetServerRequiresPassword(s) and not Client.GetServerIsLAN(s) and Client.GetServerNumPlayers(s) == 0 and Client.GetServerMaxPlayers(s) >= 12 then
        
            local address = Client.GetServerAddress(s)
            local ping = Client.GetServerPing(s)

            if bestServerPing < 0 or ping < bestServerPing then

                bestServerPing = ping
                bestServerAddress = address

            end
                        
        end
        
    end

    return bestServerAddress

end

function GUIMainMenu:CreateFindPeopleWindow()

    self.findPeopleWindow = CreateMenuElement(self.playWindow:GetContentBox(), "Image")
    self.findPeopleWindow:SetCSSClass("play_now_content")

    local text = CreateMenuElement(self.findPeopleWindow, "Font", false)
    text:SetText("Looking for a group")
    text:SetCSSClass("findpeople_font")
    self.findPeopleWindow.logText = text

    local logView = CreateMenuElement(self.findPeopleWindow, "LogView")
    logView:SetTopOffset(text:GetHeight())
    self.findPeopleWindow.logView = logView

    self.findPeopleWindow.count = 0
    self.findPeopleWindow.nextUpdate = 5

    self.findPeopleWindow.tryRegister = false
    self.findPeopleWindow.state = kState.LookForGroup

    Event.Hook("Console_catalyz_chat", function(message) 
        SendMessage(self.findPeopleWindow, message)
    end)

end

function GUIMainMenu:UpdateFindPeople(deltatime)

    PROFILE("GUIMainMenu:UpdateFindPeople")

    local window  = self.findPeopleWindow

    if window and window:GetIsVisible() then

        if window.state == kState.WaitingPlayer then

            self.findPeopleWindow.count = self.findPeopleWindow.count + deltatime
            if window.count > window.nextUpdate then
                UpdateGroup(window)
            end

        elseif window.state == kState.Starting then

            window.remainingTime = 10 - math.floor(Client.GetTime() - window.startTime)
            UpdateText(window)

            if window.remainingTime < 0 then
                MainMenu_SBJoinServer(window.group.server)
            end

        end

        if window.tryRegister == false then

            local params = {
                steamID = "" .. Client.GetSteamId(),
                nickname = Client.GetUserName(),
                build = Shared.GetBuildNumber(),
                region = Client.GetCountryCode(),
                server = findBestServer()
            }
            Shared.SendHTTPRequest(kCatalyzURL .. "/register", "GET", params, function(response)
                OnRegister(window, response)
            end)
            window.tryRegister = true

        end

    elseif window and window.tryRegister == true then
        local params = {
            steamID = "" .. Client.GetSteamId()
        }
        Shared.SendHTTPRequest(kCatalyzURL .. "/deregister", "GET", params, function(response)
            window.tryRegister = false
            window.group = nil
            window.state = kState.LookForGroup
            UpdateText(window)
        end)
    end

end
