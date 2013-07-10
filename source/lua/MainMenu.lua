//=============================================================================
//
// lua/MainMenu.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

Script.Load("lua/InterfaceSounds_Client.lua")
Script.Load("lua/ServerBrowser.lua")
Script.Load("lua/CreateServer.lua")
Script.Load("lua/OptionsDialog.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/Update.lua")
Script.Load("lua/MenuManager.lua")
Script.Load("lua/DSPEffects.lua")
Script.Load("lua/SoundEffect.lua")

CreateDSPs()

local kAllowDebuggingMainMenu = false

local mainMenuMusic = nil
local mainMenuAlertMessage  = nil

mods = { "ns2" }
mapnames = { }
maps = { }

local loadLuaMenu = true
local gMainMenu = nil

local matchingFiles = { }
Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)

for _, mapFile in pairs(matchingFiles) do

    local _, _, filename = string.find(mapFile, "maps/(.*).level")
    local mapname = string.gsub(filename, 'ns2_', '', 1):gsub("^%l", string.upper)
    local tagged,_ = string.match(filename, "ns2_", 1)
    if tagged ~= nil then
    
        table.insert(mapnames, mapname)
        table.insert(maps, {["name"] = mapname, ["fileName"] = filename})
        
    end
    
end

function MainMenu_GetIsOpened()

    // Don't load or open main menu while debugging (too slow).
    if not GetIsDebugging() or kAllowDebuggingMainMenu then
    
        if loadLuaMenu then
        
            if not gMainMenu then
                return false
            else
                return gMainMenu:GetIsVisible()
            end
            
        else
            return MenuManager.GetMenu() ~= nil
        end
        
    end
    
    return false
    
end

function LeaveMenu()

    MainMenu_OnCloseMenu()
    
    if gMainMenu then
        gMainMenu:SetIsVisible(false)
    end
    
    MenuManager.SetMenuCinematic(nil)
    MenuMenu_PlayMusic(nil)
    
end

/**
 * Plays background music in the main menu. The music will be automatically stopped
 * when the menu is left.
 */
function MenuMenu_PlayMusic(fileName)

    if mainMenuMusic ~= nil then
        Client.StopMusic(mainMenuMusic)    
    end
    
    mainMenuMusic = fileName
    
    if mainMenuMusic ~= nil then
        Client.PlayMusic(mainMenuMusic)
    end
    
end

/**
 * Called when the user selects the "Host Game" button in the main menu.
 */
function MainMenu_HostGame(mapFileName, modName)

    local port = 27015
    local maxPlayers = Client.GetOptionInteger("playerLimit", 16)
    local password = Client.GetOptionString("serverPassword", "")
    local serverName = Client.GetOptionString("serverName", "Listen Server")
    
    MainMenu_OnConnect()
    
    if Client.StartServer(mapFileName, serverName, password, port, maxPlayers) then
        LeaveMenu()
    end
    
end

function MainMenu_SelectServer(serverNum)
    gSelectedServerNum = serverNum
end

function MainMenu_GetSelectedServer()
    return gSelectedServerNum
end

function MainMenu_SetSelectedServerPassword(password)
    gPassword = password
end

function MainMenu_GetSelectedRequiresPassword()

    if gSelectedServerNum then
    
        if gSelectedServerNum >= 0 then
            return Client.GetServerRequiresPassword(gSelectedServerNum)
        else
            return GetFavoriteServers()[-gSelectedServerNum].requiresPassword
        end
        
    end
    
    return false
    
end

function MainMenu_GetSelectedIsFull()
    
    if gSelectedServerNum then
        return Client.GetServerNumPlayers(gSelectedServerNum) == Client.GetServerMaxPlayers(gSelectedServerNum)
    end
    
end

function MainMenu_GetSelectedServerName()
    
    if gSelectedServerNum then
        return Client.GetServerName(gSelectedServerNum)
    end
    
end

function MainMenu_JoinSelected()

    local address = nil
    local mapName = nil
    if gSelectedServerNum >= 0 then
    
        address = Client.GetServerAddress(gSelectedServerNum)
        mapName = Client.GetServerMapName(gSelectedServerNum)
        
    else
        address = GetFavoriteServers()[-gSelectedServerNum].address
    end
    
    MainMenu_SBJoinServer(address, gPassword, mapName)
    
end

function GetModName(mapFileName)

    for index, mapEntry in ipairs(maps) do
    
        if mapEntry.fileName == mapFileName then
            return mapEntry.modName
        end
        
    end
    
    return nil
    
end

/**
 * Returns true if we hit ESC while playing to display menu, false otherwise. 
 * Indicates to display the "Back to game" button.
 */
function MainMenu_IsInGame()
    return Client.GetIsConnected()    
end

/**
 * Called when button clicked to return to game.
 */
function MainMenu_ReturnToGame()
    LeaveMenu()
