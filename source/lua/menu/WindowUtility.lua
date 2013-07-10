// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\WindowUtility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Holds GUIItems for a window.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kRed = Color(1, 0, 0, 1)
kYellow = Color(1, 1, 0, 1)
kGreen = Color(0, 1, 0, 1)
kWhite = Color(1,1,1,1)
kNoColor = Color(0,0,0,0)

kArrowVerticalButtonTexture = "ui/menu/arrow_vert.dds"
kArrowHorizontalButtonTexture = "ui/menu/arrow_horiz.dds"
kArrowMinCoords = { 0, 0, 1, 1 }
kArrowMaxCoords = { 1, 1, 0, 0 }


local HexStringToIntMap = { }
HexStringToIntMap["0"] = 0  HexStringToIntMap["1"] = 1
HexStringToIntMap["2"] = 2  HexStringToIntMap["3"] = 3
HexStringToIntMap["4"] = 4  HexStringToIntMap["5"] = 5
HexStringToIntMap["6"] = 6  HexStringToIntMap["7"] = 7
HexStringToIntMap["8"] = 8  HexStringToIntMap["9"] = 9
HexStringToIntMap["A"] = 10  HexStringToIntMap["B"] = 11
HexStringToIntMap["C"] = 12  HexStringToIntMap["D"] = 13
HexStringToIntMap["E"] = 14  HexStringToIntMap["F"] = 15

function HexStringToNumber(hexString)
    local intValue = 0
    local index = string.len(hexString)
    for i = 0, string.len(hexString) - 1 do
        local hex = string.upper(string.sub(hexString, index, index))
        local int = HexStringToIntMap[hex]
        int = int * (16 ^ i)
        
        intValue = intValue + int
    
        index = index - 1
    end
    
    return intValue
end

// pass a MenuElement as first parameter
function CreateGraphicItem(self, attach, preventAnimation)
    local graphicItem = nil

    if self.scriptHandle ~= nil and self.scriptHandle:isa("GUIAnimatedScript")  and not preventAnimation then
        graphicItem = self.scriptHandle:CreateAnimatedGraphicItem()
        graphicItem:SetIsScaling(self:GetIsScaling())
    else
        graphicItem = GetGUIManager():CreateGraphicItem()
    end
    
    graphicItem:SetInheritsParentStencilSettings(true)
    
    if attach == true then
        self:GetBackground():AddChild(graphicItem)
    end    
    
    return graphicItem
end

function CreateTextItem(self, attach, preventAnimation)
    local graphicItem = nil

    if self.scriptHandle:isa("GUIAnimatedScript") and not preventAnimation then
        graphicItem = self.scriptHandle:CreateAnimatedTextItem()
        graphicItem:SetIsScaling(self:GetIsScaling())
    else
        graphicItem = GetGUIManager():CreateTextItem()
    end
    
    graphicItem:SetInheritsParentStencilSettings(true)
    
    if attach == true then
        self:GetBackground():AddChild(graphicItem)
    end  
    
    return graphicItem
end

function DestroyGUIItem(item)
    if item:isa("GUIItem") then
        GUI.DestroyItem(item)
    else
        item:Destroy()
    end
end

function CreateMenuElement(parentElement, className, loadStyles)

    assert(className ~= nil)

    local newElement = nil
    local creationFunction = _G[className]
    
    if creationFunction == nil then
    
        Shared.Message("Error: Failed to load menu element named " .. className)
        return nil
        
    else
    
        newElement = creationFunction()
        newElement:SetScriptHandle(parentElement.scriptHandle)
        newElement:Initialize()
        newElement:SetLayer(parentElement:GetLayer())
        
        parentElement:AddChild(newElement)
        
        // applies the tag only general styles
        if loadStyles ~= false then
            newElement:SetCSSClass()
        end
        
        return newElement
        
    end

end

local function OnCommandDebugGUI(enabled)

    gDebugGUI = enabled == "true"
    
    if not gDebugGUI and gDebugRectangle then
        GUI.DestroyItem(gDebugRectangle)
        gDebugRectangle = nil
    end
    
    Print("debuggui %s", ToString(gDebugGUI))

end

Event.Hook("Console_debuggui", OnCommandDebugGUI)
