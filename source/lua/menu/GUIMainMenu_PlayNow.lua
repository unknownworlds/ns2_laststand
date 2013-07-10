// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu_PlayNow.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local function UpdateAutoJoin(playNowWindow)

    playNowWindow.lastTimeRefreshedServers = playNowWindow.lastTimeRefreshedServers or 0
    local timeSinceRefreshed = Shared.GetTime() - playNowWindow.lastTimeRefreshedServers
    local timeToCheckForServerUpdate = timeSinceRefreshed > 5
    local forceRefreshTime = timeSinceRefreshed > 60
    if timeToCheckForServerUpdate and Client.GetNumServers() == 0 or forceRefreshTime then
    
        playNowWindow.lastTimeRefreshedServers = Shared.GetTime()
        Client.RebuildServerList()
        
    end
    
    timeSinceRefreshed = Shared.GetTime() - playNowWindow.lastTimeRefreshedServers
    if timeSinceRefreshed > 6 and Client.GetNumServers() > 0 then
    
        local allValidServers = { }
        // Still indexes at 0.
        for s = 0, Client.GetNumServers() - 1 do
        
            if not Client.GetServerRequiresPassword(s) then
            
                local numPlayers = Client.GetServerNumPlayers(s)
                local maxPlayers = Client.GetServerMaxPlayers(s)
                local percentFull = numPlayers / maxPlayers
                local name = Client.GetServerName(s)
                local address = Client.GetServerAddress(s)
                local mapname = Client.GetServerMapName(s)
                local ping = Client.GetServerPing(s)
                local rookieFriendly = Client.GetServerHasTag(s, "rookieFriendly")
                local isLANServer = Client.GetServerIsLAN(s)
                
                table.insert(allValidServers, { numPlayers = numPlayers, maxPlayers = maxPlayers, percentFull = percentFull, {name = name, rookieFriendly = rookieFriendly}, address = address, mapname = mapname, ping = ping, rookieFriendly = rookieFriendly, isLANServer = isLANServer })
                
            end
            
        end
        
        local bestServer = nil
        for vs = 1, #allValidServers do
        
            local possibleServer = allValidServers[vs]
            
            // Favor servers with low ping. But ignore ping when it is small enough.
            // Ignore LAN servers for this process.
            if not possibleServer.isLANServer and (not bestServer or (possibleServer.ping < bestServer.ping or possibleServer.ping <= 80)) then
            
                bestServer = bestServer or possibleServer
                // Favor servers that are at least half full.
                if possibleServer.percentFull >= 0.5 then
                
                    // Favor servers that are not too full when they are at least half full.
                    if possibleServer.percentFull < bestServer.percentFull then
                        bestServer = possibleServer
                    end
                    
                // Favor servers that are more populated than our current best choice if
                // both are below 50% populated.
                elseif bestServer.percentFull < 0.5 and possibleServer.percentFull > bestServer.percentFull then
                    bestServer = possibleServer
                end
                
            end
            
        end
        
        if bestServer then
            MainMenu_SBJoinServer(bestServer.address, nil, bestServer.mapname)
        end
        
    end
    
end

local function UpdatePlayNowWindowLogic(playNowWindow, mainMenu)

    PROFILE("GUIMainMenu:UpdatePlayNowWindowLogic")

    if playNowWindow:GetIsVisible() then
    
        playNowWindow.searchingForGameText.animateTime = playNowWindow.searchingForGameText.animateTime or Shared.GetTime()
        if Shared.GetTime() - playNowWindow.searchingForGameText.animateTime > 0.85 then
        
            playNowWindow.searchingForGameText.animateTime = Shared.GetTime()
            playNowWindow.searchingForGameText.numberOfDots = playNowWindow.searchingForGameText.numberOfDots or 3
            playNowWindow.searchingForGameText.numberOfDots = playNowWindow.searchingForGameText.numberOfDots + 1
            if playNowWindow.searchingForGameText.numberOfDots > 3 then
                playNowWindow.searchingForGameText.numberOfDots = 0
            end
            
            playNowWindow.searchingForGameText:SetText("SEARCHING" .. string.rep(".", playNowWindow.searchingForGameText.numberOfDots))
            
        end
        
        UpdateAutoJoin(playNowWindow)
        
    end
    
end

