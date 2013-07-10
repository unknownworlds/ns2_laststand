// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\ServerList.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/menu/ServerEntry.lua")

local kDefaultWidth = 350
local kDefaultColumnHeight = 64
local kDefaultBackgroundColor = Color(0.5, 0.5, 0.5, 0.4)

kFilterMaxPing = 600

class 'ServerList' (MenuElement)

local gLastSortType = 0
local gSortReversed = false

function UpdateSortOrder(sortType)

    if gLastSortType == sortType then
        gSortReversed = not gSortReversed
    else
        gSortReversed = false
    end
    
    gLastSortType = sortType
    
end

function SortByTickrate(a, b)

    local tickrate1 = tonumber(a.tickrate) or 0
    local tickrate2 = tonumber(b.tickrate) or 0
    
    if not gSortReversed then
        return tickrate1 > tickrate2
    else
        return tickrate1 < tickrate2
    end
    
end

function SortByPing(a, b)

    if not gSortReversed then
        return tonumber(a.ping) < tonumber(b.ping)
    else
        return tonumber(a.ping) > tonumber(b.ping)
    end
    
end

function SortByPlayers(a, b)

    if not gSortReversed then
        return tonumber(a.numPlayers) > tonumber(b.numPlayers)
    else
        return tonumber(a.numPlayers) < tonumber(b.numPlayers)
    end
    
end

function SortByPrivate(a, b)

    local aValue = a.requiresPassword and 1 or 0
    local bValue = b.requiresPassword and 1 or 0
    
    if not gSortReversed then
        return aValue > bValue
    else
        return aValue < bValue
    end
    
end

function SortByFavorite(a, b)

    local aValue = a.favorite and 1 or 0
    local bValue = b.favorite and 1 or 0
    
    if not gSortReversed then
        return aValue > bValue
    else
        return aValue < bValue
    end
    
end

function SortByMap(a, b)

    if not gSortReversed then
        return a.map:upper() > b.map:upper()
    else
        return a.map:upper() < b.map:upper()
    end
    
end

function SortByName(a, b)

    if not gSortReversed then
        return a.name:upper() > b.name:upper()
    else
        return a.name:upper() < b.name:upper()
    end
    
end

function SortByMode(a, b)

    if not gSortReversed then
        return a.mode:upper() > b.mode:upper()
    else
        return a.mode:upper() < b.mode:upper()
    end
    
end

function FilterServerMode(mode)
    return function(entry) return string.find(entry.mode, mode) ~= nil end
end

function FilterMapName(map)
    return function(entry) return string.find(entry.map, map) ~= nil end
end

function FilterMinRate(minrate)
    return function(entry) return Clamp(entry.tickrate / 30, 0, 1) >= minrate - 0.01 end
end

function FilterMaxPing(maxping)

    return function(entry)
    
        // Don't limit ping.
        if maxping == kFilterMaxPing then
            return true
        else
            return entry.ping <= maxping
        end
        
    end
    
end

function FilterEmpty(active)
    return function(entry) return not active or entry.numPlayers ~= 0 end
end

function FilterFull(active)
    return function(entry) return not active or entry.numPlayers < entry.maxPlayers end
end

function FilterModded(active)
    return function(entry) return not active or entry.modded == false end
end

function FilterFavoriteOnly(active)
    return function(entry) return not active or entry.favorite == true end
end

function FilterPassworded(active)
    return function(entry) return active or entry.requiresPassword == false end
end

function FilterRookie(active)
    return function(entry) return not active or entry.rookieFriendly == false end
end

local function CheckShowTableEntry(self, entry)

    for _, filterFunc in pairs(self.filter) do
    
        if not filterFunc(entry) then
            return false
        end
        
    end
    
    return true
    
end

local function GetBoundaries(self)

    local minY = -self:GetParent():GetContentPosition().y
    local maxY = minY + self:GetParent().contentStencil:GetSize().y
    
    return minY, maxY
    
end

