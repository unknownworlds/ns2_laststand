// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Tunnel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Tunnel entity, connection between 2 gorge tunnel entrances!
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TunnelProp.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/MinimapConnectionMixin.lua")

kTunnelExitSide = enum({'A', 'B'})

class 'Tunnel' (Entity)

local kTunnelLoopingSound = PrecacheAsset("sound/NS2.fev/alien/structures/tunnel/loop")
local kTunnelCinematic = PrecacheAsset("cinematics/alien/tunnel/tunnel_ambient.cinematic")

local kTunnelLightA = PrecacheAsset("cinematics/alien/tunnel/tunnel_ambient_a.cinematic")
local kTunnelLightB = PrecacheAsset("cinematics/alien/tunnel/tunnel_ambient_b.cinematic")

local gNumTunnels = 0

local kTunnelSpacing = Vector(160, 0, 0)
local kTunnelStart = Vector(-1600, 200, -1600)

local kTunnelLength = 27

local kEntranceAPos = Vector(3, 0.5, -11)
local kEntranceBPos = Vector(3, 0.5, 11)

local kExitAPos = Vector(3.75, 0.15, -15)
local kExitBPos = Vector(3.75, 0.15, 15)

Tunnel.kModelName = PrecacheAsset("models/alien/tunnel/tunnel.model")
local kAnimationGraph = PrecacheAsset("models/alien/tunnel/tunnel.animation_graph")

