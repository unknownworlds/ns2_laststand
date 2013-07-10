
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICountDownDisplay.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages the damage arrows pointing to the source of damage.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICountDownDisplay' (GUIScript)

GUICountDownDisplay.kFontName = "fonts/Arial_15.fnt"
GUICountDownDisplay.kFontSize = 26
GUICountDownDisplay.kBorderHeight = 90
GUICountDownDisplay.kNameFrameHeight = 40
GUICountDownDisplay.kNameFontSize = 16

GUICountDownDisplay.kHeadLineFontSize = 26
GUICountDownDisplay.kMapNameFontColor = Color(1,1,0,1)

GUICountDownDisplay.kHeadLineXOffset = 100
GUICountDownDisplay.kHeadLineYOffset = 10

GUICountDownDisplay.kIconTexture = "ui/messages_icons.dds"
GUICountDownDisplay.kIconSize = Vector(128, 64, 0)
GUICountDownDisplay.kMarineIconTexCoords = { 0, 64, 128, 128}
GUICountDownDisplay.kAlienIconTexCoords = { 0, 704, 128, 768}

GUICountDownDisplay.kServerNameXOffset = 100
GUICountDownDisplay.kServerNameYOffset = 40
GUICountDownDisplay.kServerNameFontSize = 16


GUICountDownDisplay.kMarineLogoTexture = "ui/marine_logo_small.dds"
GUICountDownDisplay.kMarineLogoTexCoords = { 0, 0, 64, 96 }

GUICountDownDisplay.kAlienLogoTexture = "ui/alien_portraiticons.dds"
GUICountDownDisplay.kAlienLogoTexCoords = { 3, 164, 80, 240 }

GUICountDownDisplay.kBackgroundTexture = "ui/black_screen_borders.dds"

local kWelcomeMessage = Locale.ResolveString("WELCOME_TO")

function GUICountDownDisplay:Initialize()

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetTexture(GUICountDownDisplay.kBackgroundTexture)

    self.borderTop = GetGUIManager():CreateGraphicItem()
    self.borderTop:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.borderTop:SetSize(Vector(Client.GetScreenWidth(), GUICountDownDisplay.kBorderHeight, 0))
    self.borderTop:SetColor(Color(0,0,0,0))
    self.borderTop:SetLayer(kGUILayerCountDown)
    
    self.teamIcon = self:CreateTeamIcon()
    self.borderTop:AddChild(self.teamIcon)
    
    self.welcomeMessage = GetGUIManager():CreateTextItem()
    self.welcomeMessage:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.welcomeMessage:SetTextAlignmentX(GUIItem.Align_Min)
    self.welcomeMessage:SetTextAlignmentY(GUIItem.Align_Min)
    self.welcomeMessage:SetPosition(Vector(GUICountDownDisplay.kHeadLineXOffset, GUICountDownDisplay.kHeadLineYOffset, 0))
    self.welcomeMessage:SetFontName(GUICountDownDisplay.kFontName)
    self.welcomeMessage:SetFontSize(GUICountDownDisplay.kHeadLineFontSize)
    self.welcomeMessage:SetText(kWelcomeMessage)
    self.borderTop:AddChild(self.welcomeMessage)
    
    self.mapName = GetGUIManager():CreateTextItem()
    self.mapName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.mapName:SetTextAlignmentX(GUIItem.Align_Min)
    self.mapName:SetTextAlignmentY(GUIItem.Align_Min)
    self.mapName:SetPosition(Vector(GUICountDownDisplay.kHeadLineXOffset + self.welcomeMessage:GetTextWidth(kWelcomeMessage), GUICountDownDisplay.kHeadLineYOffset, 0))
    self.mapName:SetFontName(GUICountDownDisplay.kFontName)
    self.mapName:SetFontSize(GUICountDownDisplay.kHeadLineFontSize)
    self.mapName:SetColor(GUICountDownDisplay.kMapNameFontColor)
    self.mapName:SetText(ToString(" " .. string.gsub(Shared.GetMapName(),"ns2_", "") ))
    self.borderTop:AddChild(self.mapName)
    
    self.serverName = GetGUIManager():CreateTextItem()
    self.serverName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.serverName:SetTextAlignmentX(GUIItem.Align_Min)
    self.serverName:SetTextAlignmentY(GUIItem.Align_Min)
    self.serverName:SetPosition(Vector(GUICountDownDisplay.kServerNameXOffset, GUICountDownDisplay.kServerNameYOffset, 0))
    self.serverName:SetFontName(GUICountDownDisplay.kFontName)
    self.serverName:SetFontSize(GUICountDownDisplay.kServerNameFontSize)
    self.serverName:SetText(Client.GetConnectedServerName())
    self.borderTop:AddChild(self.serverName)
    
    local frameWidth = Client.GetScreenWidth() / 2
    
    self.nameFrame = GetGUIManager():CreateGraphicItem()
    self.nameFrame:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.nameFrame:SetSize(Vector(frameWidth, GUICountDownDisplay.kNameFrameHeight, 0))
    self.nameFrame:SetPosition(Vector(-frameWidth, -GUICountDownDisplay.kNameFrameHeight/2, 0))
    self.nameFrame:SetColor(Color(0,0,0,0))
    self.borderTop:AddChild(self.nameFrame)
    
    self.marineNames = GetGUIManager():CreateTextItem()
    self.marineNames:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.marineNames:SetTextAlignmentX(GUIItem.Align_Min)
    self.marineNames:SetTextAlignmentY(GUIItem.Align_Center)
    self.marineNames:SetFontName(GUICountDownDisplay.kFontName)
    self.marineNames:SetFontSize(GUICountDownDisplay.kNameFontSize)
    self.nameFrame:AddChild(self.marineNames)
    
    self.alienNames = GetGUIManager():CreateTextItem()
    self.alienNames:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.alienNames:SetTextAlignmentX(GUIItem.Align_Min)
    self.alienNames:SetTextAlignmentY(GUIItem.Align_Center)
    self.alienNames:SetFontName(GUICountDownDisplay.kFontName)
    self.alienNames:SetFontSize(GUICountDownDisplay.kNameFontSize)
    self.nameFrame:AddChild(self.alienNames)
    
    self.marineIcon = GetGUIManager():CreateGraphicItem()
    self.marineIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.marineIcon:SetSize(GUICountDownDisplay.kIconSize)
    self.marineIcon:SetPosition( Vector( -GUICountDownDisplay.kIconSize.x - 10,  -GUICountDownDisplay.kIconSize.y / 2, 0) )
    self.marineIcon:SetTexture(GUICountDownDisplay.kIconTexture)
    self.marineIcon:SetTexturePixelCoordinates(unpack(GUICountDownDisplay.kMarineIconTexCoords))
    self.nameFrame:AddChild(self.marineIcon)
    
    self.alienIcon = GetGUIManager():CreateGraphicItem()
    self.alienIcon:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.alienIcon:SetSize(GUICountDownDisplay.kIconSize)
    self.alienIcon:SetPosition( Vector( -GUICountDownDisplay.kIconSize.x - 10,  -GUICountDownDisplay.kIconSize.y / 2, 0) )
    self.alienIcon:SetTexture(GUICountDownDisplay.kIconTexture)
    self.alienIcon:SetTexturePixelCoordinates(unpack(GUICountDownDisplay.kAlienIconTexCoords))
    self.nameFrame:AddChild(self.alienIcon)
    
    self.borderBottom = GetGUIManager():CreateGraphicItem()
    self.borderBottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.borderBottom:SetSize(Vector(Client.GetScreenWidth(), GUICountDownDisplay.kBorderHeight, 0))
    self.borderBottom:SetPosition(Vector(0, -GUICountDownDisplay.kBorderHeight, 0))
    self.borderBottom:SetColor(Color(0,0,0,0))
    self.borderBottom:SetLayer(kGUILayerCountDown)
    
    self.countDownMessage = GetGUIManager():CreateTextItem()
    self.countDownMessage:SetText("Game starting in 6 seconds...")
    self.countDownMessage:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.countDownMessage:SetTextAlignmentX(GUIItem.Align_Center)
    self.countDownMessage:SetTextAlignmentY(GUIItem.Align_Center)
    self.countDownMessage:SetFontName(GUICountDownDisplay.kFontName)
    self.countDownMessage:SetFontSize(GUICountDownDisplay.kFontSize)
    self.borderBottom:AddChild(self.countDownMessage)
    
    

