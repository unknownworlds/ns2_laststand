// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\TableRow.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inTableRowation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/menu/TableEntry.lua")

class 'TableRow' (MenuElement)

local kDefaultRowHeight = 16
local kDefaultRowWidth = 200
local kDefaultBackgroundColor = Color(0,0,0,0)

// called after the table has changed (style or data)
local function RenderRow(self)

    local parent = self:GetParent()

    if parent then
    
        local xOffset = parent:GetCellPadding()
        local currentEntryIndex = #self.children

        for index = 1, #self.children do
        
            local entry = self.children[currentEntryIndex]
        
            if parent then
                entry:SetCSSClass(parent:GetColumnClassName(index))
            end
            entry:SetLeftOffset(xOffset)
            
            local availableWidth = self:GetWidth() - xOffset - parent:GetCellPadding()
            
            if index == #self.children then
                entry:SetWidth(availableWidth)
            end
            
            if entry:GetWidth() > availableWidth then
                entry:SetWidth(availableWidth)
            end
            
            xOffset = xOffset + entry:GetWidth()/entry:GetScaleDivider() + parent:GetCellPadding() + parent:GetCellSpacing()
            currentEntryIndex = currentEntryIndex - 1
        
        end
    
    end

end

function TableRow:Initialize()

    MenuElement.Initialize(self)
    
    self:SetIgnoreMargin(true)
    self:SetHeight(kDefaultRowHeight)
    self:SetWidth(kDefaultRowWidth)
    self:SetBackgroundColor(kDefaultBackgroundColor)

end

function TableRow:SetRowNum(rowNum)
    self.rowNum = rowNum
end

function TableRow:GetRowNum()
    return self.rowNum
end

function TableRow:SetId(id)
    self.rowId = id
end

function TableRow:GetId()
    return self.rowId
end

function TableRow:GetTagName()
    return "row"
end

function TableRow:InformHeight(height)

    if height > self:GetHeight() then
        self:SetHeight(height)
    end
    
end

function TableRow:SetRowData(rowData, rowPattern, callbacks)

    for i, entryData in ipairs(rowData) do
    
        local entry = CreateMenuElement(self, 'TableEntry', false)

        if callbacks ~= nil and callbacks[i] ~= nil then
            entry:AddEventCallbacks( callbacks[i] )
        end
        
        if rowPattern and rowPattern[i] then
            rowPattern[i](entry, entryData)
        else
            RenderTextEntry(entry, entryData)
        end
        
    end
    
    RenderRow(self)
    
end

function TableRow:SetCSSClass(cssClassName, updateChildren)

    MenuElement.SetCSSClass(self, cssClassName, updateChildren)    
    
    RenderRow(self)
    
end

function TableRow:SetWidth(width, isPercentage, time, animateFunc, callBack)

    MenuElement.SetWidth(self, width, isPercentage, time, animateFunc, callBack)
    RenderRow(self)

end