// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\SelectableMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * SelectableMixin marks entities as selectable to a commander.
 */
SelectableMixin = CreateMixin( SelectableMixin )
SelectableMixin.type = "Selectable"

SelectableMixin.networkVars =
{
    selectionMask = "integer (0 to 4)",
    hotGroupNumber = "integer (0 to " .. ToString(kMaxHotkeyGroups) .. ")", 
}

SelectableMixin.optionalCallbacks =
{
    OnGetIsSelectable = "Returns if this entity is selectable or not"
}

function SelectableMixin:__initmixin()

    self.selectionMask = 0
    self.hotGroupNumber = 0

end

local function UpdateCachedMask(self)

    // delete caching in case local player is not a commander   
    if not Client or not Client.GetLocalPlayer() or not Client.GetLocalPlayer():isa("Commander") then
        self.selectionMaskClient = nil
    end    

end

local function UpdateCachedHotGroup(self)

    if Client then
    
        local player = Client.GetLocalPlayer()
        if not player or not player:isa("Commander") or not player:GetTeamNumber() == self:GetTeamNumber() then
            self.hotGroupNumberClient = nil
        end
        
    end
    
end

function SelectableMixin:OnSighted(sighted)

    if not sighted then
    
        local selectedByTeamOne = bit.band(self.selectionMask, 1) ~= 0
        local selectedByTeamTwo = bit.band(self.selectionMask, 2) ~= 0
        
        if self:GetTeamNumber() == 2 and selectedByTeamOne then
        
            if Server then
                self:SetSelected(1, false)
            end
            
        elseif self:GetTeamNumber() == 1 and selectedByTeamTwo then
        
            if Server then
                self:SetSelected(2, false)
            end
            
        end
        
    end
    
end

function SelectableMixin:ClearClientSelectionMask()
    self.selectionMaskClient = nil
end

function SelectableMixin:SetSelected(teamNumber, selected, keepSelection, sendMessage)
    
    if sendMessage == nil then
        sendMessage = true
    end
    
    if keepSelection == nil then
        keepSelection = true
    end
    
    local oldMask = self.selectionMask    
    selected = selected and self:GetIsSelectable(teamNumber)

    if selected then
        self.selectionMask = bit.bor(self.selectionMask, teamNumber)
    else
        self.selectionMask = bit.band(self.selectionMask, bit.bnot(teamNumber))
    end  

    if Client then
    
        local player = Client.GetLocalPlayer()
        // only commanders are allowed to select something
        if player and player:isa("Commander") then   
     
            self.selectionMaskClient = self.selectionMask
            
            if sendMessage and oldMask ~= self.selectionMask then

                local selectUnitMessage = BuildSelectUnitMessage(teamNumber, self, selected, keepSelection)
                Client.SendNetworkMessage("SelectUnit", selectUnitMessage, true)
                
            end

        end

    end 
    
    UpdateCachedMask(self)   
    if oldMask ~= self.selectionMask then 
    
        UpdateMenuTechId(teamNumber, selected)
        
        if Server then
            self:UpdateIncludeRelevancyMask()
        end
        //DebugPrint("%s:SetSelected(%s, %s, %s, %s) self.selectionMask: %s", ToString(self), ToString(teamNumber), ToString(selected), ToString(keepSelection), ToString(sendMessage), ToString(self.selectionMask))
        //DebugPrint("GEWCName:\n%s", debug.traceback()) 
                
    end
    
end

local function GetSelectedClient(self, teamNumber)

    local selected = false

    if not teamNumber and Client then
    
        local player = Client.GetLocalPlayer()
        if player and HasMixin(player, "Team") then
            teamNumber = player:GetTeamNumber()
        end
    
    end
    
    assert(teamNumber)
    
    local mask = self.selectionMask
    if self.selectionMaskClient ~= nil then
        mask = self.selectionMaskClient
    end
    
    selected = bit.band(mask, teamNumber) ~= 0
    
    return selected
    
end

