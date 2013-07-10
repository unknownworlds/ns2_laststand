// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Skulk:InitWeapons()

    Alien.InitWeapons(self)
    
    local activeWeapon = nil

    if self:GetHasUpgrade(kTechId.Parasite) then
        self:GiveItem(Parasite.kMapName)
        activeWeapon = Parasite.kMapName
    end

    if self:GetHasUpgrade(kTechId.Xenocide) then
        self:GiveItem(XenocideLeap.kMapName)
        activeWeapon = XenocideLeap.kMapName
    end
    
    if self:GetHasUpgrade(kTechId.Bite) then
        self:GiveItem(BiteLeap.kMapName)
        activeWeapon = BiteLeap.kMapName
    end
    
    if activeWeapon ~= nil then
        self:SetActiveWeapon(activeWeapon)
    end
    
end

function Skulk:GetTierTwoTechId()
    return kTechId.Leap
end

function Skulk:GetTierThreeTechId()
    return kTechId.Xenocide
end