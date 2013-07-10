// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FollowMoveMixin.lua    
//    
//    Created by:   Marc Delorme (marc@unknownworlds.com)
//
//    Move the player stick to anothen entity
//    
// =========== For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")

FollowMoveMixin = CreateMixin(FollowMoveMixin)
FollowMoveMixin.type = "FollowMove"

FollowMoveMixin.networkVars =
{
    followedTargetId = "entityid",
    imposedTargetId  = "entityid",
    followMoveEnabled = "private boolean"
}

FollowMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

FollowMoveMixin.optionalCallbacks =
{
    GetFollowMoveCameraDistance = "Optionally return camera distance."
}

FollowMoveMixin.expectedCallbacks =
{
    SetOrigin = "Set the position of the player",
    SetViewAngles = "Set the view of the player",
    GetIsValidTarget = "Check is the entity can be followed",
    GetTargetsToFollow = "Return a list a target the player can follow"
}

function FollowMoveMixin:__initmixin()

    self.followedTargetId = Entity.invalidId
    self.imposedTargetId = Entity.invalidId
    
    self.followMoveEnabled = true
    
end

function FollowMoveMixin:SetFollowMoveEnabled(enabled)
    self.followMoveEnabled = enabled
end

local function ChangeTarget(self, reverse)

    local targets = self:GetTargetsToFollow()
    local numberOfTargets = table.count(targets)
    local currentTargetIndex = table.find(targets, Shared.GetEntity(self.followedTargetId))
    local nextTargetIndex = currentTargetIndex
    
    if nextTargetIndex and reverse then
        nextTargetIndex = ((nextTargetIndex - 2) % numberOfTargets) + 1
    elseif nextTargetIndex then
        nextTargetIndex = (nextTargetIndex % numberOfTargets) + 1
    else
        nextTargetIndex = 1
    end
    
    if nextTargetIndex <= numberOfTargets then
    
        local cameraDistance = 5
        
        if self.GetFollowMoveCameraDistance then
            cameraDistance = self:GetFollowMoveCameraDistance()
        end
        
        self.followedTargetId = targets[nextTargetIndex]:GetId()
        self:SetDesiredCamera(0.0, { move = true}, targets[nextTargetIndex]:GetOrigin(), nil, cameraDistance)
        
    end
    
end

local function UpdateTarget(self, input)

    assert(Server)
    
    if self.imposedTargetId ~= Entity.invalidId then
    
        if self:GetIsValidTarget(Shared.GetEntity(self.imposedTargetId)) then
            return
        else
            self.imposedTargetId = Entity.invalidId
        end
        
    end
    
    local primaryAttack = bit.band(input.commands, Move.PrimaryAttack) ~= 0
    local secondaryAttack = bit.band(input.commands, Move.SecondaryAttack) ~= 0
    local isTargetValid = self:GetIsValidTarget(Shared.GetEntity(self.followedTargetId))
    local changeTargetAction = primaryAttack or secondaryAttack
    
    // Require another click to change target.
    local changeTarget = (not self.changeTargetAction and changeTargetAction) or not isTargetValid
    self.changeTargetAction = changeTargetAction
    
    if changeTarget and secondaryAttack then
        ChangeTarget(self, true)
    elseif changeTarget then
        ChangeTarget(self, false)
    end
    
end

local function UpdateView(self, input)

    local viewAngles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    local targetId = self.imposedTargetId ~= Entity.invalidId and self.imposedTargetId or self.followedTargetId
    local targetEntity = Shared.GetEntity(targetId)
    local isTargetValid = self:GetIsValidTarget(targetEntity)
    
    if isTargetValid then
        self:SetOrigin(targetEntity:GetOrigin())
    end
    
    self:SetViewAngles(viewAngles)
    
end

function FollowMoveMixin:UpdateMove(input)

    if not self.followMoveEnabled then
        return
    end
    
    if Server then
        UpdateTarget(self, input)
    end
    UpdateView(self, input)
    
end

function FollowMoveMixin:SetFollowTarget(target)

    if target then
        self.imposedTargetId = target:GetId()
    else
        self.imposedTargetId = Entity.invalidId
    end
    
end

function FollowMoveMixin:GetFollowTargetId()
    return self.imposedTargetId ~= Entity.invalidId and self.imposedTargetId or self.followedTargetId
end