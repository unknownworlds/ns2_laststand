// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAlienHUDElement.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Base class for Marine Hud elements.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIAlienHUDElement'

function GUIAlienHUDElement:Initialize()
    Print("GUIAlienHUDElement:Initialize()")
end

function GUIAlienHUDElement:Reset(scale)
    Print("GUIAlienHUDElement:Reset()")
end

function GUIAlienHUDElement:Update(deltaTime, parameters)
    Print("GUIAlienHUDElement:Update()")
end

function GUIAlienHUDElement:Destroy()
    Print("GUIAlienHUDElement:Destroy()")
end