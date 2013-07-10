// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_AlertQueue.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// TODO
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_AlertQueue' (GUIScript)

local isVisible

local alertQueueNeutral
local alertQueueMarine
local alertQueueAlien

local alertContainer

local kNeutralPosition
local kMarinePosition
local kAlienPosition

local kIconColor = Color(1,1,1,1)
local kIconSize = GUIScale(Vector(96, 96, 0))
local kIconPadding = GUIScale(Vector(0, 8, 0))
local kInfoColor = Color(1,1,1,1)
local kInfoScale = GUIScale(Vector(1, 1, 1))
local kShadowColor = Color(0,0,0,0.9)

local kAlertOffset = Vector(0, -(kIconSize.y + GUIScale(32)), 0)

local kAlertTime = 3
local kMoveRate = GUIScale(1000)

local kFontName = "fonts/AgencyFB_medium.fnt"

function GUIInsight_AlertQueue:Initialize()

    isVisible = true
    alertQueueNeutral = table.array(4)
    alertQueueMarine = table.array(4)
    alertQueueAlien = table.array(4)

    local width = Client.GetScreenWidth()
    local height = Client.GetScreenHeight()
    kNeutralPosition = Vector(width/2, height/4, 0)
    kMarinePosition = Vector(width/4, height/2, 0)
    kAlienPosition = Vector(3*width/4, height/2, 0)
    
    alertContainer = GUIManager:CreateGraphicItem()
    alertContainer:SetLayer(kGUILayerInsight)
    
end


function GUIInsight_AlertQueue:Uninitialize()

    GUI.DestroyItem(alertContainer)
    alertQueueNeutral = nil
    alertQueueMarine = nil
    alertQueueAlien = nil

end

function GUIInsight_AlertQueue:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    kIconSize = GUIScale(Vector(128, 128, 0))
    kIconPadding = GUIScale(Vector(0, 8, 0))
    kMoveRate = GUIScale(1000)
    self:Initialize()

end

function GUIInsight_AlertQueue:SetIsVisible(bool)

    isVisible = bool
    alertContainer:SetIsVisible(bool)

end

local function Push(queue, alert)
    
    table.insert(queue, alert)
    alert.Index = #queue
    
end

local function Pop(queue)

    return table.remove(queue, 1)

end

local function Peek(queue)

    return queue[1]

end

-- Position, IconSize, IconColor, InfoScale, InfoColor, ShadowColor
local function LerpAlert(alert)

    local percentage = alert.LerpPercentage
    local background = alert.Background
    local icon = alert.Icon
    local info = alert.Info
    local infoShadow = alert.InfoShadow

    local start = alert.Start
    local stop = alert.Stop

    local iconSize = LerpGeneric(start.IconSize, stop.IconSize, percentage)
    local infoScale = LerpNumber(start.InfoScale, stop.InfoScale, percentage)
    local infoPosition = Vector(iconSize.x/2, iconSize.y, 0) + kIconPadding
    
    background:SetPosition(LerpGeneric(start.Position, stop.Position, percentage))

    icon:SetColor(LerpColor(start.IconColor, stop.IconColor, percentage))
    icon:SetSize(iconSize)

    info:SetColor(LerpColor(start.InfoColor, stop.InfoColor, percentage))
    info:SetScale(infoScale)
    info:SetPosition(infoPosition)
    
    infoShadow:SetColor(LerpColor(start.ShadowColor, stop.ShadowColor, percentage))
    infoShadow:SetScale(infoScale)
    infoPosition.y = infoPosition.y + GUIScale(3)
    infoShadow:SetPosition(infoPosition)
    
end

local function GetAlertDetails(alert)

    local background = alert.Background
    local icon = alert.Icon
    local info = alert.Info
    local infoShadow = alert.InfoShadow

    local position = background:GetPosition()
    local iconSize = icon:GetSize()
    local iconColor = icon:GetColor()
    local infoScale = info:GetScale()
    local infoColor = info:GetColor()
    local shadowColor = infoShadow:GetColor()
    
    return { Position = position, IconSize = iconSize, IconColor = iconColor, InfoScale = infoScale, InfoColor = infoColor, ShadowColor = shadowColor }
    
end

local function Distance(Start, Stop)

    local start = Start.Position - Start.IconSize/2
    local stop = Stop.Position - Stop.IconSize/2
    local vector = start-stop
    local x = vector.x
    local y = vector.y
    return math.sqrt(x*x + y*y)

end