local kTunnelPropAttachPoints =
{
    { "Tunnel_attachPointCeiling_00", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_02", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_03", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_04", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_05", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_06", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_07", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_08", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_09", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_10", kTunnelPropType.Ceiling },
    { "Tunnel_attachPointCeiling_11", kTunnelPropType.Ceiling },
    
    { "Tunnel_attachPointGrnd_00", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_01", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_02", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_03", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_04", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_05", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_06", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_07", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_08", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_09", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_10", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_11", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_12", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_13", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_14", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_15", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_16", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_17", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_18", kTunnelPropType.Floor },
    { "Tunnel_attachPointGrnd_19", kTunnelPropType.Floor }, 
}

local networkVars =
{
    exitAConnected = "boolean",
    exitBConnected = "boolean",
    exitAEntityPosition = "vector",
    exitBEntityPosition = "vector",
    exitAUsed = "boolean",
    exitBUsed = "boolean",
    flinchAAmount = "float (0 to 1 by 0.05)",
    flinchBAmount = "float (0 to 1 by 0.05)"    
}

Tunnel.kMapName = "tunnel"

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

local function CreateEntranceLight()

    local entranceLight = Client.CreateRenderLight()
    entranceLight:SetType( RenderLight.Type_Point )
    entranceLight:SetColor( Color(1, .7, .2) )
    entranceLight:SetIntensity( 3 )
    entranceLight:SetRadius( 10 ) 
    entranceLight:SetIsVisible(false)
    
    return entranceLight

end

function Tunnel:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    
    if Server then
    
        gNumTunnels = gNumTunnels + 1
        
        InitMixin(self, EntityChangeMixin)
        
        self.exitAId = Entity.invalidId
        self.exitBId = Entity.invalidId
        
        self.exitAConnected = false
        self.exitBConnected = false
        
        self:SetPropagate(Entity.Propagate_Mask)
        self:SetRelevancyDistance(kMaxRelevancyDistance)
        
        self.collapsing = false
        
        self.loopingSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingSound:SetAsset(kTunnelLoopingSound)
        self.loopingSound:SetParent(self)
        
        self.timeExitAUsed = 0
        self.timeExitBUsed = 0
        
        self.flinchAAmount = 0
        self.flinchBAmount = 0
    
    end
    
    self:SetUpdates(true)

end

local function CreateRandomTunnelProps(self)

    for i = 1, #kTunnelPropAttachPoints do
    
        local attachPointEntry = kTunnelPropAttachPoints[i]
        local attachPointPosition = self:GetAttachPointOrigin(attachPointEntry[1])
        
        if attachPointPosition then
        
            local tunnelProp = CreateEntity(TunnelProp.kMapName, attachPointPosition)
            tunnelProp:SetParent(self)
            tunnelProp:SetTunnelPropType(attachPointEntry[2], math.max(0, i - 12))
            tunnelProp:SetAttachPoint(attachPointEntry[1])
            
        end
    
    end

end

function Tunnel:OnInitialized()

    self:SetModel(Tunnel.kModelName, kAnimationGraph)

    if Server then    
    
        self:SetOrigin(gNumTunnels * kTunnelSpacing + kTunnelStart)
        CreateRandomTunnelProps(self)
        
        InitMixin(self, MinimapConnectionMixin)
        self.loopingSound:Start()
        
        self:SetPhysicsType(PhysicsType.Kinematic)
      
    elseif Client then
    
        self.tunnelLightCinematicA = Client.CreateCinematic(RenderScene.Zone_Default)
        self.tunnelLightCinematicA:SetCinematic(kTunnelLightA)
        self.tunnelLightCinematicA:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.tunnelLightCinematicA:SetCoords(self:GetCoords())        
        self.tunnelLightCinematicA:SetIsVisible(self.exitAConnected)
        
        self.tunnelLightCinematicB = Client.CreateCinematic(RenderScene.Zone_Default)
        self.tunnelLightCinematicB:SetCinematic(kTunnelLightB)
        self.tunnelLightCinematicB:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.tunnelLightCinematicB:SetCoords(self:GetCoords())        
        self.tunnelLightCinematicB:SetIsVisible(self.exitAConnected)
        
        self.tunnelCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.tunnelCinematic:SetCinematic(kTunnelCinematic)
        self.tunnelCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.tunnelCinematic:SetCoords(self:GetCoords())
        /*
        self.tunnelReverb = Reverb()
        self.tunnelReverb:SetOrigin(self:GetOrigin())
        self.tunnelReverb.minRadius = 27
        self.tunnelReverb.maxRadius = 30
        self.tunnelReverb.reverbType = kReverbNames.hallway
        self.tunnelReverb:OnLoad()
        */
    end

end

function Tunnel:OnDestroy()

    Entity.OnDestroy(self)
    
    if Server then 
   
        gNumTunnels = gNumTunnels - 1    
        self.loopingSound = nil
        
    elseif Client then 
        
        if self.tunnelLightCinematicA then            
            Client.DestroyCinematic(self.tunnelLightCinematicA)
            self.tunnelLightCinematicA = nil            
        end
        if self.tunnelLightCinematicB then            
            Client.DestroyCinematic(self.tunnelLightCinematicB)
            self.tunnelLightCinematicB = nil            
        end
        if self.tunnelCinematic then            
            Client.DestroyCinematic(self.tunnelCinematic)
            self.tunnelCinematic = nil            
        end

    end 

end

if Server then
    
    function Tunnel:SetExits(exitA, exitB)
    
        assert(exitA)
        assert(exitB)
        
        self.exitAId = exitA:GetId()
        self.exitAEntityPosition = exitA:GetOrigin()
        self.timeExitAChanged = Shared.GetTime()

        self.exitBId = exitB:GetId()
        self.exitBEntityPosition = exitB:GetOrigin()
        self.timeExitBChanged = Shared.GetTime()
    
    end
 
    function Tunnel:GetConnectionStartPoint()
    
        if self.exitAConnected then
            return self.exitAEntityPosition
        end
        
    end
 
    function Tunnel:GetConnectionEndPoint()
    
        if self.exitBConnected then
            return self.exitBEntityPosition
        end
        
    end
 
    function Tunnel:AddExit(exit)
    
        assert(exit)
        
        if self.exitAId == Entity.invalidId then
        
            self.exitAId = exit:GetId()
            self.exitAEntityPosition = exit:GetOrigin()
            self.timeExitAChanged = Shared.GetTime()
            
            if self.exitBId == Entity.invalidId then
                self.exitBEntityPosition = Vector(self.exitAEntityPosition)
            end
        
        elseif self.exitBId == Entity.invalidId then
        
            self.exitBId = exit:GetId()
            self.exitBEntityPosition = exit:GetOrigin()
            self.timeExitBChanged = Shared.GetTime()
            
            if self.exitAId == Entity.invalidId then
                self.exitAEntityPosition = Vector(self.exitBEntityPosition)
            end
        
        else
        
            if self.timeExitAChanged < self.timeExitBChanged then
            
                self.exitAId = exit:GetId()
                self.timeExitAChanged = Shared.GetTime()
            
            else
            
                self.exitBId = exit:GetId()
                self.timeExitBChanged = Shared.GetTime()
            
            end
        
        end
    
    end

    local function GetUnitsInTunnel(self)        
        return GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), (kTunnelLength + 1))        
    end
    
    local function DestroyAllUnitsInside(self)
    
        for _, unit in ipairs(GetUnitsInTunnel(self)) do
        
            if HasMixin(unit, "Live") then
                unit:Kill()
            else
                DestroyEntity(unit)
            end
        
        end
    
    end
    
    function Tunnel:OnEntityChange(oldId)
    
        if self.exitAId == oldId then
            self.exitAId = Entity.invalidId
            self.exitAEntityPosition = Vector(self.exitBEntityPosition)
        end
        
        if self.exitBId == oldId then
            self.exitBId = Entity.invalidId
            self.exitBEntityPosition = Vector(self.exitAEntityPosition)
        end
    
    end
    
    local kExitRadius = 4
    local kExitOffset = Vector(0, 0.2, 0)
    
    function Tunnel:UseExit(entity, exit, exitSide)
    
        entity:SetOrigin(exit:GetOrigin() + kExitOffset)

        if entity:isa("Player") then
        
            local newAngles = entity:GetViewAngles()
            newAngles.pitch = 0
            newAngles.roll = 0
            newAngles.yaw = newAngles.yaw + self:GetMinimapYawOffset()
            entity:SetOffsetAngles(newAngles)
            
        end    

        exit:OnEntityExited(entity)
        
        if entity.OnUseGorgeTunnel then
            entity:OnUseGorgeTunnel()
        end
        
        if entity.TriggerEffects then
            entity:TriggerEffects("tunnel_exit_3D")
        end
        
        if exitSide == kTunnelExitSide.A then
            self.timeExitAUsed = Shared.GetTime()
        elseif exitSide == kTunnelExitSide.B then
            self.timeExitBUsed = Shared.GetTime()
        end
        
    end
    
    function Tunnel:TriggerCollapse()
        self.collapsing = true
    end
    
    function Tunnel:GetExitA()
        return self.exitAId ~= Entity.invalidId and Shared.GetEntity(self.exitAId)
    end
    
    function Tunnel:GetExitB()
        return self.exitBId ~= Entity.invalidId and Shared.GetEntity(self.exitBId)
    end
    
    function Tunnel:UpdateFlinchAmount()

        local exitA = self:GetExitA()
        local exitB = self:GetExitB()
        
        self.flinchAAmount = exitA and exitA:GetFlinchIntensity() or 0
        self.flinchBAmount = exitB and exitB:GetFlinchIntensity() or 0

    end
    
    function Tunnel:OnUpdate(deltaTime)
    
        local exitA = self:GetExitA()
        local exitB = self:GetExitB()

        self.exitAConnected = exitA and exitA:GetIsAlive()
        self.exitBConnected = exitB and exitB:GetIsAlive()
        self.exitAUsed = self.timeExitAUsed + 0.2 > Shared.GetTime()
        self.exitBUsed = self.timeExitBUsed + 0.2 > Shared.GetTime()
        
        if exitA then
            exitA.allowDigest = self.exitAConnected and self.exitBConnected
        end
        
        if exitB then
            exitB.allowDigest = self.exitAConnected and self.exitBConnected
        end

        // collapse when no exist has been found. free clientId for possible reuse later
        if not self.exitAConnected and not self.exitBConnected then
        
            DestroyAllUnitsInside(self)
            self.ownerClientId = nil
            
            self.collapsing = true
        
        end
        
        self:UpdateFlinchAmount()
        
    end
    
    function Tunnel:GetOwnerClientId()
        return self.ownerClientId
    end
    
    function Tunnel:SetOwnerClientId(clientId)
        self.ownerClientId = clientId
    end
    
    function Tunnel:MovePlayerToTunnel(player, entrance)
    
        assert(player)
        assert(entrance)
        
        local entranceId = entrance:GetId()
        
        local newAngles = player:GetViewAngles()
        newAngles.pitch = 0
        newAngles.roll = 0
        
        if entranceId == self.exitAId then
        
            player:SetOrigin(self:GetEntranceAPosition())
            newAngles.yaw = GetYawFromVector(self:GetCoords().zAxis)
            player:SetOffsetAngles(newAngles)
            player:TriggerEffects("tunnel_enter_3D")
            self.timeExitAUsed = Shared.GetTime()       
            
        elseif entranceId == self.exitBId then
        
            player:SetOrigin(self:GetEntranceBPosition())
            newAngles.yaw = GetYawFromVector(-self:GetCoords().zAxis)
            player:SetOffsetAngles(newAngles)
            player:TriggerEffects("tunnel_enter_3D")  
            self.timeExitBUsed = Shared.GetTime()
            
        end
    
    end

