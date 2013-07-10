// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUILeftMinigunDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays the heat amount for the Exo's Minigun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Global state that can be externally set to adjust the display.
heatAmountleft = 0

function Update(dt)  
    UpdateOverHeat(dt, heatAmountleft)
end

Script.Load("lua/GUIMinigun.lua")