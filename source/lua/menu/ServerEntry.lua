// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. ======
//
// lua\menu\ServerEntry.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more inTableation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/menu/WindowUtility.lua")

kServerEntryHeight = 34 // little bit bigger than highlight server
local kDefaultWidth = 350
local kModeratePing = 90
local kBadPing = 180

local kFavoriteIconSize = Vector(26, 26, 0)
local kFavoriteIconPos = Vector(6, 4, 0)
local kFavoriteTexture = "ui/menu/favorite.dds"
local kNonFavoriteTexture = "ui/menu/nonfavorite.dds"

local kFavoriteMouseOverColor = Color(1,1,0,1)
local kFavoriteColor = Color(1,1,1,0.9)

local kPrivateIconSize = Vector(26, 26, 0)
local kPrivateIconPos = Vector(60, 4, 0)
local kPrivateIconTexture = "ui/lock.dds"

function SelectServerEntry(entry)

    local height = entry:GetHeight()
    local topOffSet = entry:GetBackground():GetPosition().y + entry:GetParent():GetBackground():GetPosition().y
    entry.scriptHandle.selectServer:SetBackgroundPosition(Vector(0, topOffSet, 0), true)
    entry.scriptHandle.selectServer:SetIsVisible(true)
    MainMenu_SelectServer(entry:GetId())
    
end

class 'ServerEntry' (MenuElement)

