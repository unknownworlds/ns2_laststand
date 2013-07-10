// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//    
// lua\TargetCacheMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com) 
//
// Anything that creates TargetSelectors from the TargetCache needs to include this mixin.
// It simply notifies the TargetCache to invalidate all TargetSelectors for this entity
// when it is destroyed.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TargetCacheMixin = CreateMixin( TargetCacheMixin )
TargetCacheMixin.type = "TargetCache"

function TargetCacheMixin:__initmixin()

    assert(Server)
    
    self.targetSelectorsToDestroy = { }
    
end

function TargetCacheMixin:OnDestroy()

    for _, destroyFunc in ipairs(self.targetSelectorsToDestroy) do
        destroyFunc()
    end
    
end