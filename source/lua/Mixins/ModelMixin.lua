// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Mixins/ModelMixin.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// and Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Mixins/BaseModelMixin.lua")

ModelMixin = CreateMixin( ModelMixin )
ModelMixin.type = "Model"

ModelMixin.expectedMixins =
{
    BaseModel = "Base model mixin must be present"
}
kMaxAnimationSpeed = 10
kAnimationSpeedStep = 0.01

ModelMixin.networkVars =
{
    
    // Base Layer:
    // ------------------------------
    animationGraphNode  = "compensated integer (-1 to " .. BaseModelMixin.kMaxGraphNodes .. ")",
    // Primary animation.
    animationSequence   = "compensated integer (-1 to " .. BaseModelMixin.kMaxAnimations .. ")",
    animationStart      = "compensated time",
    animationSpeed      = "compensated float (0 to " .. kMaxAnimationSpeed .. " by " .. kAnimationSpeedStep .. ")",
    animationBlend      = "compensated float (0 to 1 by 0.01)",
    // Blended animation.
    animationSequence2  = "compensated integer (-1 to " .. BaseModelMixin.kMaxAnimations .. ")",
    animationStart2     = "compensated time",
    animationSpeed2     = "compensated float (0 to " .. kMaxAnimationSpeed .. " by " .. kAnimationSpeedStep .. ")",
    
    // Layer 1:
    // ------------------------------
    layer1AnimationGraphNode  = "compensated integer (-1 to " .. BaseModelMixin.kMaxGraphNodes .. ")",
    // Primary animation.
    layer1AnimationSequence   = "compensated integer (-1 to " .. BaseModelMixin.kMaxAnimations .. ")",
    layer1AnimationStart      = "compensated time",
    layer1AnimationBlend      = "compensated float (0 to 1 by 0.01)",
    layer1AnimationSpeed      = "compensated float(0 to " .. kMaxAnimationSpeed .. " by " .. kAnimationSpeedStep .. ")",
    // Blended animation.
    layer1AnimationSequence2  = "compensated integer (-1 to " .. BaseModelMixin.kMaxAnimations .. ")",
    layer1AnimationStart2     = "compensated time",
    layer1AnimationSpeed2     = "compensated float (0 to " .. kMaxAnimationSpeed .. " by " .. kAnimationSpeedStep .. ")",

}

function ModelMixin:__initmixin()

    self.limitedModel = false
    self.fullyUpdated = true

end
