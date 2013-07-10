// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommunicationStatusIcons.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Display icons above player's heads, indicating if they are talking, typing or in the menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/GUIAnimatedScript.lua")
class 'GUICommunicationStatusIcons' (GUIAnimatedScript)

GUICommunicationStatusIcons.kMaxSize = Vector(90, 90, 0)
GUICommunicationStatusIcons.kMinSize = Vector(40, 40, 0)
GUICommunicationStatusIcons.kDisplayRange = 10

local function GetTextureCoordinates(unitStatus)

    local x1 = 0
    local x2 = 256

    // unitStatus == kPlayerCommunicationStatus.Typing 
    local index = 0
    if unitStatus == kPlayerCommunicationStatus.Voice then
        index = 1
    elseif unitStatus == kPlayerCommunicationStatus.Menu then
        index = 2
    end

    local y1 = index * 256 
    local y2 = (index + 1) * 256
    
    return x1, y1, x2, y2

end

function GUICommunicationStatusIcons:Initialize()

    PROFILE("GUICommunicationStatusIcons:Initialize")
    
    GUIAnimatedScript.Initialize(self)
    
    self.statusIcons = { }
    
end

function GUICommunicationStatusIcons:Uninitialize()

    PROFILE("GUICommunicationStatusIcons:Uninitialize")
    
    GUIAnimatedScript.Uninitialize(self)

    for index, icon in ipairs(self.statusIcons) do
        GUI.DestroyItem(icon)
    end
    
    self.statusIcons = nil
    
end

local function CreateIcon(self, player)

    PROFILE("GUICommunicationStatusIcons:CreateIcon")
    
    local newIcon = GUIManager:CreateGraphicItem()
    
    newIcon:SetTexture("ui/communication_status.dds")
    newIcon:SetSize(GUICommunicationStatusIcons.kMaxSize)
    
    newIcon.playerId = player:GetId()
    newIcon.playerStatus = player:GetCommunicationStatus()
    newIcon.playerOrigin = player:GetOrigin()
    
    newIcon:SetTexturePixelCoordinates(GetTextureCoordinates(newIcon.playerStatus))
    
    return newIcon
    
end

local function GetIconForPlayer(self, player)

    PROFILE("GUICommunicationStatusIcons:GetIconForPlayer")
    
    for index, icon in ipairs(self.statusIcons) do
    
        if icon.playerId == player:GetId() then
            return icon
        end
        
    end
    
    return nil
    
end

// Add remove GUI icons to match up with players .
local function UpdateAddRemoveIcons(self)

    PROFILE("GUICommunicationStatusIcons:UpdateAddRemoveIcons")
    
    // Scan for nearby eligible players to display this for. Only need to do this a few times a second.
    if (self.timeOfLastCommStatusUpdate == nil) or (Shared.GetTime() > self.timeOfLastCommStatusUpdate + 0.3) then
    
        local localPlayer = Client.GetLocalPlayer()
        
        for index, player in ipairs(GetEntitiesForTeamWithinRange("Player", localPlayer:GetTeamNumber(), localPlayer:GetEyePos(), GUICommunicationStatusIcons.kDisplayRange)) do
        
            // Skip local player
            if player:GetId() ~= Client.GetLocalPlayer():GetId() then
            
                // Get player voice status.
                local status = player:GetCommunicationStatus()
                
                // If player has voice status.
                if status ~= kPlayerCommunicationStatus.None then
                
                    // Get icon associated with player
                    local icon = GetIconForPlayer(self, player)
                    
                    // We have no icon, create icon and set new status
                    if icon == nil then
                    
                        local newIcon = CreateIcon(self, player)
                        table.insert(self.statusIcons, newIcon)
                        
                    end
                    
                end
                
            end
            
        end
        
        self.timeOfLastCommStatusUpdate = Shared.GetTime()
        
    end
    
end

local function UpdateIconsFromPlayers(self)

    PROFILE("GUICommunicationStatusIcons:UpdateIconsFromPlayers")
    
    local localPlayer = Client.GetLocalPlayer()
    local viewZAxis = localPlayer:GetViewAngles():GetCoords().zAxis
    
    // Update icon positions and status' for players every tick
    for index, icon in pairs(self.statusIcons) do
    
        local player = Shared.GetEntity(icon.playerId)
        assert(player ~= nil)
        assert(player:isa("Player"))
        
        local newStatus = player:GetCommunicationStatus()
        if newStatus ~= icon.playerStatus and (newStatus ~= kPlayerCommunicationStatus.None) then
        
            icon.playerStatus = newStatus
            icon:SetTexturePixelCoordinates(GetTextureCoordinates(newStatus))
            
        end
        
        // Only draw if it's in front of us.
        local toTarget = player:GetModelOrigin() - localPlayer:GetEyePos()
        local toTargetNorm = GetNormalizedVector(toTarget)
        local visible = (toTargetNorm:DotProduct(viewZAxis) > 0)
        
        if visible then
        
            local worldPoint = player:GetEngagementPoint()
            if player.GetHealthbarOffset then
                worldPoint = worldPoint + player:GetHealthbarOffset()
            end
            
            local screenPos = Client.WorldToScreen(worldPoint)
            local sizeScalar = 1 - toTarget:GetLength()/GUICommunicationStatusIcons.kDisplayRange
            local size = GUICommunicationStatusIcons.kMinSize + (GUICommunicationStatusIcons.kMaxSize - GUICommunicationStatusIcons.kMinSize) * sizeScalar
            icon:SetSize(size)
            icon:SetPosition(screenPos - size/ 2 - Vector(0, GUIScale(70), 0))
            
        end
        
        icon:SetIsVisible(visible)
        
    end
    
end

local function RemoveOrphanedIcon(icon)

    local localPlayer = Client.GetLocalPlayer()
    local player = Shared.GetEntity(icon.playerId)
    local dist = 0
    if player ~= nil then
        dist = (localPlayer:GetEyePos() - player:GetOrigin()):GetLength()
    end
    
    local delete = (player == nil) or (not player:isa("Player")) or (icon.playerStatus ~= player:GetCommunicationStatus()) or (dist > GUICommunicationStatusIcons.kDisplayRange)
    if delete then
        GUI.DestroyItem(icon)
    end
    
    return delete
    
end

function GUICommunicationStatusIcons:Update(deltaTime)

    PROFILE("GUICommunicationStatusIcons:Update")
    
    GUIAnimatedScript.Update(self, deltaTime)
    
    table.removeConditional(self.statusIcons, RemoveOrphanedIcon)
    
    UpdateAddRemoveIcons(self)
    
    UpdateIconsFromPlayers(self)
    
end