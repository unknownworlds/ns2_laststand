// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Order.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
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

function AlienOrder_OnOrderAttack()

    PlayOrderSoundName(kTechId.AlienAttack)

end

function AlienOrder_OnOrderMove()

    PlayOrderSoundName(kTechId.AlienMove)

end

function AlienOrder_OnOrderDefend()

    //PlayOrderSoundName(kTechId.AlienDefend)

end

function AlienOrder_OnOrderConstruct()

    Print("GorgeOrder_OnOrderConstruct")
    PlayOrderSoundName(kTechId.AlienConstruct)

end

function AlienOrder_OnOrderRepair()

    PlayOrderSoundName(kTechId.Heal)

end