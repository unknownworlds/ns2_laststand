// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Form.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

Script.Load("lua/menu/TextInput.lua")
Script.Load("lua/menu/DropDown.lua")
Script.Load("lua/menu/Checkbox.lua")
Script.Load("lua/menu/SlideSelect.lua")
Script.Load("lua/menu/Slider.lua")
Script.Load("lua/menu/SlideBar.lua")
Script.Load("lua/menu/FormButton.lua")
Script.Load("lua/menu/ProgressBar.lua")

class 'Form' (MenuElement)

Form.kElementType = enum({'Checkbox', 'DropDown', 'TextInput', 'SlideSelect', 'Slider', 'SlideBar', 'FormButton', 'ProgressBar' })

local kDefaultSize = Vector(400, 400, 0)

function Form:Initialize()

    MenuElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize, true)
    self:SetBackgroundColor(Color(1,1,1,0))
    
    self.formElements = {}
    
    self.maxExtents = Vector(0,0,0)

end

function Form:GetTagName()
    return "form"
end    

function Form:FormElementChanged(formElement)


end

function Form:CreateFormElement(type, name, initialValue, parent)

    local addTo = self
    if parent then
        addTo = parent
    end
    
    local formElement = CreateMenuElement(addTo, EnumToString(Form.kElementType, type), false)
    formElement:SetFormElementName(name)
    self:AddFormElement(formElement)
    
    if initialValue ~= nil then
        formElement:SetValue(initialValue)
    end
    
    return formElement

end

function Form:AddFormElement(formElement)
    table.insert(self.formElements, formElement)
end

function Form:GetFormData()

    local formData = {}
    
    for _, formElement in ipairs(self.formElements) do
    
        formData[formElement:GetFormElementName()] = formElement:GetValue()
        
        if formElement:isa("DropDown") then
            formData[formElement:GetFormElementName() .. "_index"] = formElement:GetActiveOptionIndex()
        end
    
    end
    
    return formData

end