// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TunnelProp.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")

kTunnelPropType = enum({'Ceiling', 'Floor'})

class 'TunnelProp' (Entity)

TunnelProp.kMapName = "tunnelprop"
local kAnimationGraph = PrecacheAsset("models/alien/tunnel/tunnel_prop.animation_graph")

local networkVars = 
{
    attachPointNum = "integer (0 to 19)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

local kPropModels =
{
    [kTunnelPropType.Ceiling] = {
        PrecacheAsset("models/alien/tunnel/tunnel_attch_topTent.model"),
    },
    
    [kTunnelPropType.Floor] = {
        PrecacheAsset("models/alien/tunnel/tunnel_attch_botTents.model"),
        PrecacheAsset("models/alien/tunnel/tunnel_attch_growth.model"),
        PrecacheAsset("models/alien/tunnel/tunnel_attch_polyps.model"),
        PrecacheAsset("models/alien/tunnel/tunnel_attch_bulb.model"),
    }
}

local kPropAnimGraphs = {}
kPropAnimGraphs["models/alien/tunnel/tunnel_attch_topTent.model"] = PrecacheAsset("models/alien/tunnel/tunnel_attch_topTent.animation_graph")
kPropAnimGraphs["models/alien/tunnel/tunnel_attch_botTents.model"] = PrecacheAsset("models/alien/tunnel/tunnel_attch_botTents.animation_graph")
kPropAnimGraphs["models/alien/tunnel/tunnel_attch_bulb.model"] = PrecacheAsset("models/alien/tunnel/tunnel_attch_bulb.animation_graph")
kPropAnimGraphs["models/alien/tunnel/tunnel_attch_growth.model"] = PrecacheAsset("models/alien/tunnel/tunnel_attch_growth.animation_graph")
kPropAnimGraphs["models/alien/tunnel/tunnel_attch_polyps.model"] = PrecacheAsset("models/alien/tunnel/tunnel_attch_polyps.animation_graph")

local function GetRandomPropModel(propType)

    local propModels = kPropModels[propType]
    local numModels = #propModels
    local randomIndex = math.random(1, numModels)
    
    return propModels[randomIndex]

end

function TunnelProp:OnCreate()

    self.attachPointNum = 0

    Entity.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    
    self:SetUpdates(true)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)

end

function TunnelProp:OnDestroy()

    Entity.OnDestroy(self)

end

function TunnelProp:SetTunnelPropType(propType, attachPointNum)

    if Server then

        local randomModel = GetRandomPropModel(propType)
        self:SetModel(randomModel, kPropAnimGraphs[randomModel])
        
        self.attachPointNum = attachPointNum
        
    end

end

function TunnelProp:OnUpdateAnimationInput(modelMixin)

    PROFILE("TunnelProp:OnUpdateAnimationInput")
    
    local pose = ToString(self.attachPointNum)
    if string.len(pose) == 1 then
        pose = "0" .. pose
    end
    
    modelMixin:SetAnimationInput("pose", "GAP" .. pose)

end

Shared.LinkClassToMap("TunnelProp", TunnelProp.kMapName, networkVars)
