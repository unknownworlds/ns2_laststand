// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\FormElement.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
  
local kDefaultBgColor = Color(0,0,0,1)
local kDefaultFontSize = 38
local kDefaultWidth = 200
local kDefaultHighlightColor = Color(1,1,1,0.5)
local kDefaultBorderColor = Color(1,1,1,0)

class 'FormElement' (MenuElement)

local function InformForm(self)

    local parent = self:GetParent()
    for i = 1, 20 do
    
        if parent then
        
            if parent:GetTagName() == "form" then
                parent:FormElementChanged(self)
                return
            end
            
        else
            return
        end
        
        parent = parent:GetParent()
    
    end

end

function FormElement:Initialize()

    MenuElement.Initialize(self)
    
    self:SetBackgroundColor(kDefaultBgColor)
    
    self:SetBorderColor(kDefaultBorderColor)
    self:SetBorderHighlightColor(kDefaultHighlightColor)
    self:SetBorderWidth(1)
    
    self.value = nil
    self.formElementName = "UNDEFINED"
    
    local eventCallbacks = {
    
        OnFocus = function (self)

            if self.highlightBorderColor then
                MenuElement.SetBorderColor(self, self.highlightBorderColor)
            end
        end,

        OnBlur = function (self)

            if self.normalBorderColor then
                MenuElement.SetBorderColor(self, self.normalBorderColor)
            end    
        end,
    
    }
    
    self:AddEventCallbacks(eventCallbacks)
    
    // our own events here
    self.setValueCallbacks = {}

end

function FormElement:SetBorderColor(color, time, animateFunc, animName, callBack)

    MenuElement.SetBorderColor(self, color, time, animateFunc, animName, callBack)    
    self.normalBorderColor = color

end

function FormElement:SetBorderHighlightColor(color)
    
    self.highlightBorderColor = color

end

function FormElement:GetTagName()
    Print("WARNING: FormElement:GetTagName(), no tag name specified!")
    return ""
end

function FormElement:SetValue(value)
    self.value = value
    InformForm(self)
    
    for _, callback in ipairs(self.setValueCallbacks) do
        callback(self)
    end
end    

function FormElement:AddSetValueCallback(callback)
    table.insertunique(self.setValueCallbacks, callback)
end

function FormElement:GetValue()
    return self.value
end

function FormElement:SetFormElementName(name)
    self.formElementName = name
end

function FormElement:GetFormElementName()
    return self.formElementName
end    
