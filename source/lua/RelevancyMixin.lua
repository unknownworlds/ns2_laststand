// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RelevancyMixin.lua
//
//    Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

RelevancyMixin = CreateMixin( RelevancyMixin )
RelevancyMixin.type = "Relevancy"

RelevancyMixin.optionalCallbacks =
{
}

function CopyRelevancyMask(fromEnt, toEnt)

    if fromEnt and toEnt and HasMixin(fromEnt, "Relevancy") then
        toEnt:SetExcludeRelevancyMask(fromEnt:GetExcludeRelevancyMask())
    end

end

function RelevancyMixin:__initmixin()
    assert(Server)
    // always relevant by default
    self.excludeRelevancyMask = 31
end

function RelevancyMixin:SetExcludeRelevancyMask(mask)
    self.excludeRelevancyMask = mask
end

function RelevancyMixin:GetExcludeRelevancyMask()
    return self.excludeRelevancyMask
end