// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\StaticStaticTargetMixin.lua    
//    
//    Created by:   Mats Olsson (mats.olsson@matsotech.se) 
//
// Things which do not move (or rather, seldom move) and can be targeted by AI units must 
// mixin this.
//
// If the target seldom moves, it can call the self:StaticTargetMoved() to signal to the 
// target cache that it must be rescanned. Typically used when teleporting normally static
// structures.
//
// NOTE: REQUIRES THE MIXIN TO BE MADE IN OnInitialized! (the target cache expects the team and position to be set)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

StaticTargetMixin = CreateMixin(StaticTargetMixin)
StaticTargetMixin.type = "StaticTarget"

StaticTargetMixin.expectedMixins =
{
    Team = "TargetCache assumes all targets belongs to a team",
}

function StaticTargetMixin:__initmixin()
    TargetType.OnCreateEntity(self)
end

function StaticTargetMixin:OnDestroy()
    TargetType.OnDestroyEntity(self)
end

function StaticTargetMixin:StaticTargetMoved()
    TargetType.OnTargetMoved(self)
end


