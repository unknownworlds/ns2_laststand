// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Checkbox.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")
  
local kDefaultFontSize = 24
local kDefaultTexture = ""
local kDefaultSize = Vector(24, 24, 0)
local kDefaultBgColor = Color(0,0,0,1)
local kDefaultHighlightBgColor = Color(0.7, 0.4, 0.2, 0.4)

class 'Checkbox' (FormElement)

function Checkbox:Initialize()

    FormElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize)
    
    self:SetChildrenIgnoreEvents(true)
    
    self.checkedImage = CreateMenuElement(self, "Image", false)
    self.checkedImage:SetCSSClass("checked", false)
    
    self.checkboxCSSClassName = ""
    
    local eventCallbacks = {
      
        OnClick = function (self)
            self:SetChecked()
        end,
        
    }
    
    self:AddEventCallbacks(eventCallbacks)
    self:SetValue(true)

end

function Checkbox:GetTagName()
    return "checkbox"
end

function Checkbox:SetChecked()
    self:SetValue(not self:GetValue()) 
end

function Checkbox:SetValue(value)

    if value == "true" then
        value = true
    elseif value == "false" then
        value = false
    elseif type(value) ~= "boolean" then
    
        // NOTE: This may happen if some bad data gets into a save file.
        // Better to print warning to the log than generate a script error in this case.
        Shared.Message("Warning: value is not a boolean (defaulting to true). " .. Script.CallStack())
        value = true
        
    end
    
    FormElement.SetValue(self, value)

    self.checkedImage:SetIsVisible(value)
    self.checkedImage:SetInitialVisible(value)  
    
end
