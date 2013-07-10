// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\GUIWebView.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIWebView' (GUIScript)

local webViewCount = 0
local kCloseButtonTexture = "ui/menu/closebutton.dds"
local kCloseButtonSize = Vector(16, 16, 0)
local kCloseButtonColors = { [true] = Color(1, 1, 1, 1), [false] = Color(0.7, 0.7, 0.7, 1) }

function GUIWebView:Initialize()
    self.buttonDown = { [InputKey.MouseButton0] = false, [InputKey.MouseButton1] = false, [InputKey.MouseButton2] = false }
end

/**
 * Disables music playback while the web view is open. This is useful if the
 * web view is going to play sound that might interfere with the music. The music
 * is automatically re-enabled when the web view is destroyed.
 */
function GUIWebView:DisableMusic()
    self.musicVolume = Client.GetMusicVolume()
    Client.SetMusicVolume(0)
end

local function Destroy(self)

    if self.musicVolume ~= nil then
        Client.SetMusicVolume(self.musicVolume)
    end

    if self.webView then
    
        Client.DestroyWebView(self.webView)
        self.webView = nil
        
    end
    
    if self.background then
    
        GUI.DestroyItem(self.background)
        self.background = nil
        
    end
    
    SetKeyEventBlocker(nil)
    
end

function GUIWebView:Uninitialize()
    Destroy(self)
end

function GUIWebView:LoadUrl(url, xSize, ySize)

    Destroy(self)
    
    // Create a unique texture name for each web view.
    webViewCount = webViewCount + 1
    local textureName = "*webview_" .. webViewCount
    
    self.webView = Client.CreateWebView(xSize, ySize)
    self.webView:SetTargetTexture(textureName)
    self.webView:LoadUrl(url)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(xSize, ySize + kCloseButtonSize.y, 0))
    self.background:SetColor(Color(0.3, 0.3, 0.3, 1))
    
    self.closeBackground = GUIManager:CreateGraphicItem()
    self.closeBackground:SetSize(kCloseButtonSize)
    self.closeBackground:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.closeBackground:SetPosition(Vector(-kCloseButtonSize.x - 2, 2, 0))
    self.closeBackground:SetColor(Color(0.2, 0.2, 0.2, 1))
    self.background:AddChild(self.closeBackground)
    
    self.loadingText = GUIManager:CreateTextItem()
    self.loadingText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.loadingText:SetTextAlignmentX(GUIItem.Align_Center)
    self.loadingText:SetTextAlignmentY(GUIItem.Align_Center)
    self.loadingText:SetText(Locale.ResolveString("LOADING"))
    self.loadingText:SetFontName("fonts/AgencyFB_large.fnt")
    self.background:AddChild(self.loadingText)
    
    self.webContainer = GUIManager:CreateGraphicItem()
    self.webContainer:SetSize(Vector(xSize, ySize, 0))
    self.webContainer:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.webContainer:SetPosition(Vector(-xSize / 2, (-ySize / 2) + kCloseButtonSize.y, 0))
    self.webContainer:SetTexture(textureName)
    self.background:AddChild(self.webContainer)
    
    self.close = GUIManager:CreateGraphicItem()
    self.close:SetSize(kCloseButtonSize)
    self.close:SetTexture(kCloseButtonTexture)
    self.closeBackground:AddChild(self.close)
    
    // Only allow this GUIWebView to receive Key Events.
    SetKeyEventBlocker(self)
    
end

function GUIWebView:GetBackground()

    assert(self.background, "WebView background accessed before loading a URL")
    return self.background
    
end

function GUIWebView:Update(deltaTime)

    if self.background then
    
        local mouseX, mouseY = Client.GetCursorPosScreen()
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.webContainer, mouseX, mouseY)
        if containsPoint or self.buttonDown[InputKey.MouseButton0] or self.buttonDown[InputKey.MouseButton1] or self.buttonDown[InputKey.MouseButton2] then
            self.webView:OnMouseMove(withinX, withinY)
        end
        
        local highlight = GUIItemContainsPoint(self.close, mouseX, mouseY)
        self.close:SetColor(kCloseButtonColors[highlight])
        
    end
    
end

function GUIWebView:SendKeyEvent(key, down, amount)

    if not self.background then
        return false
    end
    
    local isReleventKey = false
    
    if type(self.buttonDown[key]) == "boolean" then
        isReleventKey = true
    end
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    if isReleventKey then
    
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
        if down and not containsPoint then
        
            Destroy(self)
            return true
            
        end
        
        containsPoint, withinX, withinY = GUIItemContainsPoint(self.webContainer, mouseX, mouseY)
        
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
            
        elseif (key == InputKey.MouseButton0 and down and GUIItemContainsPoint(self.close, mouseX, mouseY)) then
        
            Destroy(self)
            return true
            
        end
        
    elseif key == InputKey.MouseZ then
        self.webView:OnMouseWheel((amount > 0) and 30 or -30, 0)
    elseif key == InputKey.Escape then
    
        Destroy(self)
        return true
        
    end
    
    return false
    
end