// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CloakableMixin.lua    
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Outlines targets blue when SetRailgunTarget() is called for kRailgunTargetDuration seconds.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

RailgunTargetMixin = CreateMixin( RailgunTargetMixin )
RailgunTargetMixin.type = "RailgunTarget"

//Shared.PrecacheSurfaceShader("cinematics/vfx_materials/highlightmodel.surface_shader")

local kRailgunTargetDuration = 0.3

RailgunTargetMixin.expectedMixins =
{
    Model = "Required to add to shader mask."
}

function RailgunTargetMixin:__initmixin()
    assert(Client)
    self.isRailgunTarget = false
    self.timeRailgunTargeted = -1
end

function RailgunTargetMixin:SetRailgunTarget()
    self.timeRailgunTargeted = Shared.GetTime()
end

function RailgunTargetMixin:OnUpdate(deltaTime)

    local isTarget = self.timeRailgunTargeted + kRailgunTargetDuration > Shared.GetTime()
    local model = self:GetRenderModel()
    
    if self.isRailgunTarget ~= isTarget and model then
    
        if isTarget then
            EquipmentOutline_AddModel(model)
        else
            EquipmentOutline_RemoveModel(model)
        end
        
        self.isRailgunTarget = isTarget
    
    end

end

/* disabled since it doesnt look very good and distracts too much
function RailgunTargetMixin:OnUpdateRender()

    local model = self:GetRenderModel()

    if model then
    
        local intensity = 1 - Clamp( (Shared.GetTime() - self.timeRailgunTargeted) / 0.3, 0, 1 )
        local showMaterial = intensity ~= 0
    
        if not self.railgunHighlightMaterial and showMaterial then
            self.railgunHighlightMaterial = AddMaterial(model, "cinematics/vfx_materials/highlightmodel.material")
        elseif not showMaterial and self.railgunHighlightMaterial then
            RemoveMaterial(model, self.railgunHighlightMaterial)
            self.railgunHighlightMaterial = nil
        end

        if self.railgunHighlightMaterial then
            self.railgunHighlightMaterial:SetParameter("intensity", intensity * 0.5)
        end
    
    end

end
*/