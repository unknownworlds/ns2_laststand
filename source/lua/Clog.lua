// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Clog.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/ClogFallMixin.lua")
Script.Load("lua/DigestMixin.lua")
Script.Load("lua/TechMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/UsableMixin.lua")
Script.Load("lua/Mixins/SimplePhysicsMixin.lua")

local Shared_GetModel = Shared.GetModel

class 'Clog' (Entity)

Clog.kMapName = "clog"

Clog.kModelName = PrecacheAsset("models/alien/gorge/goowallnode.model")

local networkVars = { }

Clog.kRadius = 0.67

// clogs take maximum X damage per attack (prevents grenades being too effectfive against them), unless the attack is not a of type Flame)
Clog.kMaxShockDamage = 50

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)

function Clog:OnCreate()

    Entity.OnCreate(self)
    
    self.boneCoords = CoordsArray()
    
    InitMixin(self, EffectsMixin)
    InitMixin(self, TechMixin) 
    InitMixin(self, TeamMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, TargetMixin)
    InitMixin(self, DigestMixin)
    InitMixin(self, UsableMixin)
    
    if Server then
    
        InitMixin(self, InvalidOriginMixin)
        InitMixin(self, OwnerMixin)
        InitMixin(self, ClogFallMixin)
        InitMixin(self, EntityChangeMixin)       

    end
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kMaxRelevancyDistance)
    self:SetUpdates(true)
    
end

function Clog:OnInitialized()

    InitMixin(self, SimplePhysicsMixin)
    
    if Server then
    
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        
        if sighted or self:GetTeamNumber() == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander)              
        elseif self:GetTeamNumber() == 2 then        
            mask = bit.bor(mask, kRelevantToTeam2Commander)        
        end  
        
        self:SetExcludeRelevancyMask( mask )
    
    end

end

function Clog:GetSimplePhysicsBodyType()
    return kSimplePhysicsBodyType.Sphere
end

function Clog:GetSimplePhysicsBodySize()
    return Clog.kRadius
end

function Clog:OnDestroy()

    if self._renderModel ~= nil then
    
        Client.DestroyRenderModel(self._renderModel)
        self._renderModel = nil
        
    end

end

function Clog:SpaceClearForEntity(location)
    return true
end

function Clog:GetIsFlameAble()
    return true
end

function Clog:GetShowCrossHairText(toPlayer)
    return false
end

function Clog:GetCanBeHealedOverride()
    return false
end

function Clog:SetCoords(coords)

    if self._renderModel then    
        self._renderModel:SetCoords(coords)        
    end
    
    Entity.SetCoords(self, coords)

end

function Clog:SetOrigin(origin)

    local newCoords = self:GetCoords()
    newCoords.origin = origin

    if self._renderModel then    
        self._renderModel:SetCoords(newCoords)        
    end
    
    Entity.SetOrigin(self, origin)

end

function Clog:GetModelOrigin()
    return self:GetOrigin()    
end

if Server then

    function Clog:OnKill()
    
        self:TriggerEffects("death")
        DestroyEntity(self)
        
    end
    
    function Clog:GetSendDeathMessageOverride()
        return false
    end
    
    function Clog:OnCreatedByGorge(gorge)
    
        self:TriggerEffects("spawn", {effecthostcoords = self:GetCoords()})
        self:TriggerEffects("clog_slime")
    
    end

elseif Client then

    function Clog:GetShowHealthFor()
        return false
    end
    
    function Clog:OnUpdateRender()
    
        PROFILE("Clog:OnUpdateRender")
    
        if self._renderModel then
            self._renderModel:SetCoords(self:GetCoords())            
            //DebugCapsule(self:GetOrigin(), self:GetOrigin(), Clog.kRadius, 0, 0.03)
        else
            self._renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            self._renderModel:SetModel(Shared.GetModelIndex(Clog.kModelName))
            self._renderModel:SetCoords(self:GetCoords())  
        end
    
    end

end

function Clog:GetEffectParams(tableParams)

    // Only override if not specified    
    if not tableParams[kEffectFilterClassName] and self.GetClassName then
        tableParams[kEffectFilterClassName] = self:GetClassName()
    end
    
    if not tableParams[kEffectHostCoords] and self.GetCoords then
        tableParams[kEffectHostCoords] = Coords.GetTranslation( self:GetOrigin() )
    end
    
end

// simple solution for now to avoid griefing
function Clog:GetCanDigest(player)
    return player:GetIsAlive() and player:GetTeamNumber() == self:GetTeamNumber()
end

function Clog:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = player:GetTeamNumber() == self:GetTeamNumber()
end

function Clog:GetUsablePoints()
    return { self:GetOrigin() }
end

function Clog:ComputeDamageOverride(attacker, damage, damageType, time)

    if damageType ~= kDamageType.Flame and damage >= Clog.kMaxShockDamage then
        self:TriggerEffects("spawn", {effecthostcoords = self:GetCoords()})
        damage = Clog.kMaxShockDamage
    end

    return damage

end

Shared.LinkClassToMap("Clog", Clog.kMapName, networkVars)