local function GetEndPosition(alert)
    
    local team = alert.Team
    local endPosition
    if team == kTeam1Index then
        endPosition = kMarinePosition
    elseif team == kTeam2Index then
        endPosition = kAlienPosition
    else
        endPosition = kNeutralPosition
    end
    return endPosition + (alert.Index-1) * kAlertOffset
    
end

function GUIInsight_AlertQueue:MoveAlertTo(alert, stopDetails)

    startDetails = GetAlertDetails(alert)
    local distance = Distance(startDetails, stopDetails)
    alert.LerpPercentage = 0
    alert.Velocity = kMoveRate / distance
    alert.Start = startDetails
    alert.Stop = stopDetails

end

function GUIInsight_AlertQueue:Update(deltaTime)

    local currentTime = Shared.GetTime()
    local queues = {alertQueueMarine, alertQueueAlien, alertQueueNeutral}
    
    for i = 1, #queues do
        local queue = queues[i]
        
        -- Kill expired Alerts
        local head = Peek(queue)
        while head and head.ExpireTime and head.ExpireTime <= currentTime do
            local alert = Pop(queue)
            GUI.DestroyItem(alert.Background)
            head = Peek(queue)
        end
        
        -- Update alerts
        for i = 1, #queue do
        
            local alert = queue[i]
            
            if i ~= alert.Index then
            
                alert.Index = i
                local stop = alert.Stop
                stop.Position = GetEndPosition(alert)
                self:MoveAlertTo(alert, stop)
                
            end
            
            local percent = alert.LerpPercentage
            if percent < 1 then
                
                percent = percent + deltaTime * alert.Velocity
                alert.LerpPercentage = math.min(percent, 1)
                LerpAlert(alert)
            
                if percent >= 1 then
                    alert.ExpireTime = currentTime + kAlertTime
                end
                
            end
        
        end
        
    end
    
end

function GUIInsight_AlertQueue:AddAlert(alert, iconColor, infoColor)
    
    local team = alert.Team
    local queue
    if team == kTeam1Index then
        queue = alertQueueMarine
    elseif team == kTeam2Index then
        queue = alertQueueAlien
    else
        queue = alertQueueNeutral
    end
    Push(queue, alert)
    
    iconColor = iconColor or kIconColor
    infoColor = infoColor or kInfoColor
    local endPosition = GetEndPosition(alert)
    local stop = { Position = endPosition, IconSize = kIconSize, IconColor = iconColor, InfoScale = kInfoScale, InfoColor = infoColor, ShadowColor = kShadowColor }
    self:MoveAlertTo(alert, stop)
    
end

function GUIInsight_AlertQueue:CreateAlert(position, icon, info, team)

    local alert = table.array(16)
    
    alert.Team = team
    
    local background = GUIManager:CreateGraphicItem()
    background:SetColor(Color(0,0,0,0))
    background:SetPosition(position)
    alert.Background = background
    
    if icon then
    
        local iconItem = GUIManager:CreateGraphicItem()
        iconItem:SetTexture(icon.Texture)
        iconItem:SetTexturePixelCoordinates(unpack(icon.TextureCoordinates))
        iconItem:SetColor(icon.Color)
        iconItem:SetSize(icon.Size)
        background:AddChild(iconItem)
        alert.Icon = iconItem
    
    end
    
    if info then
    
        local infoShadowItem = GUIManager:CreateTextItem()
        infoShadowItem:SetText(info.Text)
        infoShadowItem:SetTextAlignmentX(GUIItem.Align_Center)
        infoShadowItem:SetTextAlignmentY(GUIItem.Align_Min)
        infoShadowItem:SetFontIsBold(true)
        infoShadowItem:SetColor(info.ShadowColor)
        infoShadowItem:SetScale(info.Scale)
        infoShadowItem:SetFontName(kFontName)
        background:AddChild(infoShadowItem)
        alert.InfoShadow = infoShadowItem
        
        local infoItem = GUIManager:CreateTextItem()
        infoItem:SetText(info.Text)
        infoItem:SetTextAlignmentX(GUIItem.Align_Center)
        infoItem:SetTextAlignmentY(GUIItem.Align_Min)
        infoItem:SetFontIsBold(true)
        infoItem:SetColor(info.Color)
        infoItem:SetScale(info.Scale)
        infoItem:SetFontName(kFontName)
        background:AddChild(infoItem)
        alert.Info = infoItem
        
    end
    
    alertContainer:AddChild(background)
    
    return alert
    
end