// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderHelpWidget.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// Displays buttons in the world to teach new commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommanderHelp.lua")

class 'GUICommanderHelpWidget' (GUIScript)

local kButtonTexture = "ui/buildmenu.dds"
local kButtonLayer = kGUILayerPlayerHUDForeground1
local kHighlightLayer = kGUILayerPlayerHUDForeground2

local kDefaultOffset = Vector(-kWorldButtonSize * .5, -kWorldButtonSize, 0)

local kBlurAlpha = 0.6
local kFocusAlpha = 1

local function CreateWorldButton(self)
    
    if self.teamType ~= kNeutralTeamType then
        
        local button = {}
        
        button.graphic = GetGUIManager():CreateGraphicItem()
        button.graphic:SetSize(Vector(kWorldButtonSize, kWorldButtonSize, 0))
        button.graphic:SetTexture(kButtonTexture)
        button.graphic:SetLayer(kButtonLayer)
        
        local useColor = Color(kIconColors[self.teamType])
        useColor.a = kBlurAlpha
        
        button.graphic:SetColor(useColor)
        
        self.background:AddChild(button.graphic)
        
        return button

    end

end

function GUICommanderHelpWidget:Initialize()

    self.teamType = PlayerUI_GetTeamType()

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetLayer(kGUILayerPlayerHUDBackground)
    
    self.worldButtons = {}
    
end

function GUICommanderHelpWidget:Uninitialize()
    
    // cleans up all buttons as well
    if self.background then
        GUI.DestroyItem(self.background)
    end
    
    self.worldButtons = {}
    
end

function GUICommanderHelpWidget:Update(deltaTime)

    PROFILE("GUICommanderHelpWidget:Update")

    local commanderButtons = CommanderHelp_GetWorldButtons()
    
    local showHelp = CommanderHelp_GetShowWorldButtons()

    self.background:SetIsVisible(showHelp)
    
    if showHelp then
    
        local numCurrentButtons = #commanderButtons 
        local numButtons = #self.worldButtons
        
        if numCurrentButtons > numButtons then
        
            for i = 1, numCurrentButtons - numButtons do
            
                local newButton = CreateWorldButton(self)
                if newButton then
                    table.insert(self.worldButtons, newButton)
                end
                
            end
        
        elseif numButtons > numCurrentButtons then
        
            for i = 1, numButtons - numCurrentButtons do
            
                if self.activeButton == self.worldButtons[#self.worldButtons] then
                    self.activeButton = nil
                end
            
                GUI.DestroyItem(self.worldButtons[#self.worldButtons].graphic)
                table.remove(self.worldButtons, #self.worldButtons)
                
            end
        
        end
        
        for i = 1, #commanderButtons do
        
            local commanderButton = commanderButtons[i]
            local button = self.worldButtons[i]
            
            button.graphic:SetTexturePixelCoordinates( unpack( GetTextureCoordinatesForIcon(commanderButton.TechId, self.teamType == kMarineTeamType) ) )
            button.graphic:SetPosition(commanderButton.Position + kDefaultOffset)
            button.TechId = commanderButton.TechId
            button.Entity = commanderButton.Entity
        
        end
    
    end

end

local function GetButtonHit(self, x, y)

    for _, button in ipairs(self.worldButtons) do
    
        if GUIItemContainsPoint(button.graphic, x, y) then
            return button     
        end
    
    end

end

function GUICommanderHelpWidget:ContainsPoint(pointX, pointY)

    local oldActiveButton = self.activeButton
    local color = Color(kIconColors[self.teamType])
    
    self.activeButton = GetButtonHit(self, pointX, pointY)
    
    if self.activeButton then
    
        color.a = kFocusAlpha
        self.activeButton.graphic:SetColor(color)
        
    end    
        
    if self.activeButton ~= oldActiveButton and oldActiveButton then
            
        color.a = kBlurAlpha
        oldActiveButton.graphic:SetColor(color)
            
    end

    return CommanderHelp_GetShowWorldButtons() and self.activeButton ~= nil
end

function GUICommanderHelpWidget:GetTooltipData()

    if CommanderHelp_GetShowWorldButtons() then

        local player = Client.GetLocalPlayer()
        
        if self.activeButton and player then    
            return PlayerUI_GetTooltipDataFromTechId(self.activeButton.TechId)        
        end
        
    end    

    return nil

end

function GUICommanderHelpWidget:SendKeyEvent(key, down)

    local success = false

    // process button presses    
    if CommanderHelp_GetShowWorldButtons() and not down and key == InputKey.MouseButton0 then
    
        local x, y = Client.GetCursorPosScreen()
        local buttonHit = GetButtonHit(self, x, y)
        
        if buttonHit then
            
            CommanderHelp_ProccessTechIdAction(buttonHit.TechId, buttonHit.Entity)            
            success = true
        
        end
    
    end
    
    return success

end

