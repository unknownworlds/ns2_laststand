// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineHUDElement.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Base class for Marine Hud elements.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMarineHUDElement'

function GUIMarineHUDElement:Initialize()
    Print("GUIMarineHUDElement:Initialize()")
end

function GUIMarineHUDElement:Reset(scale)
    Print("GUIMarineHUDElement:Reset()")
end

function GUIMarineHUDElement:Update(deltaTime, parameters)
    Print("GUIMarineHUDElement:Update()")
end

function GUIMarineHUDElement:Destroy()
    Print("GUIMarineHUDElement:Destroy()")
end