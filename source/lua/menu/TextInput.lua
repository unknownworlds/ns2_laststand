// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\TextInput.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")

local kDefaultFontSize = 34
local kDefaultFontColor = Color(0.77, 0.44, 0.22)
local kDefaultBackgroundColor = Color(0.3, 0.3, 0.3, 0.7)
local kDefaultHighlightBackgroundColor = Color(0.3, 0.3, 0.3, 0.7)
local kDefaultCursorSize = Vector(24, 28, 0)
local kDefaultCursorColor = Color(0.6, 0.6, 0.6, 1)
local kDefaultMarginLeft = 16
local kDefaultMaxLength = 32 // This is the max steam profile length

local kDefaultSize = Vector(300, 48, 0)

class 'TextInput' (FormElement)

local function UpdateCursorPosition(self)

    local textWidth = self.text:GetTextWidth(self.text:GetText() .. ".")
    textWidth = textWidth - self.text:GetTextWidth(".")
    local textHeight = self.text:GetTextHeight("!")
    
    self.textCursor:SetLeftOffset(textWidth + self:GetMarginLeft())
    self.textCursor:SetAlign(GUIItem.Left, GUIItem.Top)
    self.textCursor:SetTopOffset(self:GetHeight()/2 + textHeight/2 - self.textCursor:GetHeight())

end

function TextInput:Initialize()

    FormElement.Initialize(self)
    self.maxLength = kDefaultMaxLength;
    self:SetBackgroundSize(kDefaultSize, true)
    self:SetBackgroundColor(kDefaultBackgroundColor)
    
    self:SetChildrenIgnoreEvents(true)    
    
    self.text = CreateTextItem(self)
    self.text:SetFontSize(kDefaultFontSize)
    self.text:SetColor(kDefaultFontColor)
    self.text:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.text:SetTextAlignmentY(GUIItem.Align_Center)
    self:GetBackground():AddChild(self.text)
    self:SetBorderWidth(1)
    
    self.textCursor = CreateMenuElement(self, "Image", false)
    self.textCursor:SetIgnoreMargin(true)
    self.textCursor:SetBackgroundSize(kDefaultCursorSize)
    self.textCursor:SetBackgroundColor(kDefaultCursorColor)
    self.textCursor:SetIsVisible(false)
    self.textCursor:SetInitialVisible(false)
    self.textCursor:SetCSSClass("textcursor")
    
    local eventCallbacks = {
    
        OnFocus = function (self)
            self.textCursor:SetIsVisible(true)
            UpdateCursorPosition(self)
        end,
        
        OnBlur = function (self)        
            self.textCursor:SetIsVisible(false)
        end,
        
        OnEscape = function (self)
            self:SetValue("")
            return true
        end,
    
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    self:SetValue("")
    self:SetMarginLeft(kDefaultMarginLeft)
    UpdateCursorPosition(self)

end

function TextInput:SetNumbersOnly(numbersOnly)
    self.numbersOnly = numbersOnly
end

function TextInput:SetMaxLength(newMaxLength)

    self.maxLength = newMaxLength
    // TODO resize the current string if it's over the new maximum length
    
    UpdateCursorPosition(self)

end

function TextInput:SetMarginLeft(marginLeft)

    MenuElement.SetMarginLeft(self, marginLeft)
    
    self.text:SetPosition(Vector(self:GetMarginLeft(), 0, 0))
    UpdateCursorPosition(self)

end

function TextInput:GetTagName()
    return "textinput"
end

function TextInput:SetFontName(fontName)
    self.text:SetFontName(fontName)
end

function TextInput:SetFontSize(fontSize)
    self.text:SetFontSize(fontSize)    
end

function TextInput:SetTextColor(color)
    self.text:SetColor(color)
end

local function IsANumber(self, character)

    local oldValue = self.text:GetText()
    self.text:SetWideText(character)
    local characterString = self.text:GetText()
    self.text:SetText(oldValue)

    return characterString == "0" or characterString == "1" or characterString == "2" or characterString == "3" or characterString == "4" or 
           characterString == "5" or characterString == "6" or characterString == "7" or characterString == "8" or characterString == "9"

end

function TextInput:AddCharacter(character)

    if not self.numbersOnly or IsANumber(self, character) then
        self:SetValue(self.text:GetWideText() .. character)
    end
    
end

function TextInput:RemoveCharacter()
    local currentText = self.text:GetWideText()
    local length = #currentText
    self:SetValue(currentText:sub(1, length - 1))
end

function TextInput:SetValue(value)
    
    if type(value) == "string" then
        self.text:SetText(value)
    else    
        self.text:SetWideText(value)    
    end
    
    UpdateCursorPosition(self)
    
    FormElement.SetValue(self, self.text:GetText())

end

function TextInput:OnSendCharacter(character)
    // Don't add the character if we're already at the maximum length
    if string.len(self:GetValue()) ~= self.maxLength then
        self:AddCharacter(character)
    end
end

function TextInput:OnSendKey(key, down)
    
    if key == InputKey.Back and down then
        self:RemoveCharacter()
    end

end