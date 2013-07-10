// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/** 
 * Creates the rendering representation of the model if it doesn't match
 * the currently set model index and update's it state to match the actor.
 */
function Projectile:OnUpdateRender()

    PROFILE("Projectile:OnUpdateRender")
    
    if self.oldModelIndex ~= self.modelIndex then

        // Create/destroy the model as necessary.
        if self.modelIndex == 0 and self.renderModel then
        
            Client.DestroyRenderModel(self.renderModel)
            self.renderModel = nil
            
        elseif self.modelIndex then
        
            self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            self.renderModel:SetModel(self.modelIndex)
            
        end
    
        // Save off the model index so we can detect when it changes.
        self.oldModelIndex = self.modelIndex
        
    end
    
    if self.renderModel ~= nil then
        self.renderModel:SetCoords(self:GetCoords())
    end

end