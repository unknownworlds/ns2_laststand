// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\FormButton.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")

class 'FormButton' (FormElement)

local kDefaultFontSize = 34
local kDefaultFontColor = Color(0.77, 0.44, 0.22)
local kDefaultBackgroundColor = Color(0.0, 0.0, 0.0, 0.7)
local kDefaultHighlightBackgroundColor = Color(0.3, 0.3, 0.3, 0.7)
local kDefaultCursorSize = Vector(24, 28, 0)
local kDefaultCursorColor = Color(0.6, 0.6, 0.6, 1)
local kDefaultMarginLeft = 16
local kDefaultMaxLength = 32 // This is the max steam profile length

local kDefaultSize = Vector(300, 48, 0)

function FormButton:Initialize()

    FormElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize, true)
    self:SetBackgroundColor(kDefaultBackgroundColor)
    
    self:SetChildrenIgnoreEvents(true)    
    
    self.text = CreateTextItem(self)
    self.text:SetFontSize(kDefaultFontSize)
    self.text:SetColor(kDefaultFontColor)
    self.text:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.text:SetTextAlignmentY(GUIItem.Align_Center)
    self.text:SetPosition(Vector(10, 0, 0))
    
    self:GetBackground():AddChild(self.text)
    self:SetBorderWidth(1)
    
    self:SetValue("")
    self:SetMarginLeft(kDefaultMarginLeft)
    
end

function FormButton:GetTagName()
    return "formbutton"
end

function FormButton:SetFontSize(fontSize)
    self.text:SetFontSize(fontSize)    
end

function FormButton:SetFontName(fontName)
    self.text:SetFontName(fontName)
end

function FormButton:SetTextColor(color)
    self.text:SetColor(color)
end

function FormButton:SetValue(value)

    if type(value) == "string" then
        self.text:SetText(value)
    else    
        self.text:SetWideText(value)    
    end
    
    FormElement.SetValue(self, self.text:GetText())
    
end