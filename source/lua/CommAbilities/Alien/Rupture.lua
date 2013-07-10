// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Rupture.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Obscures marines vision.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

class 'Rupture' (CommanderAbility)

Rupture.kMapName = "rupture"

Rupture.kRuptureEffect = PrecacheAsset("cinematics/alien/cyst/rupture.cinematic")
Rupture.kRuptureViewEffect = PrecacheAsset("cinematics/alien/cyst/rupture_view.cinematic")

Rupture.kType = CommanderAbility.kType.Instant

Rupture.kRadius = 10
Rupture.kDuration = 4
local networkVars = { }

function Rupture:OnInitialized()
    
    CommanderAbility.OnInitialized(self)

end

function Rupture:GetStartCinematic()
    return Rupture.kRuptureEffect
end

function Rupture:GetType()
    return Rupture.kType
end

function Rupture:Perform()

    if Server then
    
        local enemies = GetEntitiesForTeamWithinRange("Marine", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Rupture.kRadius)
        
        TEST_EVENT("Rupture triggered")
        
        for _, entity in ipairs(enemies) do
            entity:SetRuptured()
        end
        
    elseif Client then
    
        // apply rupture to all marines nearby
        local player = Client.GetLocalPlayer()
        
        if player and player:isa("Marine") and (player:GetEyePos() - self:GetOrigin()):GetLengthSquared() < Rupture.kRadius * Rupture.kRadius then
        
            local viewCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            viewCinematic:SetCinematic(Rupture.kRuptureViewEffect)
            
            TEST_EVENT("Rupture blocked vision")
            
        end
        
    end
    
end

Shared.LinkClassToMap("Rupture", Rupture.kMapName, networkVars)