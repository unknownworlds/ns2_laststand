// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Extractor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Marine resource extractor. Gathers resources when built on a nozzle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")

Script.Load("lua/ResourceTower.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")

class 'Extractor' (ResourceTower)

Extractor.kMapName = "extractor"

Extractor.kModelName = PrecacheAsset("models/marine/extractor/extractor.model")

local kAnimationGraph = PrecacheAsset("models/marine/extractor/extractor.animation_graph")

Shared.PrecacheModel(Extractor.kModelName)

local networkVars = { }

AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)

function Extractor:OnCreate()

    ResourceTower.OnCreate(self)
    
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, PowerConsumerMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
end

function Extractor:OnInitialized()

    ResourceTower.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)
    
    self:SetModel(Extractor.kModelName, kAnimationGraph)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, InfestationTrackerMixin)
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end

end

function Extractor:GetRequiresPower()
    return true
end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end

if Server then

    function Extractor:GetIsCollecting()    
        return ResourceTower.GetIsCollecting(self) and self:GetIsPowered()  
    end
    
end

local kExtractorHealthbarOffset = Vector(0, 2.0, 0)
function Extractor:GetHealthbarOffset()
    return kExtractorHealthbarOffset
end 

Shared.LinkClassToMap("Extractor", Extractor.kMapName, networkVars)