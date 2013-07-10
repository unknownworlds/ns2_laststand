// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. ======
//
// lua\menu\Table.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more inTableation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/menu/TableRow.lua")
Script.Load("lua/menu/TableUtility.lua")

local kDefaultTableWidth = 200
local kDefaultColumnHeight = 64
local kDefaultBackgroundColor = Color(0.5, 0.5, 0.5, 0.4)

class 'Table' (MenuElement)

// called after the table has changed (style or data)
function Table:RenderTable()

    if self.tableData ~= nil and #self.tableData > 0 then
    
        for index, rowData in ipairs(self.tableData) do
            self:SetRowOffset(rowData.row, index)
        end
        
    end
    
end

function Table:SetRowOffset(row, index)

    local yOffset
    local yOffset0 = self:GetCellPadding() + self:GetVerticalCellPadding()
    local yOffset1 = row:GetHeight() + self:GetCellPadding() + self:GetVerticalCellPadding() + self:GetCellSpacing()
    local tableWidth = self:GetWidth()
    
    yOffset = yOffset0 + (index - 1) * yOffset1
    
    row:SetTopOffset( yOffset )
    row:SetWidth(tableWidth)
    row:SetRowNum(index)
    
    yOffset = yOffset + yOffset1
    
    self:SetHeight(yOffset - self:GetCellSpacing())
    
end

function Table:Initialize()

    MenuElement.Initialize(self)
    
    self:SetWidth(kDefaultTableWidth)
    self:SetBackgroundColor(kDefaultBackgroundColor)
    self.columnHeight = kDefaultColumnHeight
    
    self.rowNames = nil
    
    self.cellSpacing = 0
    self.cellPadding = 0
    self.verticalCellPadding = 0
    
    self.comparator = function(a, b) -- default sorting by ping
        return tonumber(a[5]) > tonumber(b[5])
    end
    
end

function Table:GetCellSpacing()
    return self.cellSpacing
end

function Table:GetCellPadding()
    return self.cellPadding
end

function Table:GetVerticalCellPadding()
    return self.verticalCellPadding
end

function Table:SetCellSpacing(cellSpacing)
    self.cellSpacing = cellSpacing
end

function Table:SetCellPadding(cellPadding)
    self.cellPadding = cellPadding
end

function Table:SetVerticalCellPadding(cellPadding)
    self.verticalCellPadding = cellPadding
end

function Table:GetTagName()
    return "table"
end

function Table:SetRowCreateCallback(callback)
    self.rowCreateCallback = callback
end

function Table:SetColumnClassNames(columnClassNames)    
    self.columnClassNames = columnClassNames    
end

function Table:SetEntryCallbacks(callbacks)
    self.entryCallbacks = callbacks
end

function Table:GetColumnClassName(index)

    if self.columnClassNames then
        return self.columnClassNames[index]
    end
    
    return nil
    
end

function Table:SetRowPattern(rowPattern)
    self.rowPattern = rowPattern
end

function Table:SetSortRow(value)
    self.sortRow = value == true
end

function Table:SetComparator(comparator)

    self.comparator = comparator
    self:Sort()
    
end

function Table:Sort()

    if self.comparator and self.sortRow and self.tableData ~= nil then
    
        table.sort(self.tableData, self.comparator)
        self:RenderTable()
        
    end
    
end

function Table:SetTableData(tableData)

    self:ClearChildren()
    
    if self.sortRow and tableData ~= nil then
        table.sort(tableData, self.comparator)
    end    
    
    for _, rowData in ipairs(tableData) do  
    
        local id = 0
        if rowData.row then
            id = rowData.row:GetId()
        end
        
        rowData.row = CreateMenuElement(self, 'TableRow', false)
        rowData.row:SetId(id)
        
        if self.rowCreateCallback then
            self.rowCreateCallback(rowData.row)
        end
        
        rowData.row:SetRowData(rowData, self.rowPattern, self.entryCallbacks)
        
    end
    
    self.tableData = tableData
    
    self:ReloadCSSClass()
    
end

function Table:AddRow(rowData, id)

    PROFILE("Table:AddRow")
    
    if not self.tableData then
        self.tableData = { }
    end
    
    rowData.row = CreateMenuElement(self, 'TableRow', false)
    
    if self.rowCreateCallback then
        self.rowCreateCallback(rowData.row)
    end
    
    rowData.row:SetId(id)    
    rowData.row:SetRowData(rowData, self.rowPattern, self.entryCallbacks)
    rowData.row:ReloadCSSClass()
    
    local index = #self.tableData + 1
    if self.sortRow then
    
        for i, row in ipairs(self.tableData) do  
        
            if self.comparator(row,rowData) then
            
                index = i
                break
                
            end
            
        end
        table.insert(self.tableData, index, rowData)
        
    else
        table.insert(self.tableData, rowData)
    end
    
    self:SetRowOffset(rowData.row, index)
    
end

function Table:UpdateRowData(rowIndex, rowData)

    local row = self.tableData[rowIndex].row
    row:ClearChildren()
    row:SetRowData(rowData, self.rowPattern, self.entryCallbacks)
    row:ReloadCSSClass()
    
end

function Table:ClearChildren()

    MenuElement.ClearChildren(self)
    
    self.tableData = { }

end

function Table:SetCSSClass(cssClassName, updateChildren)

    MenuElement.SetCSSClass(self, cssClassName, updateChildren)

    if self.tableData then
        self:RenderTable()
    end
    
end