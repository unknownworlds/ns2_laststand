// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\JetpackMarine_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Only display jetpack in thirdperson or for other players.
function JetpackMarine:UpdateClientEffects(deltaTime, isLocal)

    Marine.UpdateClientEffects(self, deltaTime, isLocal)
    
    local drawWorld = ((not isLocal) or self:GetIsThirdPerson())
    
    local jetpackOnBack = self:GetJetpack()
    
    if jetpackOnBack then
    
        jetpackOnBack:SetIsVisible(drawWorld)
        jetpackOnBack:UpdateJetpackTrails(deltaTime)
        
    end
    
end