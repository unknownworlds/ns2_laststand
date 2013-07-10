// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TeleportAlienGhostModel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Shows an additional trail cinematic.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Commander/GhostModel.lua")

local kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

class 'TeleportAlienGhostModel' (GhostModel)

function TeleportAlienGhostModel:Initialize()

    GhostModel.Initialize(self)
    
    if not self.circleModel then    
        self.circleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.circleModel:SetModel(kCircleModelName)
    end
    
end

function TeleportAlienGhostModel:Destroy() 

    GhostModel.Destroy(self)   
    
    if self.circleModel then 
    
        Client.DestroyRenderModel(self.circleModel)
        self.circleModel = nil
    
    end
    
end

function TeleportAlienGhostModel:SetIsVisible(isVisible)

    self.circleModel:SetIsVisible(isVisible)
    GhostModel.SetIsVisible(self, isVisible)
    
end

function TeleportAlienGhostModel:Update()

    local modelCoords = GhostModel.Update(self)
    
    if modelCoords then
        
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(modelCoords.origin, zAxis)
        self.circleModel:SetCoords(coords)
        
    end
    
end
