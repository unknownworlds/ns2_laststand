// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\RepositioningMixin.lua    
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// This mixin tries to reposition AI units to prevent stacking. It's not guaranteed since it
// tries to be as cheap as possible. It works parallel to any move orders since the repositioning
// process stops after a time limit to prevent "ai stucked" units (repositioning + moving could
// interfere with each other). The reposition process is triggered once a move order is proccessed, completed, and
// the triggering entity causes surrounding entities to move away. GetShouldRepositionDuringMove will
// disable constant checks during movement.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

RepositioningMixin = CreateMixin( RepositioningMixin )
RepositioningMixin.type = "Repositioning"

// Most units have a smaller radius than 0.5, for them we have a small gap between as a result
local kRepositiongDistance = 1.2
// in case the deltaTime of OnUpdate gets bigger than expected
local kToleranzDistance = 0.15
local kRepositioningSpeed = 3
local kRepositioningTime = 0.7
local kPositionCheckIntervall = 0.8
local kDefaultExtents = Vector(0.25, 0.25, 0.25)

local kGroupOrderCompleteRange = 6

RepositioningMixin.expectedCallbacks =
{
    GetCanReposition = "Should be true if repositioning is allowed",
}

RepositioningMixin.optionalCallbacks =
{
    OverrideRepositioningSpeed = "Defines custom repositioning speed.",
    OverrideRepositioningDistance = "Defines custom repositioning distance.",
    GetShouldRepositionDuringMove = "Default true, false will prevent updating during moving.",
    OverrideGetRepositioningTime = "Return custom duration for repositioning."
}

function RepositioningMixin:__initmixin()
    
    self.shouldReposition = false
    self.isRepositioning = false
    self.timeLeftForReposition = 0
    self.targetPos = nil
    self.initialSpaceChecked = false
    
end

function RepositioningMixin:GetRepositioningTime()

    if self.OverrideGetRepositioningTime then
        return self:OverrideGetRepositioningTime()
    end
    
    return kRepositioningTime

end

function RepositioningMixin:GetRepositioningSpeed()

    if self.OverrideRepositioningSpeed then
        return self:OverrideRepositioningSpeed()
    end
   
   return kRepositioningSpeed
    
end

function RepositioningMixin:GetRepositioningDistance()

    if self.OverrideRepositioningDistance then
        return self:OverrideRepositioningDistance()
    end
   
   return kRepositiongDistance
    
end

function RepositioningMixin:_AdjustRepositioningHeight()

    local positionOffset = Vector(0, 0, 0)
    
    if self.GetIsFlying and self:GetIsFlying() then
        positionOffset.y = self:GetHoverHeight()
    end
    
    // find correct height
    local startPointGround = self:GetOrigin() + Vector(0, 0.4, 0)
    local endPointGround = self:GetOrigin() - Vector(0, 1.5, 0) - positionOffset * 2
    
    // check for techpoint to not fall through the map
    local trace = Shared.TraceRay(startPointGround, endPointGround, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterMixinAndSelf(self, "Repositioning"))
    
    if trace.entity == nil or not trace.entity:isa("TechPoint") then
    
        local traceGround = Shared.TraceRay(startPointGround, endPointGround, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterMixinAndSelf(self, "Repositioning"))
        
        if endPointGround ~= traceGround.endPoint then
            self:SetOrigin(traceGround.endPoint + positionOffset)
        end
        
        if traceGround.entity and HasMixin(traceGround.entity, Repositioning) then
            traceGround.entity:FindBetterPosition(0, 0, 0)
        end
        
    end
    
end

function RepositioningMixin:GetIsRepositioning()
    return self.isRepositioning
end    

function RepositioningMixin:ToggleRepositioning()

    self.initialSpaceChecked = true

    if self.isRepositioning then
        return false
    end
    
    local entitiesInRange = GetEntitiesWithMixinForTeamWithinRange("Repositioning", self:GetTeamNumber(), self:GetOrigin(), self:GetRepositioningDistance())
    local count = table.count(entitiesInRange)
    local success = false
    local baseYaw = 0

    for i, entity in ipairs(entitiesInRange) do
    
        if entity:GetCanReposition() and entity ~= self then
        
            entity.isRepositioning = true
            entity.timeLeftForReposition = self:GetRepositioningTime()
            
            baseYaw = entity:FindBetterPosition( GetYawFromVector(entity:GetOrigin() - self:GetOrigin()), baseYaw, 0 )
            
            if entity.RemoveFromMesh ~= nil then
                entity:RemoveFromMesh()
            end
        end
    
    end
    
    return true
    
