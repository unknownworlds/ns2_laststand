// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BoneWall.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/ObstacleMixin.lua")

class 'BoneWall' (CommanderAbility)

BoneWall.kMapName = "bonewall"

BoneWall.kModelName = PrecacheAsset("models/alien/infestationspike/infestationspike.model")
local kAnimationGraph = PrecacheAsset("models/alien/infestationspike/infestationspike.animation_graph")

local kCommanderAbilityType = CommanderAbility.kType.OverTime
local kLifeSpan = 6

local kMoveOffset = 4
local kMoveDuration = 0.4

local networkVars =
{
    spawnPoint = "vector"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)

function AlignBoneWalls(coords)

    local nearbyMarines = GetEntitiesWithinRange("Marine", coords.origin, 20)
    Shared.SortEntitiesByDistance(coords.origin, nearbyMarines)

    for _, marine in ipairs(nearbyMarines) do
    
        if marine:GetIsAlive() and marine:GetIsVisible() then

            local newZAxis = GetNormalizedVectorXZ(marine:GetOrigin() - coords.origin)
            local newXAxis = coords.yAxis:CrossProduct(newZAxis)
            coords.zAxis = newZAxis
            coords.xAxis = newXAxis
            break
        
        end
    
    end
    
    return coords

end

function BoneWall:OnKill(attacker, doer, point, direction)

    self:TriggerEffects("death")
    DestroyEntity(self)
    
    TEST_EVENT("BoneWall killed")
    
end

function BoneWall:OnCreate()

    CommanderAbility.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ObstacleMixin)
    
end

function BoneWall:OnInitialized()

    CommanderAbility.OnInitialized(self)
    
    self.spawnPoint = self:GetOrigin()
    self:SetModel(BoneWall.kModelName, kAnimationGraph)
    
    if Server then
        self:TriggerEffects("bone_wall_burst")
    end
    
    // Make the structure kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    TEST_EVENT("BoneWall created")
    
end

function BoneWall:OverrideCheckVision()
    return false
end

function BoneWall:GetSurfaceOverride()
    return "infestation"
end    

function BoneWall:GetType()
    return kCommanderAbilityType
end

function BoneWall:GetResetsPathing()
    return true
end

function BoneWall:GetLifeSpan()
    return kLifeSpan
end

function BoneWall:OnUpdate(deltaTime)

    CommanderAbility.OnUpdate(self, deltaTime)
    
    local lifeTime = math.max(0, Shared.GetTime() - self:GetTimeCreated())
    local remainingTime = self:GetLifeSpan() - lifeTime
    
    if remainingTime < self:GetLifeSpan() then
        
        local moveFraction = 0

        if remainingTime <= 1 then
            moveFraction = 1 - Clamp(remainingTime / kMoveDuration, 0, 1)
        end
        
        local piFraction = moveFraction * (math.pi / 2)

        self:SetOrigin(self.spawnPoint - Vector(0, math.sin(piFraction) * kMoveOffset, 0))
    
    end

end

function BoneWall:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function BoneWall:GetIsFlameAble()
    return true
end

Shared.LinkClassToMap("BoneWall", BoneWall.kMapName, networkVars)