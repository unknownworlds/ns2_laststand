// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EnergizeMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * EnergizeMixin drags out parts of an umbra cloud to protect an alien for additional EnergizeMixin.kUmbraDragTime seconds.
 */
EnergizeMixin = { }
EnergizeMixin.type = "Energize"

EnergizeMixin.kSegment1Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail1.cinematic")
EnergizeMixin.kSegment2Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail2.cinematic")
EnergizeMixin.kViewModelCinematic = PrecacheAsset("cinematics/alien/crag/umbra_1p.cinematic")

local kMaxEnergizeLevel = 3

EnergizeMixin.expectedMixins =
{
    GameEffects = "Required to track energize state",
}

EnergizeMixin.networkVars =
{
    energizeLevel = "private integer (0 to " .. kMaxEnergizeLevel .. ")"
}

function EnergizeMixin:__initmixin()

    self.energizeLevel = 0

    if Server then
        self.energizeGivers = {}
        self.energizeGiverTime = {}
        self.timeLastEnergizeUpdate = 0
    end    
end

if Server then

    function EnergizeMixin:Energize(giver)
        
        table.insertunique(self.energizeGivers, giver:GetId())
        self.energizeGiverTime[giver:GetId()] = Shared.GetTime()
    
    end

end

local function SharedUpdate(self, deltaTime)

    if Server then
    
        local removeGiver = {}
        for _, giverId in ipairs(self.energizeGivers) do
            
            if self.energizeGiverTime[giverId] + 1 < Shared.GetTime() then
                self.energizeGiverTime[giverId] = nil
                table.insert(removeGiver, giverId)
            end
            
        end
        
        // removed timed out
        for _, removeId in ipairs(removeGiver) do
            table.removevalue(self.energizeGivers, removeId)
        end
        
        self.energizeLevel = Clamp(#self.energizeGivers, 0, kMaxEnergizeLevel)
        self:SetGameEffectMask(kGameEffect.Energize, self.energizeLevel > 0)
        
        if self.energizeLevel > 0 and self.timeLastEnergizeUpdate + kEnergizeUpdateRate < Shared.GetTime() then
        
            local energy = ConditionalValue(self:isa("Player"), kPlayerEnergyPerEnergize, kStructureEnergyPerEnergize)
            energy = energy * self.energizeLevel
            self:AddEnergy(energy)
            self.timeLastEnergizeUpdate = Shared.GetTime()
        
        end
        
    elseif Client then

        if self:GetGameEffectMask(kGameEffect.Energize) and (not HasMixin(self, "Cloakable") or not self:GetIsCloaked() ) then
        
            if self:GetEnergy() < self:GetMaxEnergy() and (not self.timeLastEnergizeEffect or self.timeLastEnergizeEffect + 2 < Shared.GetTime()) then
                //self:TriggerEffects("energize")
                self.timeLastEnergizeEffect = Shared.GetTime() 
            end
            
        end
    
    end
    
end

function EnergizeMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(EnergizeMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergizeMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(EnergizeMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

/*
function EnergizeMixin:AddEnergy(energy)

    if Server or ( Client and Client.GetLocalPlayer() == self ) then
        if self:GetGameEffectMask(kGameEffect.Energize) then
            self:SetEnergy(self:GetEnergy() + energy * kEnergizeEnergyIncrease * self.energizeLevel)
        end
    end
    
end
*/

function EnergizeMixin:GetEnergizeLevel()
    return self.energizeLevel
end