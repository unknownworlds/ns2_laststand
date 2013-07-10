// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\graphs\LineGraph.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// LineGraph!
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'LineGraph'

local kTitleFontName = "fonts/AgencyFB_medium.fnt"
local kFontName = "fonts/AgencyFB_small.fnt"
local kFontScale = GUIScale(Vector(1,1,0))
local gridColor = Color(1,1,1,0.1)
local fontColor = Color(1,1,1,1)
local xPadding = GUIScale(Vector(0,10,0))
local yPadding = GUIScale(Vector(-10,0,0))

function LineGraph:Initialize()

    self.max = Vector(-999999999, -999999999, 0)
    self.min = Vector(999999999, 999999999, 0)

    self.graphSize = Vector(300,150,0)
    self.gridSpacing = Vector(1,1,0)
    self.xAxisIsTime = false
    self.xAxisToBounds = false

    self.lines = {}
    self.colors = {}

    self.xActiveNames = {}
    self.yActiveNames = {}
    self.reuseNames = {}

    self.graphBackground = GUIManager:CreateGraphicItem()
    self.graphBackground:SetSize(self.graphSize)
    self.graphBackground:SetColor(Color(0,0,0.1,0.9))
    self.graphBackground:SetLayer(kGUILayerInsight)

    self.titleItem = GUIManager:CreateTextItem()
    self.titleItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.titleItem:SetFontName(kTitleFontName)
    self.titleItem:SetScale(kFontScale)
    self.titleItem:SetTextAlignmentX(GUIItem.Align_Center)
    self.titleItem:SetTextAlignmentY(GUIItem.Align_Max)
    self.titleItem:SetColor(fontColor)
    self.graphBackground:AddChild(self.titleItem)
    
    self.xLabelItem = GUIManager:CreateTextItem()
    self.xLabelItem:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.xLabelItem:SetFontName(kFontName)
    self.xLabelItem:SetScale(kFontScale)
    self.xLabelItem:SetTextAlignmentX(GUIItem.Align_Center)
    self.xLabelItem:SetTextAlignmentY(GUIItem.Align_Min)
    self.xLabelItem:SetColor(fontColor)
    self.graphBackground:AddChild(self.xLabelItem)
    
    self.yLabelItem = GUIManager:CreateTextItem()
    self.yLabelItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.yLabelItem:SetFontName(kFontName)
    self.yLabelItem:SetScale(kFontScale)
    self.yLabelItem:SetTextAlignmentX(GUIItem.Align_Max)
    self.yLabelItem:SetTextAlignmentY(GUIItem.Align_Center)
    self.yLabelItem:SetColor(fontColor)
    self.graphBackground:AddChild(self.yLabelItem)

    self.xGridLines = GUIManager:CreateLinesItem()
    self.graphBackground:AddChild(self.xGridLines)
    
    self.yGridLines = GUIManager:CreateLinesItem()
    self.graphBackground:AddChild(self.yGridLines)

    self.plotLines = GUIManager:CreateLinesItem()
    self.graphBackground:AddChild(self.plotLines)
    
end

function LineGraph:StartLine(index, lineColor)

    self.lines[index] = {}
    self.colors[index] = lineColor

end
function LineGraph:SetPoints(index, points, noRefresh, preserveBounds)

    self.lines[index] = points

end

function LineGraph:GiveParent(p)
    p:AddChild(self.graphBackground)
end
function LineGraph:SetIsVisible(b)
    self.graphBackground:SetIsVisible(b)
end
function LineGraph:Destroy()
    GUI.DestroyItem(self.graphBackground)
end
function LineGraph:SetPosition(p)
    self.graphBackground:SetPosition(p)
end
function LineGraph:SetAnchor(x,y)
    self.graphBackground:SetAnchor(x,y)
end
function LineGraph:SetSize(s)
    self.graphSize = s
    self.graphBackground:SetSize(s)
    self:refreshGrid()
    self:refreshLines()
end
function LineGraph:SetTitle(t)
    self.titleItem:SetText(t)
end
function LineGraph:SetLabels(x,y)
    self.xLabelItem:SetText(x)
    self.yLabelItem:SetText(y)
end
local function adjustUpperBound(bound, spacing)
    local r = bound%spacing
    if r == 0 then
        return bound
    end
    return bound - r + spacing
end
local function adjustLowerBound(bound, spacing)
    local r = bound%spacing
    if r == 0 then
        return bound
    end
    return bound - r - spacing
end
function LineGraph:adjustBoundsToGridSpacing()
    self.max.y = adjustUpperBound(self.max.y, self.gridSpacing.y)
    --self.min.y = adjustLowerBound(self.min.y, self.gridSpacing.y)
end
function LineGraph:SetXGridSpacing(x)
    if self.gridSpacing.x ~= x then
        self.gridSpacing.x = x
        self:refreshGrid(false, true)
    end
