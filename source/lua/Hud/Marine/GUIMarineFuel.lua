// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineFuel.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Displays fuel of jetpack.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Marine/GUIMarineHUDElement.lua")
Script.Load("lua/Utility.lua")

class 'GUIMarineFuel' (GUIMarineHUDElement)

// --------- positions ----------

// ----------- colors -----------

// ------------ fonts -----------

function CreateFuelDisplay(scriptHandle, hudLayer)

    local marineFuel = GUIMarineFuel()
    marineFuel.script = scriptHandle
    marineFuel.hudLayer = hudLayer
    marineFuel:Initialize()
    return marineFuel

end

function GUIMarineFuel:Initialize()
end

function GUIMarineFuel:Update(deltaTime, parameters)
end

function GUIMarineFuel:Destroy()
end