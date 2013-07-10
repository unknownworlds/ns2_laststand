//=============================================================================
//
// lua/MenuManager.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2012, Unknown Worlds Entertainment
//
//=============================================================================

MenuManager = { }
MenuManager.menuCinematic   = nil

/**
 * Sets the cinematic that's displayed behind the main menu.
 */
function MenuManager.SetMenuCinematic(fileName)

    if MenuManager.menuCinematic ~= nil then
    
        Client.DestroyCinematic(MenuManager.menuCinematic)
        MenuManager.menuCinematic = nil
        
    end
    
    if fileName ~= nil then
    
        MenuManager.menuCinematic = Client.CreateCinematic()
        MenuManager.menuCinematic:SetRepeatStyle(Cinematic.Repeat_Loop)
        MenuManager.menuCinematic:SetCinematic(fileName)
        
    end
    
end

function MenuManager.GetCinematicCamera()

    // Try to get the camera from the cinematic.
    if MenuManager.menuCinematic ~= nil then
        return MenuManager.menuCinematic:GetCamera()
    else
        return false
    end
    
end

function MenuManager.PlaySound(fileName)
    StartSoundEffect(fileName)
end