local function CreatePlayNowPage(self)

    self.playNowWindow = self:CreateWindow()
    self.playNowWindow:SetWindowName("PLAY NOW")
    self.playNowWindow:SetInitialVisible(false)
    self.playNowWindow:SetIsVisible(false)
    self.playNowWindow:DisableResizeTile()
    self.playNowWindow:DisableSlideBar()
    self.playNowWindow:DisableContentBox()
    self.playNowWindow:SetCSSClass("playnow_window")
    self.playNowWindow:DisableCloseButton()
    
    self.playNowWindow.UpdateLogic = UpdatePlayNowWindowLogic
    
    local eventCallbacks =
    {
        OnShow = function(self)
        
            self.scriptHandle:OnWindowOpened(self)
            MainMenu_OnWindowOpen()
            
        end,
        
        OnHide = function(self)
            self.scriptHandle:OnWindowClosed(self)
        end
    }
    self.playNowWindow:AddEventCallbacks(eventCallbacks)
    
    self.playNowWindow.searchingForGameText = CreateMenuElement(self.playNowWindow.titleBar, "Font", false)
    self.playNowWindow.searchingForGameText:SetCSSClass("playnow_title")
    self.playNowWindow.searchingForGameText:SetText("SEARCHING...")
    
    local cancelButton = CreateMenuElement(self.playNowWindow, "MenuButton")
    cancelButton:SetCSSClass("playnow_cancel")
    cancelButton:SetText("CANCEL")
    
    cancelButton:AddEventCallbacks({ OnClick =
    function() self.playNowWindow:SetIsVisible(false) end })
    
end

local function CloseFirstTimeWindow(self)

    if self.playFirstTimeWindow then

        local storeOption = self.showFirstTimeCheckbox:GetValue()
        Client.SetOptionString("preventFirstTimeWindow", ToString(storeOption))
        
        self:DestroyWindow(self.playFirstTimeWindow)
        self.playFirstTimeWindow = nil
    
    end

end

local function UpdatePlayFirstTimeWindow(self)

    local showWindow = Client.GetOptionString("preventFirstTimeWindow", "false") == "false"

    if showWindow and not self.playFirstTimeWindow then
    
        self.playFirstTimeWindow = self:CreateWindow()  
        self.playFirstTimeWindow:SetWindowName("HINT")
        self.playFirstTimeWindow:SetInitialVisible(false)
        self.playFirstTimeWindow:SetIsVisible(false)
        self.playFirstTimeWindow:DisableResizeTile()
        self.playFirstTimeWindow:DisableSlideBar()
        self.playFirstTimeWindow:DisableContentBox()
        self.playFirstTimeWindow:SetCSSClass("first_time_window")
        self.playFirstTimeWindow:DisableCloseButton()
        //self.playFirstTimeWindow:AddEventCallbacks( { OnBlur = function(self) CloseFirstTimeWindow(self.scriptHandle) end } )
        
        local hint = CreateMenuElement(self.playFirstTimeWindow, "Font")
        hint:SetCSSClass("first_time_message")
        hint:SetText(Locale.ResolveString("PLAY_FIRST_TIME_MESSAGE"))
        
        local hintLink = CreateMenuElement(self.playFirstTimeWindow, "Image")
        hintLink:SetCSSClass("first_time_video_link")
        
        hintLink.OnClick = function() SetMenuWebView("http://unknownworlds.com/spark/ns2/tutorials/tut0.html", Vector(Client.GetScreenWidth() * 0.8, Client.GetScreenHeight() * 0.8, 0)) end
        hintLink:EnableHighlighting()
        
        self.showFirstTimeCheckbox = CreateMenuElement(self.playFirstTimeWindow, "Checkbox")
        self.showFirstTimeCheckbox:SetCSSClass("firsttimecheckbox")
        self.showFirstTimeCheckbox:SetValue(false)
        
        local dontShowAgain = CreateMenuElement(self.playFirstTimeWindow, "Font")
        dontShowAgain:SetCSSClass("dontshowagain")
        dontShowAgain:SetText(Locale.ResolveString("DONT_SHOW_AGAIN"))
        
        local okButton = CreateMenuElement(self.playFirstTimeWindow, "MenuButton")
        okButton:SetCSSClass("small_bottom_right")
        okButton:SetText("CLOSE")
        
        okButton:AddEventCallbacks({ OnClick = function (self) CloseFirstTimeWindow(self.scriptHandle) end })
    
    end
    
    if self.playFirstTimeWindow then
        self.playFirstTimeWindow:SetIsVisible(showWindow)
    end

end

local function CreateJoinServerPage(self)

    self:CreateServerListWindow()
    self.playWindow:AddEventCallbacks({ 
        OnShow =
            function(self) UpdatePlayFirstTimeWindow(self.scriptHandle) end,
        OnHide =
            function(self) CloseFirstTimeWindow(self.scriptHandle) end 
    })
    
end

local function CreateHostGamePage(self)

    self.createGame = CreateMenuElement(self.playWindow:GetContentBox(), "Image")
    self.createGame:SetCSSClass("play_now_content")
    self:CreateHostGameWindow()
    
