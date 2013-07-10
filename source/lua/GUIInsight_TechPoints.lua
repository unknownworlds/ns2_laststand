// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_TechPoints.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Spectator: Displays tech point info
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_TechPoints' (GUIScript)

local isVisible

local kIconTexture = "ui/techpointicons.dds"
local kFrameTexture = "ui/techpoints.dds"
local kEdgeTexture = "ui/techpointsedge.dds"
local kBackgroundTexture = "ui/techpointsbackground.dds"
local kHorizontalBarTexture = "ui/repeatable_bar_horizontal.dds"
local kVerticalBarTexture = "ui/repeatable_bar_vertical.dds"
local kTechPointTexture = "ui/techpoint.dds"

local kFontName = "fonts/AgencyFB_small.fnt"
local kTeamNameFontScale = GUIScale(Vector(1, 0.8, 0))
local kTeamInfoFontScale = GUIScale(Vector(0.9, 0.7, 0))

local kTechPointSize = GUIScale(Vector(225, 40, 0))
local kIconSize = GUIScale(Vector(40, 40, 0))

local kAlienAlertSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_under_attack")
local kMarineAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/command_station_under_attack")

local kTimeBetweenAlerts = 30
local kClaimFlashTime = 10
local kAttackFlashTime = 5

-- Color constants.
local kInfoColor = Color(1, 1, 1, 1)
local kDeadColor = Color(1,0,0,1)
local kUnclaimedColor = Color(0.6,0.6,0.6,1)
local kClaimColor = Color(0,1,0,1)

local scale = 0.5
local cornerCoords = {0,0,110,110}
local bottomCoords = {0,110,110,256}
local topCoords = {110,0,256,110}
local leftBarCoords = {1,0,48,296}

local hBarCoords = Vector(484,80,0)
local hBarHeight = GUIScale(15)
local hBarWidth = (hBarCoords.x/hBarCoords.y) * hBarHeight
local hBarTextureWidth = (kTechPointSize.x/hBarWidth) * hBarCoords.x

local vBarSize = GUIScale(Vector(25,kTechPointSize.y*0,0))

local lastAlertTime = 0

function GUIInsight_TechPoints:Initialize()

    self.techPointBackground = GUIManager:CreateGraphicItem()
    self.techPointBackground:SetTexture(kBackgroundTexture)
    self.techPointBackground:SetTexturePixelCoordinates(unpack({0,0,512,512}))
    self.techPointBackground:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.techPointBackground:SetLayer(kGUILayerInsight)
    self.techPointBackground:SetColor(Color(0.3,0.3,0.3,0.9))
    
    local topBar = GUIManager:CreateGraphicItem()
    topBar:SetSize(Vector(kTechPointSize.x,hBarHeight,0))
    topBar:SetPosition(Vector(0,-hBarHeight,0))
    topBar:SetTexture(kHorizontalBarTexture)
    topBar:SetTexturePixelCoordinates(unpack({0,2*hBarCoords.y,hBarTextureWidth,3*hBarCoords.y}))
    topBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    topBar:SetLayer(kGUILayerInsight)
    self.techPointBackground:AddChild(topBar)
    
    local leftBar = GUIManager:CreateGraphicItem()
    leftBar:SetSize(vBarSize)
    leftBar:SetPosition(Vector(-vBarSize.x,GUIScale(10),0))
    leftBar:SetTexture(kEdgeTexture)
    leftBar:SetTexturePixelCoordinates(unpack(leftBarCoords))
    leftBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    leftBar:SetLayer(kGUILayerInsight)
    self.techPointBackground:AddChild(leftBar)
    
    self.leftBar = leftBar
    
    local corner = GUIManager:CreateGraphicItem()
    corner:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*110),0))
    corner:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*55),0))
    corner:SetTexture(kFrameTexture)
    corner:SetTexturePixelCoordinates(unpack(cornerCoords))
    corner:SetAnchor(GUIItem.Left, GUIItem.Top)
    corner:SetLayer(kGUILayerInsight+1)
    self.techPointBackground:AddChild(corner)
    
    local top = GUIManager:CreateGraphicItem()
    top:SetSize(Vector(GUIScale(scale*146),GUIScale(scale*110),0))
    top:SetPosition(-Vector(GUIScale(scale*146),GUIScale(scale*55),0))
    top:SetTexture(kFrameTexture)
    top:SetTexturePixelCoordinates(unpack(topCoords))
    top:SetAnchor(GUIItem.Right, GUIItem.Top)
    top:SetLayer(kGUILayerInsight+1)
    self.techPointBackground:AddChild(top)
    
    local bottom = GUIManager:CreateGraphicItem()
    bottom:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*146),0))
    bottom:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*146),0))
    bottom:SetTexture(kFrameTexture)
    bottom:SetTexturePixelCoordinates(unpack(bottomCoords))
    bottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    bottom:SetLayer(kGUILayerInsight+1)
    self.techPointBackground:AddChild(bottom)
    
    isVisible = true
    
    self.techPointList = {}

