// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\TeamMessageMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

TeamMessageMixin = CreateMixin( TeamMessageMixin )
TeamMessageMixin.type = "TeamMessage"

TeamMessageMixin.expectedConstants =
{
    kGUIScriptName = "The name of the GUI script to use when displaying team messages."
}

function TeamMessageMixin:__initmixin()

    // Only for use on the Client.
    assert(Client)
    
    self.teamMessageGUI = GetGUIManager():CreateGUIScript(self:GetMixinConstants().kGUIScriptName)
    
end

function TeamMessageMixin:OnDestroy()

    if self.teamMessageGUI then
    
        GetGUIManager():DestroyGUIScript(self.teamMessageGUI)
        self.teamMessageGUI = nil
        
    end
    
end

function TeamMessageMixin:SetTeamMessage(message)

    if self.teamMessageGUI then
        self.teamMessageGUI:SetTeamMessage(message)
    end
    
end