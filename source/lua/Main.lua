//=============================================================================
//
// lua/Main.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2012, Unknown Worlds Entertainment
//
// This file is loaded when the game first starts up and displays the main menu.
//
//=============================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/Render.lua")
Script.Load("lua/GUIManager.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/MainMenu.lua")

local renderCamera = nil
    
MenuManager.SetMenuCinematic("cinematics/main_menu.cinematic")

local function OnUpdateRender()

    local cullingMode = RenderCamera.CullingMode_Occlusion
    local camera = MenuManager.GetCinematicCamera()
    
    if camera ~= false then
    
        renderCamera:SetCoords(camera:GetCoords())
        renderCamera:SetFov(camera:GetFov())
        renderCamera:SetNearPlane(0.01)
        renderCamera:SetFarPlane(10000.0)
        renderCamera:SetCullingMode(cullingMode)
        Client.SetRenderCamera(renderCamera)
        
    else
        Client.SetRenderCamera(nil)
    end
    
end

local function OnLoadComplete(message)
    
    renderCamera = Client.CreateRenderCamera()
    renderCamera:SetRenderSetup("renderer/Deferred.render_setup") 
    
    Render_SyncRenderOptions()
    OptionsDialogUI_SyncSoundVolumes()
    
    MenuMenu_PlayMusic("sound/NS2.fev/Main Menu")
    MainMenu_Open()
    
    if message then
        MainMenu_SetAlertMessage(message)
    end

    Print("Last Stand, 5/1/13")
        
end

Event.Hook("UpdateRender", OnUpdateRender)
Event.Hook("LoadComplete", OnLoadComplete)
