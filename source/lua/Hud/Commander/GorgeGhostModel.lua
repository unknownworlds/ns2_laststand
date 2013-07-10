// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GorgeGhostModel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Shows an additional trail cinematic.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Commander/GhostModel.lua")


local kMistCinematic =PrecacheAsset("cinematics/alien/build/build.cinematic")

class 'GorgeGhostModel' (GhostModel)

function GorgeGhostModel:Initialize()

    GhostModel.Initialize(self)
    
    if not self.trailCinematic then
    
        self.cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.cinematic:SetCinematic(kMistCinematic)
        self.cinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end
    
    self.instancedMaterial = false
    
end

function GorgeGhostModel:Destroy() 

    GhostModel.Destroy(self)   
    
    if self.cinematic then
        Client.DestroyCinematic(self.cinematic)
        self.cinematic = nil
    end
    
end

function GorgeGhostModel:SetIsVisible(isVisible)

    self.cinematic:SetIsVisible(isVisible)
    GhostModel.SetIsVisible(self, isVisible)
    
end

function GorgeGhostModel:Update()

    local modelCoords = GhostModel.Update(self)
    
    if modelCoords then        
        self.cinematic:SetCoords(modelCoords)        
    end
    
    if not self.instancedMaterial and self.renderModel then
    
        self.renderModel:InstanceMaterials()
        self.renderModel:SetMaterialParameter("hiddenAmount", 1)
        self.instancedMaterial = true
    
    end
    
end
