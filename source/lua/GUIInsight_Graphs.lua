// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_Graphs.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// Displays graphs and statistic information
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/graphs/LineGraph.lua")
Script.Load("lua/graphs/ComparisonBarGraph.lua")

class 'GUIInsight_Graphs' (GUIScript)

local graphPadding = GUIScale(50)
local isVisible
local maxRTs = 0
local maxRes = 0
local graphBackground
local tabBars = {}

local lineGraph
local compGraph

local tabSelected
//local compGraphNames = {"RTs Lost", "Resources Gathered", "Team Kills"}

local selectedColor = Color(0,0,0,0.9)
local deselectedColor = Color(0.1,0.1,0.1,0.9)

local kFontName = "fonts/AgencyFB_small.fnt"
local kFontScale = GUIScale(Vector(1,1,0))

local function createTab(index, text, size)
    local tabBar = GUIManager:CreateGraphicItem()
    tabBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    tabBar:SetSize(Vector(size/3, 50, 0))
    tabBar:SetPosition(Vector(index * size/3, -50, 0))
    tabBar:SetColor(deselectedColor)
    graphBackground:AddChild(tabBar)
    
    local title = GUIManager:CreateTextItem()
    title:SetAnchor(GUIItem.Middle, GUIItem.Center)
    title:SetFontName(kFontName)
    title:SetScale(kFontScale)
    title:SetTextAlignmentX(GUIItem.Align_Center)
    title:SetTextAlignmentY(GUIItem.Align_Center)
    title:SetText(text)
    tabBar:AddChild(title)
    
    return tabBar
end

function GUIInsight_Graphs:Initialize()
    
    isVisible = false
    
    local width = Client.GetScreenWidth()
    local height = Client.GetScreenHeight()
    
    // Hard coding graph size for Hugh, will make this configurable in the future
    local graphSize = Vector(800, 400, 0)
    local comparisonSize = GUIScale(Vector(400,30,0))
    local miniGraphSize = graphSize - Vector(2*graphPadding,3*graphPadding,0) - Vector(0,comparisonSize.y,0)

    graphBackground = GUIManager:CreateGraphicItem()
    graphBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    graphBackground:SetSize(graphSize)
    graphBackground:SetPosition(-graphSize/2)
    graphBackground:SetColor(selectedColor)
    graphBackground:SetLayer(kGUILayerInsight)
    graphBackground:SetIsVisible(isVisible)
    
    tabSelected = 1
    tabBars[1] = createTab(0, "Resource Towers", graphSize.x)
    tabBars[1]:SetColor(selectedColor)
    tabBars[2] = createTab(1, "Team Resources", graphSize.x)
    tabBars[3] = createTab(2, "Team Kills", graphSize.x)
        
    lineGraph = _G["LineGraph"]()
    lineGraph:Initialize()
    lineGraph:SetAnchor(GUIItem.Left, GUIItem.Top)
    lineGraph:SetSize(miniGraphSize)
    lineGraph:SetYGridSpacing(1)
    lineGraph:SetXAxisIsTime(true)
    lineGraph:ExtendXAxisToBounds(true)
    lineGraph:SetPosition(Vector(graphPadding,graphPadding,0))
    lineGraph:GiveParent(graphBackground)
    
    compGraph = _G["ComparisonBarGraph"]()
    compGraph:Initialize()
    compGraph:SetAnchor(GUIItem.Middle, GUIItem.Top)
    compGraph:SetSize(comparisonSize)
    compGraph:SetValues(0,0)
    compGraph:SetPosition(Vector(-comparisonSize.x/2, graphSize.y - graphPadding, 0))
    compGraph:GiveParent(graphBackground)
    
    lineGraph:StartLine(kTeam1Index, kBlueColor)
    lineGraph:StartLine(kTeam2Index, kRedColor)
    compGraph:SetValues(0,0)
    
end

