// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ObjectiveInfo.lua")

class 'CommandStructure' (ScriptActor)
CommandStructure.kMapName = "commandstructure"

if Server then
    Script.Load("lua/CommandStructure_Server.lua")
end

local networkVars =
{
    occupied = "boolean",
    commanderId = "entityid",
    attachedId = "entityid",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function CommandStructure:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self.occupied = false
    self.commanderId = Entity.invalidId
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function CommandStructure:GetReceivesStructuralDamage()
    return true
end

function CommandStructure:GetIsOccupied()
    return self.occupied
end

function CommandStructure:GetEffectParams(tableParams)
    tableParams[kEffectFilterOccupied] = self.occupied
end

if Client then

    local function DisplayHelpArrows(self, visible)
    
        if not self.helpArrows and visible then
        
            self.helpArrows = Client.CreateCinematic(RenderScene.Zone_Default)
            self.helpArrows:SetCinematic(self:GetHelpArrowsCinematicName())
            self.helpArrows:SetCoords(self:GetCoords())
            self.helpArrows:SetRepeatStyle(Cinematic.Repeat_Endless)
            
        end
        
        if self.helpArrows then
            self.helpArrows:SetIsVisible(visible)
        end
        
    end
    
    function CommandStructure:OnUpdateRender()
    
        local player = Client.GetLocalPlayer()
        local now = Shared.GetTime()
        
        self.lastTimeOccupied = self.lastTimeOccupied or now
        if self:GetIsOccupied() then
            self.lastTimeOccupied = now
        end
        
        local displayHelpArrows = true
        if player then
        
            // Display the help arrows (get into Comm structure) when the
            // team does not have a commander and the Comm structure is built
            // and some time has passed.
            displayHelpArrows = true
            displayHelpArrows = displayHelpArrows and player:GetTeamNumber() == self:GetTeamNumber()
            displayHelpArrows = displayHelpArrows and self:GetIsBuilt() and self:GetIsAlive()
            displayHelpArrows = displayHelpArrows and not ScoreboardUI_GetTeamHasCommander(self:GetTeamNumber())
            displayHelpArrows = displayHelpArrows and not self:GetIsOccupied() and (now - self.lastTimeOccupied) >= 12
            
        end
        
        DisplayHelpArrows(self, displayHelpArrows)
        
    end
    
    function CommandStructure:OnDestroy()
    
        ScriptActor.OnDestroy(self)
        
        if self.helpArrows then
        
            Client.DestroyCinematic(self.helpArrows)
            self.helpArrows = nil
            
        end
        
    end
    
end

function CommandStructure:OnUpdateAnimationInput(modelMixin)

    PROFILE("CommandStructure:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("occupied", self.occupied)
    
end

function CommandStructure:GetCanBeUsedConstructed()
    return not self:GetIsOccupied()
end

// allow players to enter the hives before game start to signal that they want to command
function CommandStructure:GetUseAllowedBeforeGameStart()
    return true
end

Shared.LinkClassToMap("CommandStructure", CommandStructure.kMapName, networkVars, true)