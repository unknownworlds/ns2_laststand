// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIRightMinigunDisplay.lua
//
// Created by: Andreas Urwalek(andi@unknownworlds.com)
//
// Displays the heat amount for the Exo's right Minigun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Global state that can be externally set to adjust the display.
heatAmountright = 0

function Update(dt)  
    UpdateOverHeat(dt, heatAmountright)
end

Script.Load("lua/GUIMinigun.lua")