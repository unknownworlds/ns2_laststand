// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ManufactureMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

ManufactureMixin = CreateMixin( ManufactureMixin )
ManufactureMixin.type = "Manufacture"

ManufactureMixin.networkVars =
{
}

ManufactureMixin.expectedMixins =
{
    TechAction = "Required to display buttons."
}

ManufactureMixin.expectedCallbacks = 
{
}

ManufactureMixin.optionalCallbacks = 
{
}

function ManufactureMixin:__initmixin()

end


local function SharedUpdate(self, deltaTime)

    if Server then
   

    elseif Client then
    

    end
    
end

function ManufactureMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(ManufactureMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function ManufactureMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(ManufactureMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

function ManufactureMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("ManufactureMixin:OnUpdateAnimationInput")
    
end