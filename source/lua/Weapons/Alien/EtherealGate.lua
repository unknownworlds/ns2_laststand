// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\EtherealGate.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)  
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'EtherealGate' (ScriptActor)

Script.Load("lua/EntityChangeMixin.lua")

EtherealGate.kMapName = "etherealgate"

local kLifeTime = 4
local kGrowDuration = 1
local kRange = 4
local kThinkTime = 0.2

local networkVars = { }

local kVortexLoopingSound = PrecacheAsset("sound/NS2.fev/alien/fade/vortex_loop")
local kVortexLoopingCinematic = PrecacheAsset("cinematics/alien/fade/vortex.cinematic")

function EtherealGate:OnCreate()

    self.creationTime = Shared.GetTime()

    ScriptActor.OnCreate(self)

    if Server then
    
        self:AddTimedCallback(EtherealGate.TimeUp, kLifeTime)
        self:AddTimedCallback(EtherealGate.SuckIntoNether, kThinkTime)

        self.loopingVortexSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingVortexSound:SetAsset(kVortexLoopingSound)
        self.loopingVortexSound:SetParent(self)
        
        self.vortexedEntities = {}
        InitMixin(self, EntityChangeMixin)
        
    end

end

function EtherealGate:OnInitialized()

    if Server then   
 
        self.loopingVortexSound:Start()
        self:TriggerEffects("spawn")
        
    elseif Client then
  
        if not self.vortexCinematic then
        
            self.vortexCinematic = Client.CreateCinematic(RenderScene.Zone_Default)    
            self.vortexCinematic:SetCinematic(kVortexLoopingCinematic)    
            self.vortexCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.vortexCinematic:SetCoords(self:GetCoords())
            
        end
        
    end    

end 

function EtherealGate:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Server then
    
        self.loopingVortexSound = nil
        self:FreeAllVortexed()
        
    elseif Client then
    
        self:TriggerEffects("vortex_destroy")
        
        if self.vortexCinematic then
        
            Client.DestroyCinematic(self.vortexCinematic)
            self.vortexCinematic = nil
            
        end
        
    end

end

function EtherealGate:OnEntityChange(oldId, newId)

    if oldId and table.removevalue(self.vortexedEntities, oldId) and newId then
        table.insertunique(self.vortexedEntities, newId)
    end
    
end

function EtherealGate:FreeAllVortexed()

    for _, vortexedId in ipairs(self.vortexedEntities) do
    
        local vortexedEnt = Shared.GetEntity(vortexedId)
        if vortexedEnt and HasMixin(vortexedEnt, "VortexAble") then
            vortexedEnt:FreeVortexed()
        end
    
    end

end

function EtherealGate:SuckIntoNether()

    local remainingLifeTime = math.max(0, kLifeTime - (Shared.GetTime() - self.creationTime))

    if remainingLifeTime == 0 then
        return false
    end
    
    local range = (math.min(kGrowDuration, Shared.GetTime() - self.creationTime) / kGrowDuration) * kRange

    local vortexAbles = GetEntitiesWithMixinWithinRange("VortexAble", self:GetOrigin(), range)
    
    for _, vortexAble in ipairs(vortexAbles) do
    
        if not vortexAble:GetIsVortexed() and (not HasMixin(vortexAble, "NanoShieldAble") or not vortexAble:GetIsNanoShielded()) then
        
            vortexAble:SetVortexDuration(remainingLifeTime)            
            table.insertunique(self.vortexedEntities, vortexAble:GetId())
        
        end
        
    end
    
    return true

end

function EtherealGate:TimeUp()
    
    DestroyEntity(self)
    return false
    
end

Shared.LinkClassToMap("EtherealGate", EtherealGate.kMapName, networkVars)