else
    // Predict or Client
    
    function Tunnel:OnUpdateRender()
    
        self.tunnelLightCinematicA:SetIsVisible(self.exitAConnected)
        self.tunnelLightCinematicB:SetIsVisible(self.exitBConnected)
    
    end

end

function Tunnel:GetExitAPosition()
    return self:GetOrigin() + self:GetCoords():TransformVector(kExitAPos)
end

function Tunnel:GetExitBPosition()
    return self:GetOrigin() + self:GetCoords():TransformVector(kExitBPos)
end

function Tunnel:GetEntranceAPosition()
    return self:GetOrigin() + self:GetCoords():TransformVector(kEntranceAPos)
end

function Tunnel:GetEntranceBPosition()
    return self:GetOrigin() +  self:GetCoords():TransformVector(kEntranceBPos)
end

function Tunnel:GetRelativePosition(position)

    local fractionPos = ( (-self:GetCoords().zAxis):DotProduct( self:GetOrigin() - position ) + kTunnelLength *.5) / kTunnelLength
    return (self.exitBEntityPosition - self.exitAEntityPosition) * fractionPos + self.exitAEntityPosition

end

function Tunnel:GetMinimapYawOffset()

    if self.exitAEntityPosition == self.exitBEntityPosition then
        return 0
    end

    local tunnelDirection = GetNormalizedVector( self.exitBEntityPosition - self.exitAEntityPosition )
    return math.atan2(tunnelDirection.x, tunnelDirection.z)

end

function Tunnel:OnUpdatePoseParameters()

    self:SetPoseParam("intensity_yn", self.flinchAAmount)
    self:SetPoseParam("intensity_yp", self.flinchBAmount)

end

function Tunnel:OnUpdateAnimationInput(modelMixin)

    PROFILE("Tunnel:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("entrance_A_opened", self.exitAConnected)
    modelMixin:SetAnimationInput("entrance_B_opened", self.exitBConnected)
    
    modelMixin:SetAnimationInput("exit_A", self.exitAUsed)
    modelMixin:SetAnimationInput("exit_B", self.exitBUsed)
    
end    

Shared.LinkClassToMap("Tunnel", Tunnel.kMapName, networkVars)