function SelectableMixin:GetIsSelected(teamNumber)

    local selected = false
    
    UpdateCachedMask(self)
    
    if Client then
        selected = GetSelectedClient(self, teamNumber)    
    else
        selected = bit.band(self.selectionMask, teamNumber) ~= 0
    end
    
    return selected

end

function SelectableMixin:GetIsSelectable(byTeamNumber)

    local isValid = not HasMixin(self, "LOS") or self:GetIsSighted() or (HasMixin(self, "Team") and byTeamNumber == self:GetTeamNumber())
    
    if isValid and self.OnGetIsSelectable then
    
        // A table is passed in so that all the OnGetIsSelectable functions
        // have a say in the matter.
        local resultTable = { selectable = true }
        self:OnGetIsSelectable(resultTable, byTeamNumber)
        isValid = resultTable.selectable
        
    end
    
    return isValid
    
end
AddFunctionContract(SelectableMixin.GetIsSelectable, { Arguments = { "Entity", "Player" }, Returns = { "boolean" } })


function SelectableMixin:UpdateIncludeRelevancyMask()

    // Make entities which are active for a commander relevant to all commanders
    // on the same team.
    local includeMask = 0
    
    if bit.band(self.selectionMask, 1) ~= 0 or (self:GetTeamNumber() == 1 and self:GetHotGroupNumber() ~= 0) then
        includeMask = bit.bor(includeMask, kRelevantToTeam1Commander)
    end
    
    if bit.band(self.selectionMask, 2) ~= 0 or (self:GetTeamNumber() == 2 and self:GetHotGroupNumber() ~= 0) then
        includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)
    end
    
    self:SetIncludeRelevancyMask( includeMask )
    
end

if Client then

    function SelectableMixin:OnDestroy()
    
        if self.selectionCircleModel then
        
            Client.DestroyRenderModel(self.selectionCircleModel)
            self.selectionCircleModel = nil
            
        end
    
    end
    
    local function GetPlayerCanSeeSelection(player)
        return player:isa("Commander") or player:isa("Spectator")
    end

    function SelectableMixin:OnUpdateRender()
    
        local showCircle = false
        local player = Client.GetLocalPlayer()
        if player and HasMixin(player, "Team") and GetPlayerCanSeeSelection(player) then
            showCircle = self:GetIsSelected(player:GetTeamNumber())
        end
        
        if not self.selectionCircleModel and showCircle then
        
            self.selectionCircleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            local modelName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleModelName, Commander.kMarineCircleModelName)
            self.selectionCircleModel:SetModel(modelName)
            
        end
        
        if self.selectionCircleModel then
            self.selectionCircleModel:SetIsVisible(showCircle)
        end
        
        if showCircle and self.selectionCircleModel then
        
            if not self.selectionCircleCoords then
            
                self.selectionCircleCoords = Coords.GetLookIn(self:GetOrigin() + Vector(0, kZFightingConstant, 0), Vector.xAxis)
                local scale = GetCircleSizeForEntity(self)
                self.selectionCircleCoords:Scale(scale)
                
            end

            self.selectionCircleCoords.origin = self:GetOrigin() + Vector(0, kZFightingConstant, 0)
            self.selectionCircleModel:SetCoords(self.selectionCircleCoords)
            
        end

    end

end

function SelectableMixin:GetHotGroupNumber()

    UpdateCachedHotGroup(self)

    if self.hotGroupNumberClient then
        return self.hotGroupNumberClient
    else
        return self.hotGroupNumber
    end

end

function SelectableMixin:SetHotGroupNumber(hotGroupNumber)

    local currentHotGroup = self:GetHotGroupNumber()
    if currentHotGroup ~= hotGroupNumber then
    
        self.hotGroupNumber = hotGroupNumber
        
        if Client then
        
            local player = Client.GetLocalPlayer()
            if player and player:isa("Commander") and player:GetTeamNumber() == self:GetTeamNumber() then
                self.hotGroupNumberClient = hotGroupNumber
            end
            
        end
    
    end

end

