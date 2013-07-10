// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TargetMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =======================

Script.Load("lua/FunctionContracts.lua")

TargetMixin = CreateMixin(TargetMixin)
TargetMixin.type = "Target"

local kEngagementPointDefaultOffset = Vector(0, 0.2, 0)

TargetMixin.optionalCallbacks = 
{
    GetEngagementPointOverride = "Return custom engagement point."
}

function TargetMixin:__initmixin()
end

function TargetMixin:GetEngagementPoint()

    if self.lastEngagementPointOrigin ~= self:GetOrigin() then
    
        if self.GetEngagementPointOverride then
            self.cachedEngagementPoint = self:GetEngagementPointOverride()
        elseif HasMixin(self, "Model") and self:GetHasModel() then
        
            local success = false
            self.cachedEngagementPoint, success = self:GetAttachPointOrigin("target")
            if not success then
                self.cachedEngagementPoint = self:GetModelOrigin()
            end
            
        else
            self.cachedEngagementPoint = self:GetOrigin() + kEngagementPointDefaultOffset
        end
        
        self.lastEngagementPointOrigin = self:GetOrigin()
        
    end
    
    return self.cachedEngagementPoint
    
end