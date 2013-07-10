// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gorge:InitWeapons()

    Alien.InitWeapons(self)

    local activeWeapon = nil
    
    if self:GetHasUpgrade(kTechId.BileBomb) then
        self:GiveItem(BileBomb.kMapName)
        activeWeapon = BileBomb.kMapName   
    end
    
    if self:GetHasUpgrade(kTechId.BuildAbility) then
        self:GiveItem(DropStructureAbility.kMapName)
        activeWeapon = DropStructureAbility.kMapName
    end
    
    if self:GetHasUpgrade(kTechId.BabblerAbility) then
        self:GiveItem(BabblerAbility.kMapName)
        activeWeapon = BabblerAbility.kMapName
    end
    
    if self:GetHasUpgrade(kTechId.Heal) or self:GetHasUpgrade(kTechId.Spit) then
        self:GiveItem(SpitSpray.kMapName)
        activeWeapon = SpitSpray.kMapName
    end
    
    if activeWeapon ~= nil then
        self:SetActiveWeapon(activeWeapon)
    end
    
end

function Gorge:GetTierTwoTechId()
    return kTechId.BileBomb
end

function Gorge:GetTierThreeTechId()
    return kTechId.Web
end

function Gorge:OnCommanderStructureLogin(hive)

    DestroyEntity(self.slideLoopSound)
    self.slideLoopSound = nil

end

function Gorge:OnCommanderStructureLogout(hive)

    self.slideLoopSound = Server.CreateEntity(SoundEffect.kMapName)
    self.slideLoopSound:SetAsset(Gorge.kSlideLoopSound)
    self.slideLoopSound:SetParent(self)

end

function Gorge:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    if(order:GetType() == kTechId.Default and GetOrderTargetIsHealTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Heal)
        
    end
    
end
