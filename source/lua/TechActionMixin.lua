// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TechActionMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

TechActionMixin = CreateMixin( TechActionMixin )
TechActionMixin.type = "TechAction"

TechActionMixin.networkVars =
{
}

TechActionMixin.expectedMixins =
{
}

TechActionMixin.expectedCallbacks = 
{
}

TechActionMixin.optionalCallbacks = 
{
}

function TechActionMixin:__initmixin()

end


local function SharedUpdate(self, deltaTime)

    if Server then
   

    elseif Client then
    

    end
    
end

function TechActionMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(TechActionMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function TechActionMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(TechActionMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

function TechActionMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("TechActionMixin:OnUpdateAnimationInput")
    
end