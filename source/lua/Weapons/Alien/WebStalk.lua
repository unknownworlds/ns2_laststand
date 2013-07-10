// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\WebStalk.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)  
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'WebStalk' (Ability)

WebStalk.kMapName = "webstalk"

WebStalk.networkVars =
{
}

function WebStalk:GetHUDSlot()
    return 4
end


Shared.LinkClassToMap("WebStalk", WebStalk.kMapName, WebStalk.networkVars )