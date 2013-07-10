// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PrototypeLab_Client.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function PrototypeLab:GetWarmupCompleted()
    return not self.timeConstructionCompleted or (self.timeConstructionCompleted + 0.7 < Shared.GetTime())
end

function PrototypeLab:UpdatePrototypeLabWarmUp()

    if self.clientConstructionComplete ~= self.constructionComplete and self.constructionComplete then
        self.clientConstructionComplete = self.constructionComplete
        self.timeConstructionCompleted = Shared.GetTime()
    end
    
end

function PrototypeLab:OnUse(player, elapsedTime, useSuccessTable)

    self:UpdatePrototypeLabWarmUp()
    
    if GetIsUnitActive(self) and not Shared.GetIsRunningPrediction() and not player.buyMenu and self:GetWarmupCompleted() then
    
        if Client.GetLocalPlayer() == player then
        
            Client.SetCursor("ui/Cursor_MarineCommanderDefault.dds", 0, 0)
            
            // Play looping "active" sound while logged in
            // Shared.PlayPrivateSound(player, Armory.kResupplySound, player, 1.0, Vector(0, 0, 0))
            
            MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)
            
            // Tell the player to show the lua menu.
            player:BuyMenu(self)
            
        end
        
    end
    
end