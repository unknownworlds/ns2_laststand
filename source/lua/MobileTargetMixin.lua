// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MobileTargetMixin.lua    
//    
//    Created by:   Mats Olsson (mats.olsson@matsotech.se) 
//
// Things which can be expected to move and be a target of a AI units must mixin this type.
//
// If the target seldom moves, it can call the self:MobileTargetMoved() to signal to the 
// target cache that it must be rescanned. Typically used when teleporting normally static
// structures.
//
// NOTE: REQUIRES THE MIXIN TO BE MADE IN OnInitialized! (the target cache expects the team to be set)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

MobileTargetMixin = CreateMixin( MobileTargetMixin )
MobileTargetMixin.type = "MobileTarget"

MobileTargetMixin.expectedMixins =
{
    Team = "TargetCache assumes all targets belongs to a team",
}

function MobileTargetMixin:__initmixin()
    TargetType.OnCreateEntity(self)
end

function MobileTargetMixin:OnDestroy()
    TargetType.OnDestroyEntity(self)
end