end

function GUIInsight_TechPoints:Uninitialize()

    GUI.DestroyItem(self.techPointBackground)
    self.techPointBackground = nil

end

function GUIInsight_TechPoints:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    
    kTechPointSize = GUIScale(Vector(225, 40, 0))
    kIconSize = GUIScale(Vector(40, 40, 0))
    kTeamNameFontScale = GUIScale(Vector(1, 1, 0))
    kTeamInfoFontScale = GUIScale(Vector(0.95, 0.95, 0))
    vBarSize = GUIScale(Vector(25,kTechPointSize.y*0,0))
    
    self:Initialize()

end

function GUIInsight_TechPoints:SetIsVisible(bool)

    isVisible = bool
    self.techPointBackground:SetIsVisible(bool)

end

function GUIInsight_TechPoints:Update(deltaTime)

    if isVisible then
    
        local techPoints = InsightUI_GetTechPointData()
        local numTechPoints = table.count(techPoints)
        if numTechPoints > 0 then
        
            self.techPointBackground:SetIsVisible(true)
            -- resize guis if tech point size change
            if table.count(self.techPointList) ~= numTechPoints then
                self:ResizeList(self.techPointList, numTechPoints, self.techPointBackground)
                self.techPointBackground:SetSize(Vector(kTechPointSize.x, kTechPointSize.y * numTechPoints, 0))
                self.techPointBackground:SetPosition(Vector(-kTechPointSize.x, -kTechPointSize.y * numTechPoints,0))
                
                --self.techPointBackground:SetTexturePixelCoordinates(unpack({0,0,225 * 2,40*numTechPoints * 2}))
                
                --local vBarTextureHeight = (self.kTechPointSize.y*numTechPoints/hBarWidth) * vBarCoords.y
                vBarSize.y = kTechPointSize.y*numTechPoints-GUIScale(50)
                self.leftBar:SetSize(vBarSize)
                --self.leftBar:SetTexturePixelCoordinates(unpack({2*vBarCoords.x,0,3*vBarCoords.x,vBarTextureHeight}))
           end
            
            local currentPointIndex = 1
            for index, techPoint in pairs(self.techPointList) do
                local techPointRecord = techPoints[currentPointIndex]
                self:UpdateTechPoint(techPoint, techPointRecord, currentPointIndex)
                currentPointIndex = currentPointIndex + 1
            end
        else
            self.techPointBackground:SetIsVisible(false)
        end
        
    end

end

local function playAlertSound(team)

    if team == kTeam1Index then
        StartSoundEffect(kMarineAlertSound)
    elseif team == kTeam2Index then
        StartSoundEffect(kAlienAlertSound)
    end
    
end

-- teamIndex is unused, but could be used for MvM or AvA
local function GetTextureCoords(teamIndex, techId)
   
    if techId == kTechId.CommandStation then
        return {0,0,80,80}
    elseif techId == kTechId.Hive then
        return {0,80,80,160}
    elseif techId == kTechId.CragHive then
        return {80,0,160,80}
    elseif techId == kTechId.ShadeHive then
        return {80,80,160,160}
    elseif techId == kTechId.ShiftHive then
        return {80,160,160,240}
    else
        return {0,160,80,240}
    end

end

local function GetTeamColor(team)

    if team == kTeam1Index then
        return kBlueColor
    elseif team == kTeam2Index then
        return kRedColor
    else
        return kUnclaimedColor
    end

end

