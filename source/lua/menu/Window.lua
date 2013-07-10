// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Window.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Holds GUIItems for a window.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load('lua/menu/MenuElement.lua')
Script.Load('lua/menu/TitleBar.lua')
Script.Load('lua/menu/ResizeTile.lua')
Script.Load('lua/menu/ContentBox.lua')
Script.Load('lua/menu/SlideBar.lua')

local kDefaultWindowBackgroundColor = Color(0, 0, 0, 0.5)
local kDefaultWindowBackgroundSize = Vector(200, 170, 0)
local kDefaultWindowBorderWidth = 1

local kWindowMinWidth = 100
local kWindowMinHeight = 100

class 'Window' (MenuElement)

function Window:GetTagName()
    return "window"
end

function Window:Initialize()

    MenuElement.Initialize(self)
    
    self:SetIgnoreMargin(true)
    self:SetIsScaling(false)
    
    self:SetMinWidth(kWindowMinWidth)
    self:SetMinHeight(kWindowMinHeight)
    
    self.background:SetColor(kDefaultWindowBackgroundColor)
    self:SetBackgroundSize(kDefaultWindowBackgroundSize)    
    self:SetBorderWidth(kDefaultWindowBorderWidth)
    
    self:EnableTitleBar()
    self:EnableResizeTile()
    self:EnableSlideBar()
    self:EnableContentBox()
    
    self.canSetActive = true
    self.initialVisible = true
    self.canBeDragged = true
    
    local eventCallBacks = {
    
        OnMouseOver = function (self)
            if self.isResizing then
                local size = self:GetBackground():GetSize()
                size = size + MouseTracker_GetMouseMovement()
                self:SetBackgroundSize(size)
            end
        end,
        
        OnEscape = function (self)
            self:SetIsVisible(not self:GetIsVisible())
            return true
        end,
        
        OnScrollUp = function (self)
        
            if self.slideBar then
                self.slideBar:ScrollMax()
            end    
        
        end,
    
        OnScrollDown = function (self)
        
            if self.slideBar then
                self.slideBar:ScrollMin()
            end
        
        end,
        
        OnMouseWheel = function(self, up)
        
            if self.slideBar then
            
                if up then
                    self.slideBar:ScrollMin()
                else
                    self.slideBar:ScrollMax()
                end
                
            end
            
        end
    
    }
    
    self:AddEventCallbacks(eventCallBacks)

end

function Window:Uninitialize()

    if self.titleBar then
        self.titleBar:Uninitialize()
    end  
    
    MenuElement.Uninitialize(self)
    
end  

function Window:EnableCanSetActive()
    self.canSetActive = true
end

function Window:DisableCanSetActive()
    self.canSetActive = false
end    

function Window:GetCanSetActive()
    return self.canSetActive
end

function Window:SetIsVisible(isVisible)

    local setActive = isVisible and isVisible ~= self:GetIsVisible()
    
    if setActive then
        GetWindowManager():SetWindowActive(self, self.scriptHandle.windowLayer)
    end

    MenuElement.SetIsVisible(self, isVisible)   

end

// put all windows above ingame menues (buy menu, comm interface, etc)
function Window:SetLayer(layer)
    MenuElement.SetLayer(self, layer + kGUILayerMainMenu)
end

function Window:EnableTitleBar()

    if not self.titleBar then
    
        self.titleBar = CreateMenuElement(self, "TitleBar", false)
        self.titleBar:SetWidth(kDefaultWindowBackgroundSize.x)
        
        // we modify the variables directly here without access function, since the
        // window actually should 'know' about all sub elements. Assign the window
        // handle to the close button
        self.titleBar.closeButton.windowHandle = self

        self.titleBar.closeButton:AddEventCallbacks( { 
            OnClick = function(self)
                if self.windowHandle then
                    self.windowHandle:SetIsVisible(false)
                end
            end
        } )
        
    end
    
end

function Window:ResetSlideBar()

    if self.slideBar then
        self.slideBar:Reset()
    end
    
end

function Window:SetSlideBarVisible(isVisible)

    if self.slideBar then
        self.slideBar:SetIsVisible(isVisible)
    end

end

function Window:EnableSlideBar()

    if not self.slideBar then
    
        self.slideBar = CreateMenuElement(self, "SlideBar", false)
        self.slideBar:SetBackgroundSize(Vector(32, kDefaultWindowBackgroundSize.y, 0), true)
        self.slideBar:SetVertical()
        self.slideBar:AddClass("window_scroller")
        
        if self.contentBox then
            self.slideBar:Register(self.contentBox, SLIDE_VERTICAL)
        end
        
    end
    
end

function Window:EnableContentBox()

    if not self.contentBox then
    
        self.contentBox = CreateMenuElement(self, "ContentBox", false)
        self.contentBox:SetBackgroundSize(kDefaultWindowBackgroundSize, true)
        
        if self.slideBar then
            self.slideBar:Register(self.contentBox, SLIDE_VERTICAL)
        end
        
    end

end

function Window:DisableContentBox()

    if self.contentBox then
        self.contentBox:Uninitialize()
        self.contentBox = nil
    end

end

function Window:GetContentBox()
    return self.contentBox
end

function Window:SetCanBeDragged(canBeDragged)
    self.canBeDragged = canBeDragged
end

function Window:DisableTitleBar()

    if self.titleBar then
    
        self.titleBar:Uninitialize()
        self.titleBar = nil
        
    end
    
end

function Window:DisableCloseButton()

    if self.titleBar then
    
        self.titleBar.closeButton:Uninitialize()
        self.titleBar.closeButton = nil
        
    end
    
end

function Window:DisableSlideBar()

    if self.slideBar then
        self.slideBar:Uninitialize()
        self.slideBar = nil
    end

end

function Window:GetTitleBar()
    return self.titleBar
end    

local function GetTitleBarHeight(self)
    local height = 0
    if self.titleBar then
        height = self.titleBar:GetBackground():GetSize().y
    end
    return height
end

local function GetSlideBarWidth(self)
    local width = 0
    if self.slideBar then
        width = self.slideBar:GetBackground():GetSize().x
    end
    return width
end

function Window:GetMarginTop()
    return MenuElement.GetMarginTop(self) + GetTitleBarHeight(self)
end

function Window:GetMarginRight()
    return MenuElement.GetMarginRight(self) + GetSlideBarWidth(self)
end

function Window:OnChildChanged(child)

    if (child == self.titleBar or child == self.slideBar) and self.contentBox then
        self.contentBox:ReloadCSSClass()
    end
    
end

function Window:EnableResizeTile()

    if not self.resizer then
    
        self.resizer = CreateMenuElement(self, "ResizeTile", false)
        self.resizer:SetAnchor(GUIItem.Right, GUIItem.Bottom)
        
        self.resizer:SetBottomOffset(0)
        self.resizer:SetRightOffset(0)
    
    end

end

function Window:DisableResizeTile()
    
    if self.resizer then
        self.resizer:Uninitialize()
        self.resizer = nil
    end
    
end

function Window:SetWindowName(windowName, time, animateFunc, animName, callBack)
    self.windowName = windowName
end

function Window:GetWindowName()
    return self.windowName
end

function Window:SetBackgroundSize(sizeVector, absolute, time, animateFunc, animName, callBack)

    MenuElement.SetBackgroundSize(self, sizeVector, absolute, time, animateFunc, animName, callBack)

    if self.slideBar then
    
        local windowHeight = self:GetBackground():GetSize().y
        self.slideBar:SetHeight((windowHeight - self:GetMarginTop() - self:GetMarginBottom()) * self:GetScaleDivider())
        
    end

end