end

function GUICountDownDisplay:CreateTeamIcon()

    local teamIcon = GetGUIManager():CreateGraphicItem()
    teamIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    teamIcon:SetSize(Vector(64, 96, 0))
    teamIcon:SetPosition(Vector(10, -40, 0))
    
    if PlayerUI_IsOnMarineTeam() then
    
        teamIcon:SetTexture(GUICountDownDisplay.kMarineLogoTexture)
        teamIcon:SetTexturePixelCoordinates(unpack(GUICountDownDisplay.kMarineLogoTexCoords))
        
    else
    
        teamIcon:SetTexture(GUICountDownDisplay.kAlienLogoTexture)
        teamIcon:SetTexturePixelCoordinates(unpack(GUICountDownDisplay.kAlienLogoTexCoords))
        
    end
    
    return teamIcon
    
end


function GUICountDownDisplay:Uninitialize()

    if self.borderTop then
        GUI.DestroyItem(self.borderTop)
        self.borderTop = nil
    end

    if self.borderBottom then
        GUI.DestroyItem(self.borderBottom)
        self.borderBottom = nil
    end
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end    
    
end

function GetNameString(records)

    local nameString = ""

    for index, record in ipairs(records) do
    
        nameString = nameString .. record.Name
        
        if index < #records then
            nameString = nameString .. ",  "
        end
    
    end
    
    return nameString

end

function GUICountDownDisplay:Update(deltaTime)
    
    local playerRecordMarine = ScoreboardUI_GetBlueScores()
    local playerRecordAlien = ScoreboardUI_GetRedScores()
    
    local marineNames = GetNameString(playerRecordMarine)
    local alienNames = GetNameString(playerRecordAlien)
    
    self.marineNames:SetText(marineNames)
    self.alienNames:SetText(alienNames)
    
    self.countDownMessage:SetText(string.format( Locale.ResolveString("STARTING_IN") , ToString(math.ceil(PlayerUI_GetRemainingCountdown())) ))
    
end