end

/**
 * Set a message that will be displayed in window in the main menu the next time
 * it's updated.
 */
function MainMenu_SetAlertMessage(alertMessage)
    mainMenuAlertMessage = alertMessage
end

/**
 * Called every frame to see if a dialog should be popped up.
 * Return string to show (one time, message should not continually be returned!)
 * Return "" or nil for no message to pop up
 */
function MainMenu_GetAlertMessage()

    local alertMessage = mainMenuAlertMessage
    mainMenuAlertMessage = nil
    
    return alertMessage
    
end

function MainMenu_Open()

    // Don't load or open main menu while debugging (too slow).
    if not GetIsDebugging() or kAllowDebuggingMainMenu then
    
        // Load and set default sound levels
        OptionsDialogUI_OnInit()
        
        if loadLuaMenu then
        
            if not gMainMenu then
                gMainMenu = GetGUIManager():CreateGUIScript("menu/GUIMainMenu")
            end
            gMainMenu:SetIsVisible(true)
            
        else
        
            MenuManager.SetMenu(kMainMenuFlash)
            MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", false)
            
        end
        
        MainMenu_OnOpenMenu()
        
    end
    
end

function MainMenu_GetMapNameList()
    return mapnames
end

function MainMenu_OnServerRefreshed(serverIndex)
    gMainMenu:OnServerRefreshed(serverIndex)
end

/**
 * Called when the user types the "map" command at the console.
 */
local function OnCommandMap(mapFileName)

    MainMenu_HostGame(mapFileName)
    
    if Client then
        Client.SetOptionString("lastServerMapName", mapFileName)
    end
    
end

/**
 * Called when the user types the "connect" command at the console.
 */
local function OnCommandConnect(address, password)
    MainMenu_SBJoinServer(address, password)
end

/**
 * This is called if the user tries to join a server through the
 * Steam UI.
 */
local function OnConnectRequested(address, password)
    MainMenu_SBJoinServer(address, password)
end

/**
 * Sound events
 */
local kMouseInSound = "sound/NS2.fev/common/hovar"
local kMouseOutSound = "sound/NS2.fev/common/tooltip"
local kClickSound = "sound/NS2.fev/common/button_press"
local kCheckboxOnSound = "sound/NS2.fev/common/checkbox_on"
local kCheckboxOffSound = "sound/NS2.fev/common/checkbox_off"
local kCheckboxOffSound = "sound/NS2.fev/common/checkbox_off"
local kConnectSound = "sound/NS2.fev/common/checkbox_off"
local kOpenMenuSound = "sound/NS2.fev/common/menu_confirm"
local kCloseMenuSound = "sound/NS2.fev/common/menu_confirm"
local kLoopingMenuSound = "sound/NS2.fev/common/menu_loop"
local kWindowOpenSound = "sound/NS2.fev/common/open"

Client.PrecacheLocalSound(kMouseInSound)
Client.PrecacheLocalSound(kMouseOutSound)
Client.PrecacheLocalSound(kClickSound)
Client.PrecacheLocalSound(kCheckboxOnSound)
Client.PrecacheLocalSound(kCheckboxOffSound)
Client.PrecacheLocalSound(kConnectSound)
Client.PrecacheLocalSound(kOpenMenuSound)
Client.PrecacheLocalSound(kCloseMenuSound)
Client.PrecacheLocalSound(kLoopingMenuSound)
Client.PrecacheLocalSound(kWindowOpenSound)

function MainMenu_OnMouseIn()
    StartSoundEffect(kMouseInSound)
end

function MainMenu_OnMouseOut()
    //StartSoundEffect(kMouseOutSound)
end

function MainMenu_OnMouseClick()
    StartSoundEffect(kClickSound)
end

function MainMenu_OnWindowOpen()
    StartSoundEffect(kWindowOpenSound)
end

function MainMenu_OnCheckboxOn()
    StartSoundEffect(kCheckboxOnSound)
end

function MainMenu_OnCheckboxOff()
    StartSoundEffect(kCheckboxOffSound)
end

function MainMenu_OnConnect()
    StartSoundEffect(kConnectSound)
end

function MainMenu_OnOpenMenu()
    StartSoundEffect(kLoopingMenuSound)    
end

function MainMenu_OnCloseMenu()
    StartSoundEffect(kLoopingMenuSound)    
end

function MainMenu_LoadNewsURL(url)

    if gMainMenu.newsScript then
        gMainMenu.newsScript:LoadURL(url)
    end
    
end

local function OnClientDisconnected()
    LeaveMenu()
end

Event.Hook("ClientDisconnected", OnClientDisconnected)
Event.Hook("ConnectRequested", OnConnectRequested)

Event.Hook("Console_connect",  OnCommandConnect)
Event.Hook("Console_map",  OnCommandMap)