//----------------------------------------
//  Last Stand - amount of seconds left in round
//----------------------------------------
class "GUIRoundTime" (GUIScript)

local kWidgetHeight = 50

function GUIRoundTime:Initialize()

    GUIScript.Initialize(self)
    
    // Compute size/pos
    
    self.widget = GUIManager:CreateGraphicItem()
    self.widget:SetColor( Color(0.0, 0.0, 0.0, 0.5) )
    self.widget:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.widget:SetPosition(Vector(-100, 0.0, 0))
    self.widget:SetSize( Vector(100, kWidgetHeight, 0) )
    self.widget:SetIsVisible(true)

    self.timeText = GUI.CreateItem()
    self.timeText:SetOptionFlag(GUIItem.ManageRender)
    self.timeText:SetInheritsParentAlpha( false )
    self.timeText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.timeText:SetPosition(Vector(10,0,0))
    self.timeText:SetTextAlignmentX(GUIItem.Align_Min)
    self.timeText:SetTextAlignmentY(GUIItem.Align_Center)
    self.timeText:SetFontName("fonts/AgencyFB_small.fnt")
    self.timeText:SetText("12:34 OMG")

    self.widget:AddChild(self.timeText)

end

function GUIRoundTime:Uninitialize()

    if self.widget then
        GUI.DestroyItem( self.widget )
        self.widget = nil
    end

end

function GUIRoundTime:SetWidgetSize(wt,ht)
    if ht == nil then ht = kWidgetHeight end
    self.widget:SetSize( Vector(wt, ht, 0) )
    self.widget:SetPosition(Vector(-wt, 0.0, 0))
end

function GUIRoundTime:Update(dt)

    GUIScript.Update(self, dt)

    if gGameRules.gameState == kGameState.NotStarted then

        self.timeText:SetText(string.format("PICK A TEAM! Starting in %0.2f", gGameRules.lsReadySecsLeft))
        self.timeText:SetColor( Color(0,1,0,1) )
        self:SetWidgetSize(300, nil)

    elseif gGameRules.gameState == kGameState.PreGame then

        self.timeText:SetText(string.format("MARINE PREP %0.2f", gGameRules.lsPreGameSecsLeft))
        self.timeText:SetColor( Color(1,1,0,1) )
        self:SetWidgetSize(300, nil)

    elseif gGameRules.gameState == kGameState.Started then

        local player = Client.GetLocalPlayer()

        if player then

            local t = gGameRules:GetRoundSecsLeft()

            // color
            if t < 30.0 then
                self.timeText:SetColor( Color(1,0,0,1) )
            else
                self.timeText:SetColor( kChatTextColor[player:GetTeamType()] )
            end

            local numMarines = gGameRules:GetNumMarinesLeft()
            self.timeText:SetText( string.format("%d MARINES - %0.2f", numMarines, t ) )
            self:SetWidgetSize(170, nil)

        end

    elseif gGameRules.gameState == kGameState.Team1Won or gGameRules.gameState == kGameState.Team2Won then

        local t = gGameRules:GetRoundSecsLeft()
        self.timeText:SetColor( Color(1,0,0,1) )
        self.timeText:SetText( string.format("GG - %0.2f", t) )

    end
    
end

