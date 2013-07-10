// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Ragdoll.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    A fake ragdoll that dissolves after kRagdollDuration.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Entity.lua")
Script.Load("lua/Mixins/ModelMixin.lua")

function CreateRagdoll(fromEntity)

    local useModelName = fromEntity:GetModelName()
    local useGraphName = fromEntity:GetGraphName()
    
    if useModelName and string.len(useModelName) > 0 and useGraphName and string.len(useGraphName) > 0 then

        local ragdoll = CreateEntity(Ragdoll.kMapName, fromEntity:GetOrigin())
        ragdoll:SetCoords(fromEntity:GetCoords())
        ragdoll:SetModel(useModelName, useGraphName)
        
        if fromEntity.GetPlayInstantRagdoll and fromEntity:GetPlayInstantRagdoll() then
            ragdoll:SetPhysicsType(PhysicsType.Dynamic)
            ragdoll:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        else    
            ragdoll:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)    
        end
        
        ragdoll:CopyAnimationState(fromEntity)
    
    end
    
end

class 'Ragdoll' (Entity)

local kRagdollDuration = 6

Ragdoll.kMapName = "ragdoll"

local networkVars =
{
    creationTime = "float"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function Ragdoll:OnCreate()

    Entity.OnCreate(self)
    
    self.creationTime = Shared.GetTime()
    
    if Server then
        self:AddTimedCallback(Ragdoll.TimeUp, kRagdollDuration)
    end
    
    self:SetUpdates(true)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)  

end

function Ragdoll:OnUpdateAnimationInput(modelMixin)
    PROFILE("Ragdoll:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("alive", false)  
    modelMixin:SetAnimationInput("built", true)
    modelMixin:SetAnimationInput("active", true)
end

function Ragdoll:OnUpdatePoseParameters()
    self:SetPoseParam("grow", 1)    
end

function Ragdoll:TimeUp()
    DestroyEntity(self)
end

function Ragdoll:OnUpdateRender()

    PROFILE("Ragdoll:OnUpdateRender")
    
    local remainingLifeTime = kRagdollDuration - (Shared.GetTime() - self.creationTime)
    if remainingLifeTime <= 1 then

        local dissolveAmount = Clamp(1 - remainingLifeTime, 0, 1)
        self:SetOpacity(1-dissolveAmount, "dissolveAmount")
        
    end
    
end

if Server then

    function Ragdoll:OnTag(tagName)
    
        PROFILE("Ragdoll:OnTag")
    
        if tagName == "death_end" then
            self:SetPhysicsType(PhysicsType.Dynamic)
            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        end
        
    end
    
end

Shared.LinkClassToMap("Ragdoll", Ragdoll.kMapName, networkVars)