function GUIInsight_TechPoints:UpdateTechPoint(techPoint, techPointRecord, currentPointIndex)

    local currentTime = Shared.GetTime()

    local currentPosition = Vector(techPoint.Background:GetPosition())
    currentPosition.y = (currentPointIndex-1) * kTechPointSize.y
    techPoint.Background:SetPosition(currentPosition)
    techPoint.EntityId = techPointRecord.EntityIndex

    local storedValues = techPoint.StoredValues
    local background = techPoint.Background
    local name = techPoint.Name
    local info = techPoint.Info
    local icon = techPoint.Icon
    
    local team = techPointRecord.TeamNumber
    local healthFraction = techPointRecord.HealthFraction
    local alive = healthFraction > 0
    local builtFraction = techPointRecord.BuiltFraction
    local built = builtFraction >= 1
    local teamChanged = team ~= storedValues.Team
    local techId = techPointRecord.TechId
    local powerFraction = techPointRecord.PowerNodeFraction
    local location = Shared.GetString(techPointRecord.Location)

    if teamChanged then
    
        -- Update icon and colors
        storedValues.TeamColor = GetTeamColor(team)
        name:SetText(location)
        name:SetColor(storedValues.TeamColor)
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoords(team, techId)))

        background:SetColor(storedValues.TeamColor)
        info:SetColor(kInfoColor)

        -- Flash and alert when team changes
        if team > 0 then        
            
            storedValues.ClaimFlashTime = currentTime + kClaimFlashTime
            
            if not built then
            
                local text = string.format("%s Claimed", location)
                local icon = {Texture = kIconTexture, TextureCoordinates = GetTextureCoords(team, techId), Color = Color(1,1,1,0.5), Size = kIconSize}
                local info = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = storedValues.TeamColor, ShadowColor = Color(0,0,0,0.5)}
                local position = techPoint.Background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, team)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), kClaimColor)
                
            end
        else
            techPoint.Info2:SetText("-")
            techPoint.Info2:SetColor(kInfoColor) 
            
            if storedValues.Team > 0 then
                local text = string.format("%s Destroyed", location)
                local icon = {Texture = kIconTexture, TextureCoordinates = GetTextureCoords(storedValues.Team, storedValues.Type), Color = Color(1,1,1,0.5), Size = kIconSize}
                local alertinfo = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = storedValues.TeamColor, ShadowColor = Color(0,0.5,0.5,0.5)}
                local position = techPoint.Background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, alertinfo, storedValues.Team)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), kDeadColor)
            end
        end
        
        storedValues.eggCount = -1
        storedValues.Power = -1
        storedValues.Team = team
        
    end
        
    if techId ~= storedValues.Type then
        
        icon:SetTexturePixelCoordinates(unpack(GetTextureCoords(team, techId)))
        storedValues.Type = techId
        
    end
    
    if healthFraction ~= storedValues.Health or builtFraction ~= storedValues.Built then
        local infoText
        if team > 0 then
            
            if alive then
            
                if not teamChanged and healthFraction < storedValues.Health then
                    storedValues.DamageFlashTime = currentTime + kAttackFlashTime
                    if currentTime - lastAlertTime > kTimeBetweenAlerts then
                        lastAlertTime = currentTime
                        playAlertSound(team)
                    end
                end
            
                infoText = string.format("%d%%", math.ceil(healthFraction*100))
            
                if not built then
                
                    local builtStr
                    if team == kTeam1Index then
                        builtStr = "Built"
                    else
                        builtStr = "Grown"
                    end
                    local constructionStr = string.format(" (%d%% %s)", math.ceil(builtFraction*100), builtStr)
                    infoText = infoText .. constructionStr
                    
                elseif storedValues.Built < builtFraction then -- just finished building
                
                    local text = string.format("%s Finished", location)
                    local icon = {Texture = kIconTexture, TextureCoordinates = GetTextureCoords(team, techId), Color = Color(1,1,1,0.5), Size = kIconSize}
                    local alertinfo = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = storedValues.TeamColor, ShadowColor = Color(0,0.5,0.5,0.5)}
                    local position = techPoint.Background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                    local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, alertinfo, team)
                    GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), kInfoColor)

                end
                info:SetColor(kInfoColor)
                
            else
            
                infoText = "Destroyed"
                info:SetColor(kDeadColor)

            end

        else
            infoText = "Unclaimed"
            info:SetColor(kInfoColor)
        end
        
        info:SetText(infoText)
        
        storedValues.Health = healthFraction
        storedValues.Built = builtFraction
        
    end
    
    if team == kTeam1Index then
        if powerFraction ~= storedValues.Power then
        
            if not teamChanged and powerFraction < storedValues.Power then
                storedValues.DamageFlashTime = currentTime + kAttackFlashTime
                if currentTime - lastAlertTime > kTimeBetweenAlerts then
                    lastAlertTime = currentTime
                    playAlertSound(team)
                end
            end

            local powerText = string.format("Power: %d%%", math.ceil(powerFraction*100))
            techPoint.Info2:SetText(powerText)
            techPoint.Info2:SetColor(kBlueColor)
            storedValues.Power = powerFraction
        end
    elseif team == kTeam2Index then
        local eggcount = techPointRecord.EggCount
        if eggcount ~= storedValues.eggCount then
            techPoint.Info2:SetText("Eggs: " .. tostring(eggcount))
            techPoint.Info2:SetColor(kRedColor)
            storedValues.eggCount = eggCount
        end
    end    
    
    -- Flash if necessary
    local flashDamage = currentTime < storedValues.DamageFlashTime
    local flashClaim = currentTime < storedValues.ClaimFlashTime
    local teamColor = storedValues.TeamColor
    if flashDamage or flashClaim then
    
        local intensity = math.sin(2*currentTime)
        intensity = intensity*intensity
        local flashColor
        
        if flashDamage then
            flashColor = kDeadColor
        elseif flashClaim then
            flashColor = kClaimColor
        end
        
        local blendedColor = LerpColor(teamColor, flashColor, intensity)
        background:SetColor(blendedColor)
        name:SetColor(blendedColor)
        
    else
    
        background:SetColor(teamColor)
        name:SetColor(teamColor)
        
    end
    
