// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIRightRailgunDisplay.lua
//
// Created by: Andreas Urwalek(andi@unknownworlds.com)
//
// Displays the charge amount for the Exo's right Railgun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Global state that can be externally set to adjust the display.
chargeAmountright = 0
timeSinceLastShotright = 0

function Update(dt)  
    UpdateCharge(dt, chargeAmountright, timeSinceLastShotright)
end

Script.Load("lua/GUIRailgun.lua")