function GUIInsight_Graphs:Uninitialize()
    
    GUI.DestroyItem(graphBackground)

end

function GUIInsight_Graphs:SetIsVisible(bool)
    isVisible = bool
    graphBackground:SetIsVisible(isVisible)
end

function GUIInsight_Graphs:SendKeyEvent(key, down)

    if down and GetIsBinding(key, "RequestHealth") then
        GUIInsight_Graphs:SetIsVisible(not isVisible)
        return true
    end
    
    local cursor = MouseTracker_GetCursorPos()
    if isVisible and down and key == InputKey.MouseButton0 then
        
        for index, tabBar in ipairs(tabBars) do
            local inside, posX, posY = GUIItemContainsPoint( tabBar, cursor.x, cursor.y )
            if inside then
                tabSelected = index                
            end
            tabBar:SetColor(deselectedColor)
        end
        tabBars[tabSelected]:SetColor(selectedColor)
        
    end
    
    return false
end

local function getXSpacing(time)

    if time < 60 then
        return 10
    elseif time < 5*60 then
        return 30
    elseif time < 15*60 then
        return 60
    elseif time < 60*60 then
        return 300
    else
        return 600
    end    

end

local function getYSpacing(value)

    if tabSelected == 1 then -- RTs
        return 1
    elseif tabSelected == 2 then -- Res
        if value < 100 then
            return 10
        elseif value < 500 then
            return 50
        elseif value < 1000 then
            return 100
        else
            return 200    
        end
    elseif tabSelected == 3 then -- Kills
        if value < 10 then
            return 1
        elseif value < 20 then
            return 2
        elseif value < 100 then
            return 10
        else
            return 25    
        end
    end
    
end

local function getBound()
    if tabSelected == 1 then -- RTs
        return Insight_GetMaxRTs()
    elseif tabSelected == 2 then -- Res
        return Insight_GetMaxRes()
    elseif tabSelected == 3 then -- Kills
        return Insight_GetMaxKills()
    end
end

local function GetPoints(index)

    local team = Insight_GetTeamData(index)
    if team then
    
        if tabSelected == 1 then -- RTs
            return team.RTPoints
        elseif tabSelected == 2 then -- Res
            return team.TeamResPoints
        elseif tabSelected == 3 then -- Kills
            return team.KillPoints
        end
        
    end
    
    return nil
    
end

local function GetBluePoints()
    return GetPoints(kTeam1Index)
end

local function GetRedPoints()
    return GetPoints(kTeam2Index)
end

local function getValue(index)
    local team = Insight_GetTeamData(index)
    if tabSelected == 1 then -- RTs
        return DeathMsgUI_GetRtsLost(index)
    elseif tabSelected == 2 then -- Res
        return team.TotalTeamRes
    elseif tabSelected == 3 then -- Kills
        return team.Kills
    end
end
    
local function getBlueValue()
    return getValue(kTeam1Index)
end

local function getRedValue()
    return getValue(kTeam2Index)
end

function GUIInsight_Graphs:Update(deltaTime)
    
    if isVisible and PlayerUI_GetHasGameStarted() then
    
        local time = Shared.GetTime()
            
        local bound = getBound()
        
        local redValue = getRedValue()
        local blueValue = getBlueValue()
    
        local startTime = PlayerUI_GetGameStartTime()
        
        lineGraph:SetXGridSpacing(getXSpacing(time - startTime))
        lineGraph:SetYGridSpacing(getYSpacing(bound))
        
        local bluePoints = GetBluePoints()
        if bluePoints then
            lineGraph:SetPoints(kTeam1Index, bluePoints)
        end
        
        local redPoints = GetRedPoints()
        if redPoints then
            lineGraph:SetPoints(kTeam2Index, redPoints)
        end
        
        lineGraph:SetYBounds(0, bound+1, true)
        lineGraph:SetXBounds(startTime, time)
        
        compGraph:SetValues(blueValue, redValue)
    end
    
end