end

local function CreateFindPeoplePage(self)
    self:CreateFindPeopleWindow()
end

local function ShowServerWindow(self)

    self.playWindow.updateButton:SetIsVisible(true)
    self.joinServerButton:SetIsVisible(true)
    self.highlightServer:SetIsVisible(true)
    self.selectServer:SetIsVisible(true)
    self.serverRowNames:SetIsVisible(true)
    self.serverList:SetIsVisible(true)
    self.filterForm:SetIsVisible(true)
    
    // Re-enable slide bar.
    self.playWindow:SetSlideBarVisible(true)
    self.playWindow:ResetSlideBar()
    
end

local function HideServerWindow(self)

    self.playWindow.updateButton:SetIsVisible(false)
    self.joinServerButton:SetIsVisible(false)
    self.highlightServer:SetIsVisible(false)
    self.selectServer:SetIsVisible(false)
    self.serverRowNames:SetIsVisible(false)
    self.serverList:SetIsVisible(false)
    self.filterForm:SetIsVisible(false)
    
    // Hide it, but make sure it's at the top position.
    self.playWindow:SetSlideBarVisible(false)
    self.playWindow:ResetSlideBar()
    
end

function GUIMainMenu:SetPlayContentInvisible(cssClass)

    HideServerWindow(self)
    self.createGame:SetIsVisible(false)
    self.findPeopleWindow:SetIsVisible(false)
    self.playNowWindow:SetIsVisible(false)
    self.hostGameButton:SetIsVisible(false)
    
    if cssClass then
        self.playWindow:GetContentBox():SetCSSClass(cssClass)
    end
    
end

function GUIMainMenu:CreatePlayWindow()

    self.playWindow = self:CreateWindow()
    self:SetupWindow(self.playWindow, "PLAY")
    self.playWindow:AddCSSClass("play_window")
    self.playWindow:ResetSlideBar()    // so it doesn't show up mis-drawn
    self.playWindow:GetContentBox():SetCSSClass("serverbrowse_content")
    
    local hideTickerCallbacks =
    {
        OnShow = function(self)
            self.scriptHandle.tweetText:SetIsVisible(false)
        end,
        
        OnHide = function(self)
            self.scriptHandle.tweetText:SetIsVisible(true)
        end
    }
    
    self.playWindow:AddEventCallbacks( hideTickerCallbacks )
    
    local back = CreateMenuElement(self.playWindow, "MenuButton")
    back:SetCSSClass("back")
    back:SetText("BACK")
    back:AddEventCallbacks( { OnClick = function() self.playWindow:SetIsVisible(false) end } )
    
    local tabs = 
        {
            { label = "JOIN", func = function(self) self.scriptHandle:SetPlayContentInvisible("serverbrowse_content") ShowServerWindow(self.scriptHandle) end },
            //{ label = "PICK UP GAME", func = function(self) self.scriptHandle:SetPlayContentInvisible("play_content") self.scriptHandle.findPeopleWindow:SetIsVisible(true) end},
            { label = "QUICK JOIN", func = function(self) self.scriptHandle:SetPlayContentInvisible("play_content") self.scriptHandle.playNowWindow:SetIsVisible(true) end },
            { label = "START SERVER", func = function(self) self.scriptHandle:SetPlayContentInvisible("play_content") self.scriptHandle.createGame:SetIsVisible(true) self.scriptHandle.hostGameButton:SetIsVisible(true) end }
        }
        
    local xTabWidth = 256

    local tabBackground = CreateMenuElement(self.playWindow, "Image")
    tabBackground:SetCSSClass("tab_background")
    tabBackground:SetIgnoreEvents(true)
    
    local tabAnimateTime = 0.1
        
    for i = 1,#tabs do
    
        local tab = tabs[i]
        local tabButton = CreateMenuElement(self.playWindow, "MenuButton")
        
        local function ShowTab()
            for j =1,#tabs do
                local tabPosition = tabButton.background:GetPosition()
                tabBackground:SetBackgroundPosition( tabPosition, false, tabAnimateTime ) 
            end
        end
    
        tabButton:SetCSSClass("tab")
        tabButton:SetText(tab.label)
        tabButton:AddEventCallbacks({ OnClick = tab.func })
        tabButton:AddEventCallbacks({ OnClick = ShowTab })
        
        local tabWidth = tabButton:GetWidth()
        tabButton:SetBackgroundPosition( Vector(tabWidth * (i - 1), 0, 0) )
        
    end

    CreateJoinServerPage(self)
    CreatePlayNowPage(self)
    CreateHostGamePage(self)
    CreateFindPeoplePage(self)
    
    self:SetPlayContentInvisible()
    ShowServerWindow(self)
    
end