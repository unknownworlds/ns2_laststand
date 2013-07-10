// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIList.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Graphical way to display a list of items.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIList' (GUIScript)

GUIList.kAlignment = enum( {'Left', 'Right', 'Top', 'Bottom'} )

function GUIList:Initialize()

    self.list = {}
    self.size = GUIScale(Vector(42, 42, 0))
    self.spacing = GUIScale(2)
    self.padding = GUIScale(Vector(0,0,0))
    self.moveRate = GUIScale(100)
    self.alignment = self.kAlignment.Left
    
    local bg = GUIManager:CreateGraphicItem()
    bg:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    bg:SetColor(Color(0.05,0.05,0.05,0.9))
    self.background = bg
    
end

function GUIList:Uninitialize()

    GUI.DestroyItem(self.background)
    self.list = nil

end
function GUIList:GetBackground()
    return self.background
end
function GUIList:SetColor(color)
    self.background:SetColor(color)
end
function GUIList:SetPosition(position)
    self.background:SetPosition(position)
end
function GUIList:SetAnchor(xAnchor,yAnchor)
    self.background:SetAnchor(xAnchor,yAnchor)
end
function GUIList:SetLayer(layer)
    self.background:SetLayer(layer)
end
function GUIList:SetSize(size)
    self.size = (size)
    repostion = function(item, i)
        item.Background:SetSize(size)
        item.Background:SetPosition(getLocation(self, i))
    end
    self:ForEach(reposition)
end
function GUIList:SetSpacing(spacing)
    self.spacing = spacing
end
function GUIList:SetPadding(padding)
    self.padding = padding
end
function GUIList.SetMoveRate(rate)
    self.moveRate = rate
end
function GUIList:SetAlignment(alignment)
    self.alignment = alignment
end
function GUIList:SetIsVisible(bool)
    self.background:SetIsVisible(bool)
end

local function LerpItem(item)

    local fraction = item.LerpFraction
    local background = item.Background

    local start = item.Start
    local stop = item.Stop

    background:SetPosition(LerpGeneric(start, stop, fraction))
    
end

local function getDistance(Start, Stop)

    local vector = Start-Stop
    local x = vector.x
    local y = vector.y
    return math.sqrt(x*x + y*y)

end

local function moveItem(self, item, stop)

    start = item.Background:GetPosition()
    local distance = getDistance(start, stop)
    item.LerpFraction = 0
    item.Velocity = self.moveRate / distance
    item.Start = start
    item.Stop = stop

end

local function getLocation(self, index)
    if self.alignment == self.kAlignment.Right then
        return index * Vector(-self.size.x - self.spacing, 0, 0)
    elseif self.alignment == self.kAlignment.Left then
        return (index-1) * Vector(self.size.x + self.spacing, 0, 0)
    elseif self.alignment == self.kAlignment.Bottom then
        return index * Vector(0, -self.size.y - self.spacing, 0)
    elseif self.alignment == self.kAlignment.Top then
        return (index-1) * Vector(0, self.size.y + self.spacing, 0)
    end
end

local function updateItem(self, item, i, deltaTime)
    if i ~= item.Index then
    
        item.Index = i
        moveItem(self, item, getLocation(self, i))
        
    end
    
    local fraction = item.LerpFraction
    if fraction and fraction < 1 then
        
        fraction = math.min(fraction + deltaTime * item.Velocity, 1)
        item.LerpFraction = fraction
        LerpItem(item)

    end
end

function GUIList:Update(deltaTime)
    
    for i = 1, #self.list do
        local item = self.list[i]
        updateItem(self, item, i, deltaTime)
    end
    
    if #self.list > 0 then
        local bgSize = Vector(0, self.size.y, 0) + self.list[#self.list].Background:GetPosition()
        if self.alignment == self.kAlignment.Left then
            bgSize.x = bgSize.x + self.size.x
        end
        self.background:SetSize(bgSize + self.padding)
    else
        self.background:SetSize(Vector(0,0,0))
    end
    
end

function GUIList:Create(id)
    local item = {}
    item.Id = id
    
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(self.size)
    item.Background = background
    
    self.background:AddChild(background)
    
    return item
end

function GUIList:Add(item, move)
    
    table.insert(self.list, item)
    item.Index = #(self.list)
    self.background:AddChild(item.Background)
    if move then
        moveItem(self, item, getLocation(self, item.Index))
    else
        item.Background:SetPosition(getLocation(self, item.Index))
    end
    
end

function GUIList:Remove(id)
    local item, i = self:Get(id)
    if item then
        GUI.DestroyItem(item.Background)
        table.remove(self.list, i)
    end
end

function GUIList:Get(id)
    for i = 1, #(self.list) do
        local item = self.list[i]
        if item.Id == id then
            return item, i
        end
    end
    return nil
end

function GUIList:ForEach(func)
    for i = 1, #(self.list) do
        local item = self.list[i]
        func(item, i)
    end
end