// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenuNews.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSizeX = 0.32
local kSizeY = 0.38
local kTextureName = "*mainmenu_news"
-- Non local so modders can easily change the URL.
kMainMenuNewsURL = "http://unknownworlds.com/ns2/ingamenews/"

class 'GUIMainMenuNews' (GUIScript)

function GUIMainMenuNews:Initialize()

    local xSize = kSizeX * Client.GetScreenWidth()
    local ySize = xSize
    self.webView = Client.CreateWebView(xSize, ySize)
    self.webView:SetTargetTexture(kTextureName)
    self.webView:LoadUrl(kMainMenuNewsURL)
    
    self.webContainer = GUIManager:CreateGraphicItem()
    self.webContainer:SetSize(Vector(xSize, ySize, 0))
    self.webContainer:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.webContainer:SetPosition(Vector(-xSize - 0.14 * Client.GetScreenWidth(), -ySize / 2, 0))
    self.webContainer:SetTexture(kTextureName)
    self.webContainer:SetLayer(kGUILayerMainMenuWeb)
	self.webContainer:SetIsVisible(false)
    
    self.buttonDown = { [InputKey.MouseButton0] = false, [InputKey.MouseButton1] = false, [InputKey.MouseButton2] = false }
    
end

function GUIMainMenuNews:Uninitialize()

    GUI.DestroyItem(mainMenu.newsView.webContainer)
    mainMenu.newsView.webContainer = nil
    
    Client.DestroyWebView(self.webView)
    self.webView = nil
    
end

function GUIMainMenuNews:SendKeyEvent(key, down, amount)

    local isReleventKey = false
    
    if type(self.buttonDown[key]) == "boolean" then
        isReleventKey = true
    end
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    if isReleventKey then
    
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.webContainer, mouseX, mouseY)
        
        // If we pressed the button inside the window, always send it the button up
        // even if the cursor was outside the window.
        if containsPoint or (not down and self.buttonDown[key]) then
        
            local buttonCode = key - InputKey.MouseButton0
            if down then
                self.webView:OnMouseDown(buttonCode)
            else
                self.webView:OnMouseUp(buttonCode)
            end
            
            self.buttonDown[key] = down
            
            return true
            
        end
        
    elseif key == InputKey.MouseZ then
    
        -- This isn't working currently as the input is blocked by the main menu code in
        -- MouseTracker_SendKeyEvent(). But it is a nice thought.
        self.webView:OnMouseWheel((amount > 0) and 30 or -30, 0)
        
    end
    
    return false
    
end

function GUIMainMenuNews:Update(deltaTime)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    local containsPoint, withinX, withinY = GUIItemContainsPoint(self.webContainer, mouseX, mouseY)
    if containsPoint or self.buttonDown[InputKey.MouseButton0] or self.buttonDown[InputKey.MouseButton1] or self.buttonDown[InputKey.MouseButton2] then
        self.webView:OnMouseMove(withinX, withinY)
    end
    
end

function GUIMainMenuNews:SetIsVisible(visible)
    --self.webContainer:SetIsVisible(visible)
end

function GUIMainMenuNews:LoadURL(url)
    self.webView:LoadUrl(url)
end

Event.Hook("Console_refreshnews", function() MainMenu_LoadNewsURL(kMainMenuNewsURL) end)