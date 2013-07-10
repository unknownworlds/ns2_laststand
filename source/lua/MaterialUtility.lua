//======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MaterialUtility.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Materials specific utilty functions
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function AddMaterial(model, materialName)

    assert(model)
    assert(materialName)

    local materialHandle = Client.CreateRenderMaterial()
    materialHandle:SetMaterial(materialName)        
    model:AddMaterial(materialHandle)
    
    return materialHandle

end

function RemoveMaterial(model, materialHandle)

    assert(model)

    if materialHandle then
    
        model:RemoveMaterial(materialHandle)
        Client.DestroyRenderMaterial(materialHandle)
        materialHandle = nil
        
        return true
    
    end
    
    return false

end