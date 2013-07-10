// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderButtonsAliens.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages alien specific layout and updating for commander buttons.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUICommanderButtons.lua")

class 'GUICommanderButtonsAliens' (GUICommanderButtons)

GUICommanderButtonsAliens.kBackgroundTexture = "ui/alien_commander_background.dds"

GUICommanderButtonsAliens.kNumberAlienButtonRows = 2
GUICommanderButtonsAliens.kNumberAlienButtonColumns = 4
// One row of special buttons on top.
GUICommanderButtonsAliens.kNumberMarineTopTabs = GUICommanderButtonsAliens.kNumberAlienButtonColumns
// With the normal buttons below.
GUICommanderButtonsAliens.kNumberAlienButtons = GUICommanderButtonsAliens.kNumberAlienButtonRows * GUICommanderButtonsAliens.kNumberAlienButtonColumns

GUICommanderButtonsAliens.kButtonYOffset = 20 * kCommanderGUIsGlobalScale

GUICommanderButtonsAliens.kMarineTabXOffset = 37 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kMarineTabYOffset = 30 * kCommanderGUIsGlobalScale

GUICommanderButtonsAliens.kMarineTabWidth = 99 * kCommanderGUIsGlobalScale
// Determines how much space is between each tab.
GUICommanderButtonsAliens.kAlienTabSpacing = 4 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kAlienTabTopHeight = 40 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kAlienTabBottomHeight = 8 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kAlienTabBottomOffset = 0 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kAlienTabConnectorWidth = 109 * kCommanderGUIsGlobalScale
GUICommanderButtonsAliens.kAlienTabConnectorHeight = 15 * kCommanderGUIsGlobalScale

function GUICommanderButtonsAliens:GetBackgroundTextureName()

    return GUICommanderButtonsAliens.kBackgroundTexture

end

function GUICommanderButtonsAliens:InitializeButtons()

    self:InitializeHighlighter()
    
    local settingsTable = { }
    settingsTable.NumberOfTabs = GUICommanderButtonsAliens.kNumberMarineTopTabs
    settingsTable.TabXOffset = GUICommanderButtonsAliens.kMarineTabXOffset
    settingsTable.TabYOffset = GUICommanderButtonsAliens.kMarineTabYOffset
    settingsTable.TabWidth = GUICommanderButtonsAliens.kMarineTabWidth
    settingsTable.TabSpacing = GUICommanderButtonsAliens.kAlienTabSpacing
    settingsTable.TabTopHeight = GUICommanderButtonsAliens.kAlienTabTopHeight
    settingsTable.TabBottomHeight = GUICommanderButtonsAliens.kAlienTabBottomHeight
    settingsTable.TabBottomOffset = GUICommanderButtonsAliens.kAlienTabBottomOffset
    settingsTable.TabConnectorWidth = GUICommanderButtonsAliens.kAlienTabConnectorWidth
    settingsTable.TabConnectorHeight = GUICommanderButtonsAliens.kAlienTabConnectorHeight
    settingsTable.NumberOfColumns = GUICommanderButtonsAliens.kNumberAlienButtonColumns
    settingsTable.NumberOfButtons = GUICommanderButtonsAliens.kNumberAlienButtons
    settingsTable.ButtonYOffset = GUICommanderButtonsAliens.kButtonYOffset
    self:SharedInitializeButtons(settingsTable)
    
end