end
function LineGraph:SetYGridSpacing(y)
    if self.gridSpacing.y ~= y then
        self.gridSpacing.y = y
        self:adjustBoundsToGridSpacing()
        self:refreshGrid(true, false)
    end
end    
function LineGraph:SetXBounds(n,x,ignoreLines)
    self.min.x = n
    self.max.x = x
    self:refreshGrid(false, true)
    if not ignoreLines then
        self:refreshLines()
    end
end
function LineGraph:SetYBounds(n,y,ignoreLines)
    self.min.y = n
    self.max.y = y
    self:adjustBoundsToGridSpacing()
    self:refreshGrid(true, false)
    if not ignoreLines then
        self:refreshLines()
    end
end
function LineGraph:SetXAxisIsTime(bool)
    self.xAxisIsTime = bool
    self:refreshGrid(false, true)
end
function LineGraph:ExtendXAxisToBounds(bool)
    self.xAxisToBounds = bool
    self:refreshLines()
end



function LineGraph:toGameTimeString(timeInt)

    local startTime = PlayerUI_GetGameStartTime()

    if startTime ~= 0 then
        startTime = timeInt - startTime
    end

    local minutes = math.floor(startTime/60)
    local seconds = startTime - minutes*60
    return string.format("%d:%02d", minutes, seconds)

end

function LineGraph:scalePoint(point)
    return Vector(((point.x - self.min.x)/(self.max.x - self.min.x)) * self.graphSize.x, self.graphSize.y - ((point.y - self.min.y)/(self.max.y - self.min.y)) * self.graphSize.y,0)
end

function LineGraph:refreshLines()

    self.plotLines:ClearLines()
    for l = 1, #self.lines do
        local linePoints = self.lines[l]
        local color = self.colors[l]
        -- scale and plot points
        if #linePoints > 0 then
            local previous = self:scalePoint(linePoints[1])
            for i = 2, #linePoints do
                local current = self:scalePoint(linePoints[i])
                self.plotLines:AddLine(previous, current, color)
                previous = current
            end
            if self.xAxisToBounds then
                local lastPoint = linePoints[#linePoints]
                if lastPoint then
                    local pointAtBounds = Vector(self.max.x, lastPoint.y, 0)
                    local toBounds = self:scalePoint(pointAtBounds)
                    self.plotLines:AddLine(previous, toBounds, color)
                end
            end
        end
    end
end

function LineGraph:freeNameItem(index, isX)

    local nameItem
    if isX then
        nameItem = table.remove(self.xActiveNames, index)
    else
        nameItem = table.remove(self.yActiveNames, index)
    end
    
    if nameItem then
        nameItem:SetIsVisible(false)
        table.insert(self.reuseNames, nameItem) 
    end

end

function LineGraph:getNameItem(isX)

    local nameItem

    if #self.reuseNames > 0 then
        nameItem = table.remove(self.reuseNames, 1)
        nameItem:SetIsVisible(true)
    else
        nameItem = GUIManager:CreateTextItem()
        nameItem:SetFontName(kFontName)
        nameItem:SetScale(kFontScale)
        nameItem:SetColor(fontColor)
        self.graphBackground:AddChild(nameItem)
    end
    if isX then
        table.insert(self.xActiveNames, nameItem)
    else
        table.insert(self.yActiveNames, nameItem)
    end
    return nameItem
end

function LineGraph:refreshGrid(ignoreX, ignoreY)
    
    if not ignoreX then    
        self.xGridLines:ClearLines()
        for i = 1, #self.xActiveNames do
            self:freeNameItem(1, true)
        end
        for x = self.min.x, self.max.x, self.gridSpacing.x do
        
            local xOffset = self:scalePoint(Vector(x,self.min.y,0))
            self.xGridLines:AddLine(xOffset - Vector(0,self.graphSize.y,0), xOffset, gridColor)
            
            local lineString
            if self.xAxisIsTime then
                lineString = self:toGameTimeString(x)
            else
                lineString = tostring(x)
            end
            local nameItem = self:getNameItem(true)
            nameItem:SetText(lineString)
            nameItem:SetTextAlignmentX(GUIItem.Align_Center)
            nameItem:SetTextAlignmentY(GUIItem.Align_Min)
            nameItem:SetPosition(xOffset + xPadding)
            
        end
    end
    
    if not ignoreY then    
        self.yGridLines:ClearLines()
        for i = 1, #self.yActiveNames do
            self:freeNameItem(1, false)
        end
        for y = self.min.y, self.max.y, self.gridSpacing.y do
        
            local yOffset = self:scalePoint(Vector(self.min.x,y,0))
            self.yGridLines:AddLine(yOffset, yOffset + Vector(self.graphSize.x,0,0), gridColor)
            
            local lineString = tostring(y)
            local nameItem = self:getNameItem(false)
            nameItem:SetText(lineString)
            nameItem:SetTextAlignmentX(GUIItem.Align_Max)
            nameItem:SetTextAlignmentY(GUIItem.Align_Center)
            nameItem:SetPosition(yOffset + yPadding)
            
        end
    end
end