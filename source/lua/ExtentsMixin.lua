// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ExtentsMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * ExtentsMixin allows an entity to define how much space it takes up.
 * The GetExtents() function is expected to be provided by anything that uses this mixin.
 */
ExtentsMixin = CreateMixin( ExtentsMixin )
ExtentsMixin.type = "Extents"

ExtentsMixin.expectedMixins =
{
    Tech = "Returns the tech Id of this entity."
}

ExtentsMixin.optionalCallbacks =
{
    GetExtentsOverride = "Returns a Vector indicating the current extents of this entity."
}

local function InternalGetMaxExtents(self)

    if not self.maxExtents then
    
        local maxExtents = LookupTechData(self:GetTechId(), kTechDataMaxExtents, nil)
        
        if not maxExtents then
            
            if HasMixin(self, "Model") then
            
                local min, max = self:GetModelExtents()
                maxExtents = max

            end
            
        else
            self.extentsTechDataDefined = true
        end
        
        if maxExtents == nil then
            maxExtents = Vector(0.5, 0.5, 0.5)
        end
    
        self.maxExtents = Vector(maxExtents)
    
    end
    
    return self.maxExtents

end

function ExtentsMixin:__initmixin()
    InternalGetMaxExtents(self)
end

// we keep the previous extents in case there is no model anymore
function ExtentsMixin:OnModelChanged(hasModel)
    if hasModel and not self.extentsTechDataDefined then
        self.maxExtents = nil
    end
end

function ExtentsMixin:GetExtents()

    if self.GetExtentsOverride then
        return self:GetExtentsOverride()
    end
    return self:GetMaxExtents()

end
AddFunctionContract(ExtentsMixin.GetExtents, { Arguments = { "Entity" }, Returns = { "Vector" } })

function ExtentsMixin:GetMaxExtents()
    return Vector(InternalGetMaxExtents(self))
end
AddFunctionContract(ExtentsMixin.GetMaxExtents, { Arguments = { "Entity" }, Returns = { "Vector" } })