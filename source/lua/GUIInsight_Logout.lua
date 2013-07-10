// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_Logout.lua
//
// Created by: Jon 'Huze' Hughes
//
// Manages displaying spectator logout button in addition to 
// sending the player to the readyroom when pressed.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_Logout' (GUIScript)

local kBackgroundTexture = "ui/location.dds"
local kFontName = "fonts/AgencyFB_large.fnt"
local kFontScale = GUIScale(Vector(1, 1, 0))

local kMouseOverColor = Color(0.7, 0.7, 1, 1)
local kDefaultColor = Color(1, 1, 1, 1)

function GUIInsight_Logout:Initialize()

    local ratio = 3.65789474 -- preserve aspect ratio of background image
    local size = GUIScale(Vector(100*ratio,100,0))
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(size)
    self.background:SetTexture(kBackgroundTexture)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.background:SetTexturePixelCoordinates(unpack({556,0,0,152}))
    self.background:SetPosition(Vector(-size.x, GUIScale(-10), 0))
    
    self.logoutText = GUIManager:CreateTextItem()
    self.logoutText:SetFontName(kFontName)
    self.logoutText:SetScale(kFontScale)
    self.logoutText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.logoutText:SetTextAlignmentX(GUIItem.Align_Max)
    self.logoutText:SetTextAlignmentY(GUIItem.Align_Center)
    self.logoutText:SetPosition(GUIScale(Vector(-10, -3, 0)))
    self.logoutText:SetColor(Color(1, 1, 1, 1))
    self.logoutText:SetText(Locale.ResolveString("MENU_RETURN"))
    self.logoutText:SetLayer(kGUILayerLocationText)
    self.background:AddChild(self.logoutText)

    local locationTextBack = GUIManager:CreateTextItem()
    locationTextBack:SetFontName(kFontName)
    locationTextBack:SetScale(kFontScale)
    locationTextBack:SetAnchor(GUIItem.Right, GUIItem.Center)
    locationTextBack:SetTextAlignmentX(GUIItem.Align_Max)
    locationTextBack:SetTextAlignmentY(GUIItem.Align_Center)
    locationTextBack:SetPosition(GUIScale(Vector(-13, 0, 0)))
    locationTextBack:SetColor(Color(0, 0, 0, 0.9))
    locationTextBack:SetText(Locale.ResolveString("MENU_RETURN"))
    locationTextBack:SetLayer(kGUILayerLocationText - 1)
    self.background:AddChild(locationTextBack)
    
    self:Update(0)
    
end

function GUIInsight_Logout:Uninitialize()

    if self.background then
    
        GUI.DestroyItem(self.background)
        self.background = nil
        
    end

end
    
function GUIInsight_Logout:SendKeyEvent(key, down)

    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
    
        self.mousePressed = down
        // Check if the button was pressed.
        if not self.mousePressed then
        
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
            if containsPoint then
            
                Shared.ConsoleCommand("ReadyRoom")
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function GUIInsight_Logout:Update(deltaTime)

    PROFILE("GUIInsight_Logout:Update")
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
    if containsPoint then
        self.background:SetColor(kMouseOverColor)
    else
        self.background:SetColor(kDefaultColor)
    end
    
end