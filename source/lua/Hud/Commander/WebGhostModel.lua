// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\WebGhostModel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Commander/GhostModel.lua")

class 'WebGhostModel' (GhostModel)

local kWebMaterial = "models/alien/gorge/web.material"

function WebGhostModel:Initialize()

    GhostModel.Initialize(self)
    
    self.desiredVisibility = true
    
    if not self.webRenderModel then
    
        self.webRenderModel = DynamicMesh_Create()
        self.webRenderModel:SetMaterial(kWebMaterial)
        
    end    
    
end

function WebGhostModel:Destroy() 

    GhostModel.Destroy(self)   
    
    if self.webRenderModel then
    
        DynamicMesh_Destroy(self.webRenderModel)
        self.webRenderModel = nil
        
    end
    
end

function WebGhostModel:SetIsVisible(isVisible)

    self.webRenderModel:SetIsVisible(isVisible)
    self.desiredVisibility = isVisible
    GhostModel.SetIsVisible(self, isVisible)
    
end

function WebGhostModel:Update()

    local modelCoords = GhostModel.Update(self)
    local lastClickedPos = GhostModelUI_GetLastClickedPosition()
    local valid = GhostModelUI_GetIsValidPlacement()

    if valid and self.desiredVisibility and modelCoords and lastClickedPos then      
  
        local length = (modelCoords.origin - lastClickedPos):GetLength()

        modelCoords.zAxis = GetNormalizedVector(lastClickedPos - modelCoords.origin)
        modelCoords.xAxis = modelCoords.zAxis:GetPerpendicular()
        modelCoords.yAxis = modelCoords.zAxis:CrossProduct(modelCoords.xAxis)
        
        DynamicMesh_SetTwoSidedLine(self.webRenderModel, modelCoords, 0.1, length)
        
    end
    
    self.webRenderModel:SetIsVisible(self.desiredVisibility and valid)
    
end
