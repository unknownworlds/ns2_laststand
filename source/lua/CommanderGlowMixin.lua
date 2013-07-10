// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CommanderGlowMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    
if Client then

Script.Load("lua/FunctionContracts.lua")

CommanderGlowMixin = CreateMixin( CommanderGlowMixin )
CommanderGlowMixin.type = "CommanderGlow"

CommanderGlowMixin.expectedMixins =
{
    Model = "Needed for effects"
}

CommanderGlowMixin.optionalCallbacks =
{
    GetTeamNumber = "Get team index"
}

function CommanderGlowMixin:OnUpdateRender()
    PROFILE("CommanderGlowMixin:OnUpdateRender")
    self:UpdateHighlight()
end
AddFunctionContract(CommanderGlowMixin.OnUpdateRender, { Arguments = { "Entity" }, Returns = { } })

function CommanderGlowMixin:UpdateHighlight()

    // Show glowing outline for commander, to pick it out of the darkness
    local player = Client.GetLocalPlayer()
    local visible = player ~= nil and (player:isa("Commander") or (player.GetIsOverhead and player:GetIsOverhead()))
    
    // Don't show enemy structures as glowing
    if visible and self.GetTeamNumber and (player:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
        visible = false
    end

    // Update the visibility status.
    if visible ~= self.commanderGlowOutline then
    
        local model = self:GetRenderModel()
        if model ~= nil then

            local isAlien = GetIsAlienUnit(player)        
            if visible then
                if isAlien then
                    HiveVision_AddModel( model )
                else
                    EquipmentOutline_AddModel( model )
                end
            else
                HiveVision_RemoveModel( model )
                EquipmentOutline_RemoveModel( model )
            end
         
            self.commanderGlowOutline = visible    
            
        end
        
    end
    
end

end