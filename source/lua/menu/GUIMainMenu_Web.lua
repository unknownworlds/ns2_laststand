// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu_Web.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIWebView.lua")

local webView = nil

function SetMenuWebView(url, size)

    if webView then
        GetGUIManager():DestroyGUIScript(webView)
    end
    
    webView = GetGUIManager():CreateGUIScript("GUIWebView")
    webView:LoadUrl(url, size.x, size.y)
    webView:DisableMusic()
    
    webView:GetBackground():SetAnchor(GUIItem.Middle, GUIItem.Center)
    webView:GetBackground():SetPosition(-webView:GetBackground():GetSize() / 2)
    webView:GetBackground():SetLayer(kGUILayerMainMenuWeb)
    webView:GetBackground():SetIsVisible(true)
    
end