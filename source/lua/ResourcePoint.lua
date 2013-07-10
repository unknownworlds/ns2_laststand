// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourcePoint.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'ResourcePoint' (ScriptActor)

ResourcePoint.kPointMapName = "resource_point"

local kEffect = PrecacheAsset("cinematics/common/resnode.cinematic")
local kIdleSound = PrecacheAsset("sound/NS2.fev/common/resnode_idle")

ResourcePoint.kModelName = PrecacheAsset("models/misc/resource_nozzle/resource_nozzle.model")

local networkVars =
{
    playingEffect = "boolean",
    showObjective = "boolean",
    occupiedTeam = string.format("integer (-1 to %d)", kSpectatorIndex),
    attachedId = "entityid",
}
    
if Server then
    Script.Load("lua/ResourcePoint_Server.lua")
end

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function ResourcePoint:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)   
        self.resnodeEffectPlaying = false
    end
    
    // Anything that can be built upon should have this group
    self:SetPhysicsGroup(PhysicsGroup.AttachClassGroup)
    
    // Make the nozzle kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    self:SetTechId(kTechId.ResourcePoint)
    
end

function ResourcePoint:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(ResourcePoint.kModelName)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self:SetRelevancyDistance(Math.infinity)
        self:SetExcludeRelevancyMask(bit.bor(kRelevantToTeam1, kRelevantToTeam2))
        
        self.showObjective = false
        self.occupiedTeam = 0
    elseif Client then
        InitMixin(self, UnitStatusMixin)     
    end
    
end

function ResourcePoint:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end


function ResourcePoint:Reset()
    
    self:OnInitialized()
    
    self:ClearAttached()
    
    local locationName = self:GetLocationName()
    if locationName == nil or locationName == "" then
        Print("Resource point at %s isn't in a valid location (\"%s\", it won't be socketed)", ToString(locationName), ToString(self:GetOrigin()))
    end
    
end

if Client then

    function ResourcePoint:OnUpdate(deltaTime)
    
        ScriptActor.OnUpdate(self, deltaTime)
        
        // changed this to check for attached entity, instead of controlling the effect serverside
        local attached = self:GetAttached()
        
        local playEffect = not attached or (not attached:GetIsVisible())
        
        if not playEffect and self.resnodeEffectPlaying then
        
            self:DestroyAttachedEffects()
            self:StopSound(kIdleSound)
            self.resnodeEffectPlaying = false
            
        elseif playEffect and not self.resnodeEffectPlaying then
        
            self:AttachEffect(kEffect, self:GetCoords())
            self:PlaySound(kIdleSound)
            self.resnodeEffectPlaying = true
            
        end

    end
    
end

local kResourcePointHealthbarOffset = Vector(0, 0.6, 0)
function ResourcePoint:GetHealthbarOffset()
    return kResourcePointHealthbarOffset
end 

Shared.LinkClassToMap("ResourcePoint", ResourcePoint.kPointMapName, networkVars)