// Called after the table has changed (style or data).
local function RenderServerList(self)

    PROFILE("ServerList:RenderServerList")

    local renderPosition = 0
    
    local serverListWidth = self:GetWidth()
    local serverListSize = #self.serverEntries
    local numServers = #self.tableData
    local lastSelectedServerId = MainMenu_GetSelectedServer()
    self.scriptHandle:ResetServerSelection()
    
    // Add, remove entries, but reuse as many GUIItems as possible.
    if serverListSize < numServers then
    
        for i = 1, numServers - serverListSize do
        
            local entry = CreateMenuElement(self, 'ServerEntry', false)
            entry:SetParentList(self)
            entry:SetWidth(serverListWidth)
            
            table.insert(self.serverEntries, entry)
            
            
        end
        
    elseif serverListSize > numServers then
    
        for i = 1, serverListSize - numServers do
        
            self.serverEntries[#self.serverEntries]:Uninitialize()
            table.remove(self.serverEntries, #self.serverEntries)
            
        end
        
    end
    
    local minY, maxY = GetBoundaries(self)
    
    for i = 1, #self.tableData do
    
        local serverEntry = self.serverEntries[i]
        
        if CheckShowTableEntry(self, self.tableData[i]) then

            serverEntry:SetBackgroundPosition(Vector(0, renderPosition * kServerEntryHeight, 0))
            serverEntry:SetServerData(self.tableData[i])
            
            if self.tableData[i].serverId == lastSelectedServerId then
                SelectServerEntry(serverEntry)
            end
                     
            renderPosition = renderPosition + 1
            serverEntry:SetIsFiltered(false)
            
        else
            serverEntry:SetIsFiltered(true)
        end
        
        serverEntry:UpdateVisibility(minY, maxY, renderPosition * kServerEntryHeight)
        
    end
    
    self:SetHeight(renderPosition * kServerEntryHeight)
    
end

function ServerList:Initialize()

    self:DisableBorders()
    
    MenuElement.Initialize(self)
    
    self:SetWidth(kDefaultWidth)
    self:SetBackgroundColor(kNoColor)
    
    self.tableData = { }
    self.serverEntries = { }
    self.filter = { }
    
    // Default sorting is set in GUIMainMenu.
    self.comparator = nil
    
end

function ServerList:Uninitialize()

    MenuElement.Uninitialize(self)
    
    self.tableData = { }
    self.serverEntries = { }
    
end

function ServerList:GetTagName()
    return "serverlist"
end

function ServerList:SetEntryCallbacks(callbacks)
    self.entryCallbacks = callbacks
end

function ServerList:SetComparator(comparator)

    self.comparator = comparator
    self:Sort(self.tableData)
    
end

function ServerList:OnParentSlide()

    local minY, maxY = GetBoundaries(self)
    
    for _, entry in ipairs(self.serverEntries) do        
        entry:UpdateVisibility(minY, maxY)    
    end

end

function ServerList:Sort(tableData)

    if self.comparator then
        table.sort(tableData, self.comparator)
    end
    
    RenderServerList(self)
    
end

function ServerList:SetTableData(tableData)

    if tableData then
    
        self:Sort(tableData)
        self.tableData = tableData
        
    end
    
end

function ServerList:ClearChildren()

    MenuElement.ClearChildren(self)
    
    self.tableData = { }
    self.serverEntries = { }
    
end

function ServerList:AddEntry(serverEntry, noRender)

    table.insert(self.tableData, serverEntry)
    if not noRender then
        RenderServerList(self)
    end
    
end

function ServerList:UpdateEntry(serverEntry, noRender)

    for s = 1, #self.tableData do
    
        if self.tableData[s].address == serverEntry.address then
        
            for k, v in pairs(serverEntry) do
                self.tableData[s][k] = v
            end
            break
            
        end
        
    end
    
    if not noRender then
        RenderServerList(self)
    end
    
end

function ServerList:RenderNow()
    RenderServerList(self)
end

function ServerList:GetEntryExists(serverEntry)

    for s = 1, #self.tableData do
    
        if self.tableData[s].address == serverEntry.address then
            return true
        end
        
    end
    
    return false
    
end

function ServerList:SetFilter(index, func)

    self.filter[index] = func
    RenderServerList(self)
    
end