// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\UsableMixin.lua
//
//    Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

UsableMixin = CreateMixin(UsableMixin)
UsableMixin.type = "Usable"

UsableMixin.expectedCallbacks =
{
    GetUsablePoints = "Returns a list of usable points in world space for this entity.",
    GetCanBeUsed = "Returns true when this entity is able to be used."
}

UsableMixin.optionalCallbacks =
{
    OnUse = "Called when something uses this entity"
}

function UsableMixin:__initmixin()
end