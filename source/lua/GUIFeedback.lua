
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIFeedback.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the feedback text.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIFeedback' (GUIScript)

GUIFeedback.kFontSize = 14
GUIFeedback.kTextFontName = "fonts/AgencyFB_tiny.fnt"
GUIFeedback.kTextColor = Color(1.0, 1.0, 1.0, 0.5)
GUIFeedback.kTextOffset = Vector(3, 8, 0)

function GUIFeedback:Initialize()

    self.buildText = GUIManager:CreateTextItem()
    self.buildText:SetFontSize(GUIFeedback.kFontSize)
    self.buildText:SetFontName(GUIFeedback.kTextFontName)
    self.buildText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.buildText:SetTextAlignmentX(GUIItem.Align_Min)
    self.buildText:SetTextAlignmentY(GUIItem.Align_Center)
    self.buildText:SetPosition(GUIFeedback.kTextOffset)
    self.buildText:SetColor(GUIFeedback.kTextColor)
    self.buildText:SetFontIsBold(true)
    self.buildText:SetText(Locale.ResolveString("BETA_MAINMENU") .. tostring(Shared.GetBuildNumber()))
    
end

function GUIFeedback:Uninitialize()

    if self.buildText then
        GUI.DestroyItem(self.buildText)
        self.buildText = nil
        self.feedbackText = nil
    end
    
end