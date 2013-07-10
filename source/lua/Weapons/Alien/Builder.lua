// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Builder.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Attaches a laser to an entity. Rendering and events is done client side only,
//    the server controls only the status (active or not active). 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/Globals.lua")
Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")

class 'Builder' (Entity)

Builder.mapName = "builder"

Builder.networkVars =
{
    isBuilding    = "boolean"
}

function Builder:OnCreate()
    
    Entity.OnCreate(self)
    
    if Server then
    
        self:SetUpdates(false)
        
    elseif Client then
    
        local constants = {kRenderZone = RenderScene.Zone_ViewModel}
        InitMixin(self, ClientModelMixin, constants)
        self:SetUpdates(true)
        
    end

end

function Builder:OnGetIsRelevant(player)
    
    // Only the parent can see the view model builder
    return self:GetParent() == player
    
end

if Client then

    // Override camera coords with custom camera animation
    function Builder:OnAdjustModelCoords(coords)
    
        PROFILE("Builder:OnAdjustModelCoords")
        
        local overrideCoords = Coords.GetIdentity()
        
        if self:GetNumModelCameras() > 0 then

            local camera = self:GetModelCamera(0)
            
            if self:GetParent() == Client.GetLocalPlayer() then
                Client.SetZoneFov(RenderScene.Zone_Builder, camera:GetFov())
            end

            overrideCoords = camera:GetCoords():GetInverse()
            
        else
        
            if self:GetParent() == Client.GetLocalPlayer() then
                Client.SetZoneFov(RenderScene.Zone_Builder, math.rad(65))
            end
            
        end
        
        return overrideCoords
        
    end

    /**
     * Updates the GUI elements in the view model.
     */
    function Builder:UpdateGUI()

        local renderModel = self:GetRenderModel()
        if renderModel ~= nil then

            renderModel:SetMaterialParameter("buildPercentage", PlayerUI_GetBuildPercentage())
            
        end
    
    end
        
end

function Builder:OnUpdateAnimationInput(modelMixin)

    PROFILE("Builder:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("build", self.isBuilding)
    
end

Shared.LinkClassToMap("Builder", Builder.mapName, Builder.networkVars)