// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Order.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugratz.at)
//
//    Provides functions for checking the current order of a marine and callbacks for effects/sound.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local function PlayOrderSoundName(type)

    local soundName = LookupTechData(type, kTechDataOrderSound, nil)
    local player = Client.GetLocalPlayer()
    if soundName and player and not player:isa("Commander") then
        StartSoundEffectOnEntity(soundName, player)
    end
    
end

function MarineOrder_OnOrderAttack()

    PlayOrderSoundName(kTechId.Attack)

end

function MarineOrder_OnOrderMove()

    PlayOrderSoundName(kTechId.Move)

end

function MarineOrder_OnOrderDefend()

    PlayOrderSoundName(kTechId.Defend)

end

function MarineOrder_OnOrderConstruct()

    PlayOrderSoundName(kTechId.Construct)

end

function MarineOrder_OnOrderRepair()

    PlayOrderSoundName(kTechId.Weld)

end