end

function RepositioningMixin:FindBetterPosition(yaw, baseYaw, calls)

    // limit recursion depth by 3 calls, otherwise we could have some big problems...
    if calls > 2 then
        return baseYaw
    end
    
    self:_AdjustRepositioningHeight()
    
    local angles = self:GetAngles()
    angles.yaw = yaw + baseYaw
    
    local coords = angles:GetCoords(self:GetOrigin())
    local startPoint = self:GetOrigin()
    local endPoint = startPoint + coords.zAxis * 10
    
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterMixinAndSelf(self, "Repositioning"))
    
    local validPos = false
    
    if trace.fraction ~= 1 then
        endPoint = trace.endPoint + coords.zAxis * -0.5
    end
    
    if (endPoint - startPoint):GetLength() >= self:GetRepositioningDistance() then
        endPoint = startPoint + coords.zAxis * self:GetRepositioningDistance()
        validPos = true
    end
    
    if validPos then
        validPos = Pathing.GetIsFlagSet(endPoint, kDefaultExtents, Pathing.PolyFlag_Walk)
    end
    
    if validPos then
        self.targetPos = endPoint
    else
        baseYaw = self:FindBetterPosition(yaw, baseYaw + math.pi/2, calls + 1)
    end
    
    return baseYaw

end

function RepositioningMixin:PerformRepositioning(deltaTime)

    if self.targetPos ~= nil then
    
        local direction = self.targetPos - self:GetOrigin()
        self.timeLeftForReposition = Clamp(self.timeLeftForReposition - deltaTime, 0, self:GetRepositioningTime())
        
        if direction:GetLength() < kToleranzDistance then
        
            if HasMixin(self, "Pathing") then
                self:SetCurrentPositionValid(self.targetPos)
            end
        
            self.isRepositioning = false
            self.targetPos = nil
            self:_AdjustRepositioningHeight()
            self:ToggleRepositioning()
            
            if self.AddToMesh ~= nil then
                self:AddToMesh()
            end
            
            return
            
        end
        
        // in the case we are out of time we simply failed, it could be too risky to trigger repositioning
        if self.timeLeftForReposition <= 0 then     
            
            if HasMixin(self, "Pathing") then
                self:SetCurrentPositionValid(self.targetPos)
            end
            
            self.isRepositioning = false
            self.targetPos = nil
            self:_AdjustRepositioningHeight()
            
            return
            
        end
        
        direction:Normalize()
        local newOrigin = self:GetOrigin() + (deltaTime * self:GetRepositioningSpeed()) * direction
        
        if Pathing.GetIsFlagSet(newOrigin, kDefaultExtents, Pathing.PolyFlag_Walk) then        
            self:SetOrigin(newOrigin)
        end
    
    else
        self.isRepositioning = false
    end

end

function RepositioningMixin:_GetShouldCheckPosition()

    if (self.timeLastPositionCheck == nil) or (self.timeLastPositionCheck + kPositionCheckIntervall < Shared.GetTime()) then
    
        self.timeLastPositionCheck = Shared.GetTime()
        return true
    
    end
    
    return not self.initialSpaceChecked

end

function RepositioningMixin:OnUpdate(deltaTime)

    if self.isRepositioning then
    
        self:PerformRepositioning(deltaTime)
        
    elseif HasMixin(self, "Orders") and (self:GetHasOrder() or not self.initialSpaceChecked) then
        
        //self:_AdjustRepositioningHeight()
        
        if self:_GetShouldCheckPosition() then
        
            if self.GetShouldRepositionDuringMove and not self:GetShouldRepositionDuringMove() then
                return
            end
            
            self:ToggleRepositioning()
            
        end
        
    end

end

function RepositioningMixin:OnOrderComplete(currentOrder)

    if HasMixin(self, "Orders") then
        /* disabled, here is not the right place for group orders
        if(currentOrder:GetType() == kTechId.Move) then

            local entitiesInRange = GetEntitiesWithMixinForTeamWithinRange("Repositioning", self:GetTeamNumber(), self:GetOrigin(), kGroupOrderCompleteRange)
            
            for index, entity in ipairs(entitiesInRange) do
            
                if HasMixin(entity, "Orders") and entity ~= self then
                
                    local entityOrder = entity:GetCurrentOrder()
                    if entityOrder and entityOrder:GetType() == kTechId.Move and currentOrder:GetLocation() == entityOrder:GetLocation() then
                        entity:ClearOrders()
                    end
                
                end
            
            end
        
        end
        */
    
	    if currentOrder then
	        self:ToggleRepositioning()
	    end
    end

end