end

function GUIInsight_TechPoints:SendKeyEvent( key, down )

    if isVisible and key == InputKey.MouseButton0 and down then

        local cursor = MouseTracker_GetCursorPos()
        local inside, posX, posY = GUIItemContainsPoint( self.techPointBackground, cursor.x, cursor.y )
        if inside then

            local index = math.floor( posY / kTechPointSize.y ) + 1
            local entityId = self.techPointList[index].EntityId
            -- Teleport to the mapblip with the same entityId
            for _, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do
            
                if blip.ownerEntityId == entityId then
                
                    local player = Client.GetLocalPlayer()
                    local blipOrig = blip:GetOrigin()
                    player:SetWorldScrollPosition(blipOrig.x-5, blipOrig.z)
                    return true
                    
                end
                
            end
            
        end
        
    end

    return false

end

function GUIInsight_TechPoints:CreateBackground()

    -- Create background.
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kTechPointSize)
    background:SetTexture(kTechPointTexture)
    background:SetTexturePixelCoordinates(unpack({0,0,432,80}))
    background:SetAnchor(GUIItem.Left, GUIItem.Top)
    
    -- Type icon item (Weapon/Class/CommandStructure)
    local typeIcon = GUIManager:CreateGraphicItem()
    typeIcon:SetSize(kIconSize)
    typeIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    typeIcon:SetTexture(kIconTexture)
    typeIcon:SetTexturePixelCoordinates(unpack({0,160,80,240}))
    background:AddChild(typeIcon)

    -- Name text item. (Player Name / Structure Location)
    local nameItem = GUIManager:CreateTextItem()
    nameItem:SetFontName(kFontName)
    nameItem:SetScale(kTeamNameFontScale)
    nameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    nameItem:SetTextAlignmentX(GUIItem.Align_Min)
    nameItem:SetTextAlignmentY(GUIItem.Align_Min)
    nameItem:SetPosition(Vector(kIconSize.x, 0, 0))
    nameItem:SetColor(kInfoColor)
    background:AddChild(nameItem)

    -- Info text item.
    local infoItem = GUIManager:CreateTextItem()
    infoItem:SetFontName(kFontName)
    infoItem:SetScale(kTeamInfoFontScale)
    infoItem:SetAnchor(GUIItem.Left, GUIItem.Middle)
    infoItem:SetTextAlignmentX(GUIItem.Align_Min)
    infoItem:SetTextAlignmentY(GUIItem.Align_Min)
    infoItem:SetPosition(Vector(kIconSize.x+4, 0, 0))
    infoItem:SetColor(kInfoColor)
    background:AddChild(infoItem)
    
    local infoItem2 = GUIManager:CreateTextItem()
    infoItem2:SetFontName(kFontName)
    infoItem2:SetScale(kTeamInfoFontScale)
    infoItem2:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    infoItem2:SetTextAlignmentX(GUIItem.Align_Max)
    infoItem2:SetTextAlignmentY(GUIItem.Align_Max)
    infoItem2:SetColor(kInfoColor)
    infoItem2:SetPosition(-Vector(4, 0, 0))
    infoItem2:SetText("-")
    background:AddChild(infoItem2)
    
    return { Background = background,  Name = nameItem, Icon = typeIcon, Info = infoItem, Info2 = infoItem2,
            StoredValues = { Team = -1, TeamColor = kUnclaimedColor, Health = -1, Built = 1, Type = -1, ClaimFlashTime = -1, DamageFlashTime = -1 }
           }

end

-----------
-- Other --
-----------

function GUIInsight_TechPoints:ResizeList(list, listCount, GUIItem)

    while table.count(list) > listCount do
        local reuseItem = list[1]
        GUIItem:RemoveChild(reuseItem["Background"])
        reuseItem["Background"]:SetIsVisible(false)
        table.insert(self.reusebackgrounds, reuseItem)
        table.remove(list, 1)
    end

    while table.count(list) < listCount do
        local newItem = self:CreateBackground()
        table.insert(list, newItem)
        GUIItem:AddChild(newItem["Background"])
        newItem["Background"]:SetIsVisible(true)
    end

end