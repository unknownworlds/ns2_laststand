// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CragBabblers.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Protects friendly units from bullets.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")

Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")

class 'CragBabblers' (CommanderAbility)

CragBabblers.kMapName = "cragbabblers"

CragBabblers.kCragBabblersEffect = PrecacheAsset("cinematics/alien/Crag/babbler.cinematic")
CragBabblers.kModelName = PrecacheAsset("models/alien/crag/cragbabblers.model")

CragBabblers.kType = CommanderAbility.kType.Repeat

// duration of cinematic, increase cinematic duration and kCragBabblersDuration to 12 to match the old value from Crag.lua
CragBabblers.kCragBabblersDuration = 40
CragBabblers.kSpotRange = 20

CragBabblers.kNumBabblers = 5
CragBabblers.kThinkTime = 2

local networkVars =
{
}

AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)

function CragBabblers:OnCreate()

    CommanderAbility.OnCreate(self)
    
    self.controller = Shared.CreateCollisionObject(self)
    self.controller:SetGroup(PhysicsGroup.BabblerGroup)
    self.controller:SetTriggeringEnabled(true)
    self.controller:SetPhysicsType(CollisionObject.Static)
    self.controller:SetGroupFilterMask(PhysicsMask.CommanderSelect)
    
    self.controller:SetupCylinder( 2, 0.3, self.controller:GetCoords(), true )
    
    InitMixin(self, LiveMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, SelectableMixin)
    
    local babblerHealth = LookupTechData(kTechId.Babbler, kTechDataMaxHealth, 100) * CragBabblers.kNumBabblers
    self.maxHealth = babblerHealth
    self.health = babblerHealth
    self.maxArmor = 0
    self.armor = 0

end

if Server then
    
    function CragBabblers:OnInitialized()
    
        CommanderAbility.OnInitialized(self)
        
        self.babblers = {}
        
        for i = 1, CragBabblers.kNumBabblers do

            local randomDirection = Vector(math.random() * 2 - 1, math.random(), math.random() * 2 - 1)
            randomDirection:Normalize()
            randomDirection:Scale(1.5)
            local spawnPos = self:GetOrigin() + Vector(0, .2, 0) + randomDirection
            
            local babbler = CreateEntity(Babbler.kMapName, spawnPos, self:GetTeamNumber())
            table.insert(self.babblers, babbler:GetId())
       
        end
        
        // TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        
        self.targetSelector = TargetSelector():Init(
                self,
                CragBabblers.kSpotRange,
                true, 
                { kAlienStaticTargets, kAlienMobileTargets })
    
    end
    
    function CragBabblers:SetOwner(newOwner)
    
        for index, babblerId in ipairs(self.babblers) do
            local babbler = Shared.GetEntity(babblerId)
            if babbler then
                babbler:SetOwner(newOwner)
            end
        end    
    
    end
    
    function CragBabblers:SetHostCrag(crag)

        for index, babblerId in ipairs(self.babblers) do
            local babbler = Shared.GetEntity(babblerId)
            if babbler then
                Shared.SetPhysicsObjectCollisionsEnabled(babbler.physicsBody, crag.physicsModel, false)
            end
        end 
    
    end
    
    function CragBabblers:SetOrigin(vector)
    
        CommanderAbility.SetOrigin(self, vector)
        if self.controller then
            self.controller:SetPosition(vector)
        end
    
    end
    
    function CragBabblers:OnDestroy()
    
        CommanderAbility.OnDestroy(self)
        
        if self.controller ~= nil then
            Shared.DestroyCollisionObject(self.controller)
            self.controller = nil
        end
        
        for index, babblerId in ipairs(self.babblers) do
        
            local babbler = Shared.GetEntity(babblerId)
            if babbler then
                babbler:Kill()
            end

        end
        
    end
    
    function CragBabblers:OnUpdate(deltaTime)
        
        CommanderAbility.OnUpdate(self, deltaTime)
        
        // update position and health
        local health = 0
        local numPositions = 0
        local posVec = Vector(0,0,0)
        for index, babblerId in ipairs(self.babblers) do
        
            local babbler = Shared.GetEntity(babblerId)
            
            if babbler then
            
                health = health + babbler:GetHealth()
                posVec = posVec + babbler:GetOrigin()
                numPositions = numPositions + 1
                
            end
        
        end
        
        if health == 0 then
            DestroyEntity(self)
        else    
        
            if self.health ~= health then
                self.timeOfLastDamage = Shared.GetTime()
                self.health = health
            end
            
            if numPositions > 0 then
                posVec:Scale(1 / numPositions)
            end
            
            self:SetOrigin(posVec)
        
        end
        
    end

