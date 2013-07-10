// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\CSSParser.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Parses a CSS string in a table. gCSSToMenuElementFunc stores the mapping
//    between CSS attribute names and ApplyFunctions. gCSSToValueFunc translates
//    CSS string values to internal format.
//
//    Dependency (parent tag) 'none' and class names 'none' are reserved.
//
//    table structure:
//    cssClassName -> { entry, entry... },
//    cssClassName -> ...
//
//    entry -> { Dependency, RequiredTag, Function, Value }
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/WindowUtility.lua")

local gCurrentStyle = {}
local gCSSToMenuElementFunc = {}
local gCSSToValueFunc = {}

// --------- CSS attributes to MenuElement set function mapping ------------

local function SetBackgroundColor(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBackgroundColor then
        menuElement:SetBackgroundColor(value, time, animateFunc, animName)
    end
end
local function SetBackgroundHoverColor(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBackgroundHoverColor then
        menuElement:SetBackgroundHoverColor(value, time, animateFunc, animName)
    end
end
local function SetBackgroundRepeat(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBackgroundRepeat then
        menuElement:SetBackgroundRepeat(value, time, animateFunc, animName)
    end
end
local function SetBackgroundTexture(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBackgroundTexture then
        menuElement:SetBackgroundTexture(value.Path, time, animateFunc, animName)
    end
    if menuElement.SetTextureCoords and value.Coords then
        menuElement:SetTextureCoords(value.Coords, time, animateFunc, animName)
    end
    if menuElement.SetTexturePixelCoords and value.PixelCoords then
        menuElement:SetTexturePixelCoords(value.PixelCoords, time, animateFunc, animName)
    end
end
local function SetFontSize(menuElement, value, time, animateFunc, animName)
    if menuElement.SetFontSize then
        menuElement:SetFontSize(value.Number, time, animateFunc, animName)
    end
end
local function SetFontScale(menuElement, value, time, animateFunc, animName)
    if menuElement.SetFontScale then
        menuElement:SetFontScale(value.Number, time, animateFunc, animName)
    end
end
local function SetOpacity(menuElement, value, time, animateFunc, animName)
    if menuElement.SetOpacity then
        menuElement:SetOpacity(value.Number, time, animateFunc, animName)
    end
end
local function SetWidth(menuElement, value, time, animateFunc, animName)
    if menuElement.SetWidth then
        menuElement:SetWidth(value.Number, value.IsPercentage, time, animateFunc, animName)
    end
end
local function SetHeight(menuElement, value, time, animateFunc, animName)
    if menuElement.SetHeight then
        menuElement:SetHeight(value.Number, value.IsPercentage, time, animateFunc, animName)
    end
end
local function SetTopOffset(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTopOffset then
        menuElement:SetTopOffset(value.Number, value.IsPercentage, time, animateFunc, animName)
    end
end
local function SetLeftOffset(menuElement, value, time, animateFunc, animName)
    if menuElement.SetLeftOffset then
        menuElement:SetLeftOffset(value.Number, value.IsPercentage, time, animateFunc, animName)
    end
end
local function SetBottomOffset(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBottomOffset then
        menuElement:SetBottomOffset(value.Number, value.IsPercentage, time, animateFunc, animName)
    end    
end
local function SetRightOffset(menuElement, value, time, animateFunc, animName)
    if menuElement.SetRightOffset then
        menuElement:SetRightOffset(value.Number, value.IsPercentage, time, animateFunc, animName)
    end    
end
local function SetTextColor(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextColor then
        menuElement:SetTextColor(value, time, animateFunc, animName)
    end    
end
local function SetHoverTextColor(menuElement, value, time, animateFunc, animName)
    if menuElement.SetHoverTextColor then
        menuElement:SetHoverTextColor(value, time, animateFunc, animName)
    end    
end
local function SetVerticalAlign(menuElement, value, time, animateFunc, animName)
    if menuElement.SetVerticalAlign then
        menuElement:SetVerticalAlign(value, time, animateFunc, animName)
    end
end    
local function SetHorizontalAlign(menuElement, value, time, animateFunc, animName)
    if menuElement.SetHorizontalAlign then
        menuElement:SetHorizontalAlign(value, time, animateFunc, animName)
    end
end
local function SetMinHeight(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMinHeight then
        menuElement:SetMinHeight(value.Number, time, animateFunc, animName)
    end
end
local function SetMinWidth(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMinWidth then
        menuElement:SetMinWidth(value.Number, time, animateFunc, animName)
    end
end
local function SetBorderColor(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBorderColor then
        menuElement:SetBorderColor(value, time, animateFunc, animName)
    end
end
local function SetBorderWidth(menuElement, value, time, animateFunc, animName)
    if menuElement.SetBorderWidth then
        menuElement:SetBorderWidth(value.Number, time, animateFunc, animName)
    end
end
local function SetTextHorizontalAlign(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextHorizontalAlign then
        menuElement:SetTextHorizontalAlign(value, time, animateFunc, animName)
    end
end
local function SetTextVerticalAlign(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextVerticalAlign then
        menuElement:SetTextVerticalAlign(value, time, animateFunc, animName)
    end
end
local function SetFontName(menuElement, value, time, animateFunc, animName)
    if menuElement.SetFontName then
        menuElement:SetFontName(value, time, animateFunc, animName)
    end
end
local function SetTextPadding(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextPadding then
        menuElement:SetTextPadding(value.Number, time, animateFunc, animName)
    end
end
local function SetFrameCount(menuElement, value, time, animateFunc, animName)
    if menuElement.SetFrameCount then
        menuElement:SetFrameCount(value.Number, time, animateFunc, animName)
    end
end
local function SetTextPaddingTop(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextPaddingTop then
        menuElement:SetTextPaddingTop(value.Number, time, animateFunc, animName)
    end
end
local function SetTextPaddingRight(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextPaddingRight then
        menuElement:SetTextPaddingRight(value.Number, time, animateFunc, animName)
    end
end
local function SetTextPaddingBottom(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextPaddingBottom then
        menuElement:SetTextPaddingBottom(value.Number, time, animateFunc, animName)
    end
end
local function SetTextPaddingLeft(menuElement, value, time, animateFunc, animName)
    if menuElement.SetTextPaddingLeft then
        menuElement:SetTextPaddingLeft(value.Number, time, animateFunc, animName)
    end
end
local function SetIgnoreMargin(menuElement, value, time, animateFunc, animName)
    if menuElement.SetIgnoreMargin then
        menuElement:SetIgnoreMargin(value, time, animateFunc, animName)
    end
end
local function SetIsScaling(menuElement, value, time, animateFunc, animName)
    if menuElement.SetIsScaling then
        menuElement:SetIsScaling(value, time, animateFunc, animName)
    end
end
local function SetMarginTop(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMarginTop then
        menuElement:SetMarginTop(value.Number, time, animateFunc, animName)
    end
end
local function SetMarginRight(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMarginRight then
        menuElement:SetMarginRight(value.Number, time, animateFunc, animName)
    end
end
local function SetMarginBottom(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMarginBottom then
        menuElement:SetMarginBottom(value.Number, time, animateFunc, animName)
    end
end
local function SetMarginLeft(menuElement, value, time, animateFunc, animName)
    if menuElement.SetMarginLeft then
        menuElement:SetMarginLeft(value.Number, time, animateFunc, animName)
    end
end
local function SetCellSpacing(menuElement, value, time, animateFunc, animName)
    if menuElement.SetCellSpacing then
        menuElement:SetCellSpacing(value.Number, time, animateFunc, animName)
    end
end
local function SetCellPadding(menuElement, value, time, animateFunc, animName)
    if menuElement.SetCellPadding then
        menuElement:SetCellPadding(value.Number, time, animateFunc, animName)
    end
end
local function SetVerticalCellPadding(menuElement, value, time, animateFunc, animName)
    if menuElement.SetVerticalCellPadding then
        menuElement:SetVerticalCellPadding(value.Number, time, animateFunc, animName)
    end
end
local function SetInheritOpacity(menuElement, value, time, animateFunc, animName)
    if menuElement.SetInheritOpacity then
        menuElement:SetInheritOpacity(value, time, animateFunc, animName)
    end
end
local function SetIsVisible(menuElement, value)
    if menuElement.SetIsVisible then
        menuElement:SetIsVisible(value)
    end
end
gCSSToMenuElementFunc["background-color"] = SetBackgroundColor
gCSSToMenuElementFunc["hover-background-color"] = SetBackgroundHoverColor
gCSSToMenuElementFunc["background-image"] = SetBackgroundTexture
gCSSToMenuElementFunc["background-repeat"] = SetBackgroundRepeat
gCSSToMenuElementFunc["frame"] = SetFrameCount
gCSSToMenuElementFunc["font-size"] = SetFontSize
gCSSToMenuElementFunc["font-scale"] = SetFontScale
gCSSToMenuElementFunc["opacity"] = SetOpacity
gCSSToMenuElementFunc["width"] = SetWidth
gCSSToMenuElementFunc["height"] = SetHeight
gCSSToMenuElementFunc["top"] = SetTopOffset
gCSSToMenuElementFunc["left"] = SetLeftOffset
gCSSToMenuElementFunc["bottom"] = SetBottomOffset
gCSSToMenuElementFunc["right"] = SetRightOffset
gCSSToMenuElementFunc["text-color"] = SetTextColor
gCSSToMenuElementFunc["hover-text-color"] = SetHoverTextColor
gCSSToMenuElementFunc["vertical-align"] = SetVerticalAlign
gCSSToMenuElementFunc["horizontal-align"] = SetHorizontalAlign
gCSSToMenuElementFunc["min-height"] = SetMinHeight
gCSSToMenuElementFunc["min-width"] = SetMinWidth
gCSSToMenuElementFunc["border-color"] = SetBorderColor
gCSSToMenuElementFunc["border-width"] = SetBorderWidth
gCSSToMenuElementFunc["text-align"] = SetTextHorizontalAlign
gCSSToMenuElementFunc["vertical-text-align"] = SetTextVerticalAlign
gCSSToMenuElementFunc["font-name"] = SetFontName
gCSSToMenuElementFunc["text-padding"] = SetTextPadding
gCSSToMenuElementFunc["text-padding-top"] = SetTextPaddingTop
gCSSToMenuElementFunc["text-padding-right"] = SetTextPaddingRight
gCSSToMenuElementFunc["text-padding-bottom"] = SetTextPaddingBottom
gCSSToMenuElementFunc["text-padding-left"] = SetTextPaddingLeft
gCSSToMenuElementFunc["ignore-margin"] = SetIgnoreMargin
gCSSToMenuElementFunc["scaling"] = SetIsScaling
gCSSToMenuElementFunc["margin-top"] = SetMarginTop
gCSSToMenuElementFunc["margin-right"] = SetMarginRight
gCSSToMenuElementFunc["margin-bottom"] = SetMarginBottom
gCSSToMenuElementFunc["margin-left"] = SetMarginLeft
gCSSToMenuElementFunc["cell-spacing"] = SetCellSpacing
gCSSToMenuElementFunc["cell-padding"] = SetCellPadding
gCSSToMenuElementFunc["vertical-cell-padding"] = SetVerticalCellPadding
gCSSToMenuElementFunc["inherit-opacity"] = SetInheritOpacity
gCSSToMenuElementFunc["visible"] = SetIsVisible

// ----------------- sub argument parsing ------------------

local function GetSubArgNumberList(stringValue)
    stringValue = StringSplit(stringValue, ",")
    for i, n in ipairs(stringValue) do
        stringValue[i] = tonumber(n)
    end
    return stringValue
end
local function GetSubArgTime(stringValue)
    return tonumber(stringValue)
end
local function GetSubArgFunc(stringValue)
    stringValue = StringTrim(stringValue)
    
    if stringValue == "AnimateLinear" then
        return AnimateLinear
    elseif stringValue == "AnimateQuadratic" then
        return AnimateQuadratic
    elseif stringValue == "AnimateSqRt" then
        return AnimateSqRt
    elseif stringValue == "AnimateSin" then
        return AnimateSin
    elseif stringValue == "AnimateCos" then
        return AnimateCos
    end
end
local function GetSubArgAnimName(stringValue)
    return string.upper(stringValue)
end    

gCSSSubArgToValueFunc = {}
gCSSSubArgToValueFunc["rgb"] = GetSubArgNumberList
gCSSSubArgToValueFunc["rgba"] = GetSubArgNumberList
gCSSSubArgToValueFunc["time"] = GetSubArgTime
gCSSSubArgToValueFunc["func"] = GetSubArgFunc
gCSSSubArgToValueFunc["animName"] = GetSubArgAnimName
gCSSSubArgToValueFunc["coords"] = GetSubArgNumberList
gCSSSubArgToValueFunc["pixelCoords"] = GetSubArgNumberList

// parse sub arguments help function
local function GetSubArgument(argumentName, stringValue)

    local subArgValue = nil
    local found = false
    local subArgIndex = string.find(stringValue, argumentName .. "%(")
    local stringEnd = string.len(stringValue)
    
    if subArgIndex then
    
        found = true
        local subArg = string.sub(stringValue, subArgIndex, string.len(stringValue))
        subArg = string.gsub(subArg, argumentName .. "%(", "")
        
        stringEnd = string.find(stringValue, "%)", subArgIndex)
        
        subArg = string.sub(subArg, 1, string.find(subArg, "%)"))
        subArgValue = string.gsub(subArg, "%)", "")
        
    end
    
    // use plain string values if there is no sub argument parsing defined
    if gCSSSubArgToValueFunc[argumentName] and subArgValue and found then
        subArgValue = gCSSSubArgToValueFunc[argumentName](subArgValue)
    end
    
    if not subArgIndex then
        subArgIndex = 1
    end  

    if found then
        stringValue = string.sub(stringValue, 1, subArgIndex - 1) .. string.sub(stringValue, stringEnd + 1, string.len(stringValue))
    end  

    return subArgValue, found, stringValue
    
end

// ----------------- CSS string values to internal values ------------------

local function GetColorValue(stringValue)

    local r = 1
    local g = 1
    local b = 1
    local a = 1
    
    if string.find(stringValue, "#") then

        stringValue = StringTrim(string.gsub(stringValue, "#", ""))
        r = HexStringToNumber(string.sub(stringValue, 1, 2)) / 255
        g = HexStringToNumber(string.sub(stringValue, 3, 4)) / 255
        b = HexStringToNumber(string.sub(stringValue, 5, 6)) / 255
    
    elseif string.find(stringValue, "rgb") then
    
        local result = GetSubArgument("rgb", stringValue)
        if not result then
            result = GetSubArgument("rgba", stringValue)
        end
        
        r = ConditionalValue(result[1], result[1], 1)
        g = ConditionalValue(result[2], result[2], 1)
        b = ConditionalValue(result[3], result[3], 1)
        a = ConditionalValue(result[4], result[4], 1)

    end

    return Color(r, g, b, a)
end
local function GetTextureValue(stringValue)

    local path = GetSubArgument("path", stringValue)
    local coords = GetSubArgument("coords", stringValue)
    local pixelCoords = GetSubArgument("pixelCoords", stringValue)

    return { Path = path, Coords = coords, PixelCoords = pixelCoords }
end
local function GetNumberValue(stringValue)  
    local stringValue = string.gsub(stringValue, "px", "")
    local number = 0
    
    local isPercentage = string.find(stringValue, "%%") ~= nil
    local stringValue = string.gsub(stringValue, "%%", "")
    number = tonumber(stringValue)
    
    if isPercentage then
        number = number / 100
    end    

    return { Number = number, IsPercentage = isPercentage }
end
local function GetVerticalAlignValue(stringValue)
    stringValue = StringTrim(stringValue)
    if stringValue == "top" then
        return GUIItem.Top
    elseif stringValue == "center" then
        return GUIItem.Center
    elseif stringValue == "bottom" then
        return GUIItem.Bottom
    end
end
local function GetHorizontalAlignValue(stringValue)
    stringValue = StringTrim(stringValue)
    if stringValue == "left" then
        return GUIItem.Left
    elseif stringValue == "center" then
        return GUIItem.Middle
    elseif stringValue == "right" then
        return GUIItem.Right
    end
end
local function GetTextAlignValue(stringValue)
    stringValue = StringTrim(stringValue)
    if stringValue == "left" or stringValue == "top" then
        return GUIItem.Align_Min
    elseif stringValue == "center" then
        return GUIItem.Align_Center
    elseif stringValue == "right" or stringValue == "bottom" then
        return GUIItem.Align_Max
    end
end
local function GetTrimmedStringValue(stringValue)
    return StringTrim(stringValue)
end    
local function GetBooleanValue(stringValue)
    stringValue = string.upper(StringTrim(stringValue))
    if stringValue == "TRUE" then
        return true
    elseif stringValue == "FALSE" then
        return false
    end    
end

gCSSToValueFunc["background-color"] = GetColorValue
gCSSToValueFunc["hover-background-color"] = GetColorValue
gCSSToValueFunc["background-image"] = GetTextureValue
gCSSToValueFunc["background-repeat"] = GetBooleanValue
gCSSToValueFunc["frame"] = GetNumberValue
gCSSToValueFunc["font-size"] = GetNumberValue
gCSSToValueFunc["font-scale"] = GetNumberValue
gCSSToValueFunc["opacity"] = GetNumberValue
gCSSToValueFunc["width"] = GetNumberValue
gCSSToValueFunc["height"] = GetNumberValue
gCSSToValueFunc["top"] = GetNumberValue
gCSSToValueFunc["left"] = GetNumberValue
gCSSToValueFunc["bottom"] = GetNumberValue
gCSSToValueFunc["right"] = GetNumberValue
gCSSToValueFunc["text-color"] = GetColorValue
gCSSToValueFunc["hover-text-color"] = GetColorValue
gCSSToValueFunc["vertical-align"] = GetVerticalAlignValue
gCSSToValueFunc["horizontal-align"] = GetHorizontalAlignValue
gCSSToValueFunc["min-height"] = GetNumberValue
gCSSToValueFunc["min-width"] = GetNumberValue
gCSSToValueFunc["border-color"] = GetColorValue
gCSSToValueFunc["border-width"] = GetNumberValue
gCSSToValueFunc["text-align"] = GetTextAlignValue
gCSSToValueFunc["vertical-text-align"] = GetTextAlignValue
gCSSToValueFunc["font-name"] = GetTrimmedStringValue
gCSSToValueFunc["text-padding"] = GetNumberValue
gCSSToValueFunc["text-padding-top"] = GetNumberValue
gCSSToValueFunc["text-padding-right"] = GetNumberValue
gCSSToValueFunc["text-padding-bottom"] = GetNumberValue
gCSSToValueFunc["text-padding-left"] = GetNumberValue
gCSSToValueFunc["ignore-margin"] = GetBooleanValue
gCSSToValueFunc["scaling"] = GetBooleanValue
gCSSToValueFunc["margin-top"] = GetNumberValue
gCSSToValueFunc["margin-right"] = GetNumberValue
gCSSToValueFunc["margin-bottom"] = GetNumberValue
gCSSToValueFunc["margin-left"] = GetNumberValue
gCSSToValueFunc["cell-spacing"] = GetNumberValue
gCSSToValueFunc["cell-padding"] = GetNumberValue
gCSSToValueFunc["vertical-cell-padding"] = GetNumberValue
gCSSToValueFunc["inherit-opacity"] = GetBooleanValue
gCSSToValueFunc["visible"] = GetBooleanValue


function ResetCSSStyles()
    gCurrentStyle = {}
end

function LoadCSSFile(fileName)

    Script.Load(fileName)
    local currentClassNames = {}
    
    // is true when we are inside brackets
    local parsingAttributes = false
    local currentCSS = css
    local nextIndex = 1
    for i = 1, string.len(css) do
    
        if string.len(currentCSS) <= 1 then
            break
        end

        local currentReference, nextIndex = GetClassNames(currentCSS)
        currentCSS = string.sub(currentCSS, nextIndex, string.len(currentCSS))
        
        local attributes, nextIndex = GetAttributes(currentCSS)
        currentCSS = string.sub(currentCSS, nextIndex, string.len(currentCSS))
        
        for index, reference in ipairs(currentReference) do
            for index, attribute in ipairs(attributes) do
                if not string.find(attribute, "//") and string.find(attribute, ":") then
                    local attributeSplitted = StringSplit(attribute, ":")
                    StoreClassAttribute(reference, StringTrim(attributeSplitted[1]), attributeSplitted[2])
                end
            end
        end
    
    end

end 

// search for the first '{' and return the class names + new start index
function GetClassNames(css)

    local namesUntilIndex = string.find(css, "{")
    
    if namesUntilIndex then
        local classNamesString = string.lower(string.sub(css, 1, namesUntilIndex - 1))
        local classNames = StringSplit(classNamesString, ",")
        
        local classNamesDependencies = {}
        
        for index, className in ipairs(classNames) do
        
            className = StringTrim(className)
        
            local dependency = nil
            local ref = nil
            
            if not string.find(className, " ") then
                ref = StringSplit(className, "%.")
            else    
                local splitted = StringSplit(className, " ")

                ref = StringSplit(splitted[#splitted], "%.")
                
                dependency = ""
                for i = 1, #splitted - 1 do
                    dependency = dependency .. splitted[i] .. " "
                end
                
            end
            
            local reference = { Dependency = dependency, TagName = ref[1], ClassName = ref[2]}
            
            /*
            Print("Dependency: %s", ToString(reference.Dependency))
            Print("TagName: %s", ToString(reference.TagName))
            Print("ClassName: %s", ToString(reference.ClassName))
            */
            
            table.insert(classNamesDependencies, reference)
        end
        
        return classNamesDependencies, namesUntilIndex + 1
    else
        return {}, string.len(css)
    end    

end

function GetAttributes(css)

    local attributesUntilIndex = string.find(css, "}")
    
    if attributesUntilIndex then
    
        local attributeString = StringTrim(string.sub(css, 1, attributesUntilIndex - 1))
        return StringSplit(string.sub(attributeString, 1, attributesUntilIndex - 1), ";"), attributesUntilIndex + 1
        
    else
        return nil, string.len(css)    
    end
    
end

function StoreClassAttribute(reference, attribute, value)

    // stop here already since we have no implementation for that css attribute
    if not gCSSToMenuElementFunc[attribute] or not gCSSToValueFunc[attribute] then
        Print(" :" .. attribute .. ": not implemented")
        return
    end

    if reference.Dependency == nil or reference.Dependency == "" then
        reference.Dependency = "none"
    end
    
    if not reference.ClassName or reference.ClassName == "" then
        reference.ClassName = "none"
    end
    
    if not gCurrentStyle[reference.ClassName] then
        gCurrentStyle[reference.ClassName] = {}
    end
    
    local animTime, found, value = GetSubArgument("time", value)
    local animFunc, found, value = GetSubArgument("func", value)
    local animName, found, value = GetSubArgument("animName", value)
    
    local styleEntry = {
        Dependency = StringTrim(reference.Dependency),
        RequiredTag = StringTrim(reference.TagName),
        Function = gCSSToMenuElementFunc[attribute],
        Value = { Specific = gCSSToValueFunc[attribute](value), AnimTime = animTime, AnimFunc = animFunc, AnimName = animName }
    }

    /*
    Print("---- entry for class name %s ----", ToString(reference.ClassName))
    Print("Dependency: %s", ToString(styleEntry.Dependency))
    Print("RequiredTag: %s", ToString(styleEntry.RequiredTag))
    Print("Function: %s", ToString(styleEntry.Function))
    Print("Value: %s", ToString(styleEntry.Value))
    Print("---------------------------------")
    */
    
    table.insert(gCurrentStyle[reference.ClassName], styleEntry)

end

local function CheckDependency(menuElement, dependency)

    local reqParents = StringSplit(StringTrim(dependency), " ")  
    local currentParent = menuElement
    local index = #reqParents
    
    for i = 1, #reqParents do

        currentParent = currentParent:GetParent()
        local reqParent = StringSplit(reqParents[index], "%.")
        reqParent[1] = ConditionalValue(reqParent[1] == nil, "", reqParent[1])
        reqParent[2] = ConditionalValue(reqParent[2] == "", nil, reqParent[2])
        
        local reqTag = reqParent[1]
        local reqClass = reqParent[2]
        
        if not currentParent then
            return false
        end

        if (reqTag and reqTag ~= "" and currentParent:GetTagName() ~= reqTag) or (reqClass and reqClass ~= "" and reqClass ~= "none" and not currentParent:HasCSSClass(reqClass)) then
            return false
        end
        
        index = index - 1
    
    end
    
    return true

end

local function InternalApplyAttribute(classTable, menuElement)

    local tagName = menuElement:GetTagName()
    local parentTag = menuElement:GetParentTagName()

    if classTable then
        for index, attribute in ipairs(classTable) do

            if ( (not attribute.RequiredTag or string.len(attribute.RequiredTag) == 0) or attribute.RequiredTag == tagName ) and
               ( attribute.Dependency == "none" or CheckDependency(menuElement, attribute.Dependency) ) then

                attribute.Function(menuElement, attribute.Value.Specific, attribute.Value.AnimTime, attribute.Value.AnimFunc, attribute.Value.AnimName)
                
            end
            
        end
    end

end

function ApplyStylesTo(menuElement, className)
 
    // apply class specific styles afterwards, to overwrite the general style
    if className and gCurrentStyle[className] then
        InternalApplyAttribute(gCurrentStyle[className], menuElement)
    end

end