function ServerEntry:Initialize()

    self:DisableBorders()
    
    MenuElement.Initialize(self)
    
    // Has no children, but just to keep sure, we do that.
    self:SetChildrenIgnoreEvents(true)
    
    local eventCallbacks =
    {
        OnMouseIn = function(self, buttonPressed)
            MainMenu_OnMouseIn()
        end,
        
        OnMouseOver = function(self)
        
            local height = self:GetHeight()
            local topOffSet = self:GetBackground():GetPosition().y + self:GetParent():GetBackground():GetPosition().y
            self.scriptHandle.highlightServer:SetBackgroundPosition(Vector(0, topOffSet, 0), true)
            self.scriptHandle.highlightServer:SetIsVisible(true)
            
            if GUIItemContainsPoint(self.favorite, Client.GetCursorPosScreen()) then
                self.favorite:SetColor(kFavoriteMouseOverColor)
            else
                self.favorite:SetColor(kFavoriteColor)
            end
            
        end,
        
        OnMouseOut = function(self)
        
            self.scriptHandle.highlightServer:SetIsVisible(false)
            self.favorite:SetColor(kFavoriteColor)
            
        end,
        
        OnMouseDown = function(self, key, doubleClick)
        
            if GUIItemContainsPoint(self.favorite, Client.GetCursorPosScreen()) then
            
                if not self.serverData.favorite then
                
                    self.favorite:SetTexture(kFavoriteTexture)
                    self.serverData.favorite = true
                    SetServerIsFavorite(self.serverData, true)
                    
                else
                
                    self.favorite:SetTexture(kNonFavoriteTexture)
                    self.serverData.favorite = false
                    SetServerIsFavorite(self.serverData, false)
                    
                end
                
                self.parentList:UpdateEntry(self.serverData, true)
                
            else
            
                SelectServerEntry(self)
                
                if doubleClick then
                
                    if (self.timeOfLastClick ~= nil and (Shared.GetTime() < self.timeOfLastClick + 0.3)) then
                        self.scriptHandle:ProcessJoinServer()
                    end
                    
                else
                
                    // < 0 indicates that this server hasn't been queried yet.
                    // This happens when a server is a favorite and hasn't
                    // been downloaded yet.
                    if self:GetId() >= 0 then
                    
                        local function RefreshCallback(serverIndex)
                            MainMenu_OnServerRefreshed(serverIndex)
                        end
                        Client.RefreshServer(self:GetId(), RefreshCallback)
                        
                    else
                    
                        //local function RefreshCallback(name, ping, players)
                        //    MainMenu_OnServerRefreshed(serverIndex)
                        //end
                        //Client.RefreshServer(self.serverData.address, RefreshCallback)
                        
                    end
                    
                end
                
                self.timeOfLastClick = Shared.GetTime()
                
            end
            
        end
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    self.serverName = CreateTextItem(self, true)
    self.mapName = CreateTextItem(self, true)
    self.mapName:SetTextAlignmentX(GUIItem.Align_Center)
    self.ping = CreateTextItem(self, true)
    self.ping:SetTextAlignmentX(GUIItem.Align_Max)
    self.tickRate = CreateTextItem(self, true)
    self.tickRate:SetTextAlignmentX(GUIItem.Align_Center)
    self.modName = CreateTextItem(self, true)
    self.modName:SetTextAlignmentX(GUIItem.Align_Min)
    self.playerCount = CreateTextItem(self, true)
    self.playerCount:SetTextAlignmentX(GUIItem.Align_Max)
    
    self.favorite = CreateGraphicItem(self, true)
    self.favorite:SetSize(kFavoriteIconSize)
    self.favorite:SetPosition(kFavoriteIconPos)
    self.favorite:SetTexture(kNonFavoriteTexture)
    self.favorite:SetColor(kFavoriteColor)
    
    self.private = CreateGraphicItem(self, true)
    self.private:SetSize(kPrivateIconSize)
    self.private:SetPosition(kPrivateIconPos)
    self.private:SetTexture(kPrivateIconTexture)
    
    self:SetFontName("fonts/AgencyFB_small.fnt")
    
    self:SetTextColor(kWhite)
    self:SetHeight(kServerEntryHeight)
    self:SetWidth(kDefaultWidth)
    self:SetBackgroundColor(kNoColor)

end

function ServerEntry:SetParentList(parentList)
    self.parentList = parentList
end

function ServerEntry:SetFontName(fontName)

    self.serverName:SetFontName(fontName)
    self.mapName:SetFontName(fontName)
    self.ping:SetFontName(fontName)
    self.tickRate:SetFontName(fontName)
    self.modName:SetFontName(fontName)
    self.playerCount:SetFontName(fontName)

end

function ServerEntry:SetTextColor(color)

    self.serverName:SetColor(color)
    self.mapName:SetColor(color)
    self.ping:SetColor(color)
    self.tickRate:SetColor(color)
    self.modName:SetColor(color)
    self.playerCount:SetColor(color)
    
end

function ServerEntry:SetIsFiltered(filtered)
    self.filtered = filtered
end

function ServerEntry:GetIsFiltered()
    return self.filtered == true
end    

local function GetHasDataChanged(oldData, newData)

    return oldData == nil or newData == nil or
        oldData.numPlayers ~= newData.numPlayers or
        oldData.name ~= newData.name or
        oldData.modded ~= newData.modded or    
        oldData.rookieFriendly ~= newData.rookieFriendly or
        oldData.mapName ~= newData.mapName or
        oldData.ping ~= newData.ping or
        oldData.tickrate ~= newData.tickrate or
        oldData.requiresPassword ~= newData.requiresPassword or 
        oldData.mode ~= newData.mode or
        oldData.favorite ~= newData.favorite

end

function ServerEntry:SetServerData(serverData)

    PROFILE("ServerEntry:SetServerData")

    if self.serverData ~= serverData then
    
        self.playerCount:SetText(string.format("%d/%d", serverData.numPlayers, serverData.maxPlayers))
        if serverData.numPlayers >= serverData.maxPlayers then
            self.playerCount:SetColor(kRed)
        else
            self.playerCount:SetColor(kWhite)
        end 
     
        self.serverName:SetText(serverData.name)
        
        if serverData.rookieFriendly then
            self.serverName:SetColor(kGreen)
        else
            self.serverName:SetColor(kWhite)
        end
        
        self.mapName:SetText(serverData.map)
        
        self.ping:SetText(ToString(serverData.ping))    
        if serverData.ping >= kBadPing then
            self.ping:SetColor(kRed)
        elseif serverData.ping >= kModeratePing then
            self.ping:SetColor(kYellow)
        else    
            self.ping:SetColor(kGreen)
        end
        
        // It's possible for a server to not repsond with the tickrate
        if serverData.tickrate ~= nil then
            local performance = Clamp(serverData.tickrate / 30, 0, 1)
            self.tickRate:SetColor(Color(1 - performance, performance, performance - 0.8, 1))
            self.tickRate:SetText(string.format("%d %%", math.round(performance * 100)))
        else
            self.tickRate:SetColor(Color(0.5, 0.5, 0.5, 1))
            self.tickRate:SetText("??")
        end
        
        self.private:SetIsVisible(serverData.requiresPassword)
        
        self.modName:SetText(serverData.mode)
        if serverData.mode == "ns2" then
            self.modName:SetColor(kWhite)
        else
            self.modName:SetColor(kWhite)
        end
        
        if serverData.favorite then
            self.favorite:SetTexture(kFavoriteTexture)
        else
            self.favorite:SetTexture(kNonFavoriteTexture)
        end
        
        self:SetId(serverData.serverId)
        self.serverData = { }
        for name, value in pairs(serverData) do
            self.serverData[name] = value
        end
        
    end
    
end

local kUseVector = Vector(1, 0, 0)
function ServerEntry:SetWidth(width, isPercentage, time, animateFunc, callBack)

    if width ~= self.storedWidth then

        MenuElement.SetWidth(self, width, isPercentage, time, animateFunc, callBack)

        self.serverName:SetPosition(kUseVector * width * 0.08)
        self.modName:SetPosition(kUseVector * width * 0.49)
        self.mapName:SetPosition(kUseVector * width * 0.61)
        self.playerCount:SetPosition(kUseVector * width * 0.78)
        self.tickRate:SetPosition(kUseVector * width * 0.89)
        self.ping:SetPosition(kUseVector * width * 0.97)
        
        self.storedWidth = width
    
    end

end

function ServerEntry:Uninitialize()

    MenuElement.Uninitialize(self)

end

function ServerEntry:UpdateVisibility(minY, maxY, desiredY)

    if not self:GetIsFiltered() then

        if not desiredY then
            desiredY = self:GetBackground():GetPosition().y
        end
        
        local yPosition = self:GetBackground():GetPosition().y
        local ySize = self:GetBackground():GetSize().y
        
        local inBoundaries = ((yPosition + ySize) > minY) and yPosition < maxY
        self:SetIsVisible(inBoundaries)
        
    else
        self:SetIsVisible(false)
    end    

end

function ServerEntry:SetBackgroundTexture()
    Print("ServerEntry:SetBackgroundTexture")
end

// do nothing, save performance, save the world
function ServerEntry:SetCSSClass(cssClassName, updateChildren)
end

function ServerEntry:GetTagName()
    return "serverentry"
end

function ServerEntry:SetId(id)

    assert(type(id) == "number")
    self.rowId = id
    
end

function ServerEntry:GetId()
    return self.rowId
end