elseif Client then

    function CragBabblers:OnInitialized()

        CommanderAbility.OnInitialized(self)

        if not self.renderModel then
            local modelIndex = Shared.GetModelIndex(CragBabblers.kModelName)
            self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            self.renderModel:SetModel(modelIndex)
        end
        
        self:SetUpdates(true)
        
        //DebugCapsule(self:GetOrigin(), self:GetOrigin(), 1.5, 0, 20)
        
    end

    function CragBabblers:OnDestroy()

        CommanderAbility.OnDestroy(self)
        
        if self.renderModel then
        
            Client.DestroyRenderModel(self.renderModel)
        
        end
        
    end
    
    function CragBabblers:OnUpdate(deltaTime)
    
        local showModel = false
        
        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") and player:GetTeamNumber() == self:GetTeamNumber() then
            showModel = true
        end
        
        self.renderModel:SetIsVisible(showModel)
        self.renderModel:SetCoords(self:GetCoords())
        
        /*
        if not self.timeLastUpdate or self.timeLastUpdate + 0.1 < Shared.GetTime() then
        
            DebugCapsule(self:GetOrigin(), self:GetOrigin(), .5, 0, 0.1)
            self.timeLastUpdate = Shared.GetTime()
        
        end
        */
    
    end

end 

function CragBabblers:GetEyePos()
    return self:GetOrigin() + Vector(0, 0.5, 0)
end    

function CragBabblers:GetFov()
    return 360
end    

function CragBabblers:Perform()

    if Server then
        
        local currentTarget = self:GetTarget() 
        local targetAcquired = nil
        
        local attackEntValid = false
        
        if currentTarget ~= nil then
            attackEntValid = self.targetSelector:ValidateTarget(currentTarget)
        end
        
        if not attackEntValid then
            targetAcquired = self:SetTarget(self.targetSelector:AcquireTarget())                
        end
    
    end

end

function CragBabblers:SetTarget(newTarget)

    // check if we are targeting the same unit so we don't generate 10 orders/sec attacking the same target
    local currentTarget = self:GetTarget()
    if not currentTarget or (newTarget and currentTarget:GetId() ~= newTarget:GetId()) then
    
        if self.targetSelector:ValidateTarget(newTarget) then
        
            for index, babblerId in ipairs(self.babblers) do
            
                local babbler = Shared.GetEntity(babblerId)
                if babbler then
                    babbler:SetTarget(newTarget)
                end
 
            end
        
            self:GiveOrder(kTechId.Attack, newTarget:GetId(), nil)
            return newTarget
            
        end
    
    end
    
    return nil
    
end

function CragBabblers:OnOrderChanged()

    local order = self:GetCurrentOrder()    
    if order and order:GetType() == kTechId.Move then
    
        for index, babblerId in ipairs(self.babblers) do
            local babbler = Shared.GetEntity(babblerId)
            if babbler then
                babbler:SetMoveTarget(order:GetLocation())
            end
        end
    
    end

end

function CragBabblers:GetStartCinematic()
    return CragBabblers.kCragBabblersEffect
end    

function CragBabblers:GetThinkTime()
    return CragBabblers.kThinkTime
end

function CragBabblers:GetType()
    return CragBabblers.kType
end
    
function CragBabblers:GetLifeSpan()
    return CragBabblers.kCragBabblersDuration
end

Shared.LinkClassToMap("CragBabblers", CragBabblers.kMapName, networkVars)