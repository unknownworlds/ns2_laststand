// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Lerk:InitWeapons()

    Alien.InitWeapons(self)

    local activeWeapon = nil
    
    if self:GetHasUpgrade(kTechId.Spores) then
        self:GiveItem(Spores.kMapName) 
        activeWeapon = Spores.kMapName
    end

    if self:GetHasUpgrade(kTechId.Umbra) then
        self:GiveItem(LerkUmbra.kMapName) 
        activeWeapon = LerkUmbra.kMapName
    end

    if self:GetHasUpgrade(kTechId.LerkBite) or self:GetHasUpgrade(kTechId.Spikes) then
        self:GiveItem(LerkBite.kMapName) 
        activeWeapon = LerkBite.kMapName
    end
        
    self:SetActiveWeapon(activeWeapon)
    
end

function Lerk:GetTierTwoTechId()
    return kTechId.Spores
end

function Lerk:GetTierThreeTechId()
    return kTechId.Umbra
end



