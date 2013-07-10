// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMapAnnotations.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages text that is drawn in the world to annotate maps.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/dkjson.lua")
Script.Load("lua/Globals.lua")

class 'GUIMapAnnotations' (GUIScript)

GUIMapAnnotations.kMaxDisplayDistance = 30

GUIMapAnnotations.kNumberOfDataFields = 6

local kAfterPostGetAnnotationsTime = 0.5

function GUIMapAnnotations:Initialize()

    self.visible = false
    self.annotations = { }
    self.getLatestAnnotationsTime = 0

end

function GUIMapAnnotations:Uninitialize()

    self:ClearAnnotations()
    
end

function GUIMapAnnotations:ClearAnnotations()

    for i, annotation in ipairs(self.annotations) do
        GUI.DestroyItem(annotation.Item)
    end
    self.annotations = { }

end

function GUIMapAnnotations:SetIsVisible(setVisible)
    self.visible = setVisible
end

function GUIMapAnnotations:GetIsVisible()
    return self.visible
end

function GUIMapAnnotations:AddAnnotation(text, worldOrigin)
    
    local annotationItem = { Item = GUIManager:CreateTextItem(), Origin = Vector(worldOrigin) }
    annotationItem.Item:SetLayer(kGUILayerDebugText)
    annotationItem.Item:SetFontSize(20)
    annotationItem.Item:SetAnchor(GUIItem.Left, GUIItem.Top)
    annotationItem.Item:SetTextAlignmentX(GUIItem.Align_Center)
    annotationItem.Item:SetTextAlignmentY(GUIItem.Align_Center)
    annotationItem.Item:SetColor(Color(1, 1, 1, 1))
    annotationItem.Item:SetText(text)
    annotationItem.Item:SetIsVisible(false)
    table.insert(self.annotations, annotationItem)
    
end

function GUIMapAnnotations:Update(deltaTime)

    PROFILE("GUIMapAnnotations:Update")

    for i, annotation in ipairs(self.annotations) do
    
        if not self.visible then
            annotation.Item:SetIsVisible(false)
        else
        
            // Set position according to position/orientation of local player.
            local screenPos = Client.WorldToScreen(Vector(annotation.Origin.x, annotation.Origin.y, annotation.Origin.z))
            
            local playerOrigin = PlayerUI_GetEyePos()
            local direction = annotation.Origin - playerOrigin
            local normToAnnotationVec = GetNormalizedVector(direction)
            local normViewVec = PlayerUI_GetForwardNormal()
            local dotProduct = normToAnnotationVec:DotProduct(normViewVec)
            
            local visible = true
            
            if screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
               screenPos.y < 0 or screenPos.y > Client.GetScreenHeight() or
               dotProduct < 0 then
               
                visible = false
                
            else
                annotation.Item:SetPosition(screenPos)
            end
            
            // Fade based on distance.
            local fadeAmount = (direction:GetLengthSquared()) / (GUIMapAnnotations.kMaxDisplayDistance * GUIMapAnnotations.kMaxDisplayDistance)
            if fadeAmount < 1 then
                annotation.Item:SetColor(Color(1, 1, 1, 1 - fadeAmount))
            else
                visible = false
            end
            
            annotation.Item:SetIsVisible(visible)
            
        end
        
    end
    
    if self.getLatestAnnotationsTime > 0 and Shared.GetTime() >= self.getLatestAnnotationsTime then
    
        self:GetLatestAnnotations()
        self.getLatestAnnotationsTime = 0
        
    end
    
end

local function ParseAnnotations(data)

    local obj, pos, err = json.decode(data, 1, nil)
    if err then
        Shared.Message("Error in parsing annotations: " .. ToString(err))
    else
    
        for k, v in pairs(obj) do
            ClientUI.GetScript("GUIMapAnnotations"):AddAnnotation(v.message, Vector(v.x, v.y, v.z))
        end
        
    end
    
end

function GUIMapAnnotations:GetLatestAnnotations(versionNumOverride, mapNameOverride)

    self:ClearAnnotations()
    
    local versionNumString = (versionNumOverride and ToString(versionNumOverride)) or ToString(Shared.GetBuildNumber())
    local mapName = string.lower(mapNameOverride or Shared.GetMapName())
    local requestURL = "http://sponitor2.herokuapp.com/api/get/annotations/" .. mapName .. "/" .. versionNumString .. "/"
    Shared.SendHTTPRequest(requestURL, "GET", { }, ParseAnnotations)
    
end

function GUIMapAnnotations:GetLatestAnnotationsLater(laterTime)

    assert(laterTime >=0)
    
    self.getLatestAnnotationsTime = Shared.GetTime() + laterTime

end

function OnCommandAnnotate(...)

    local info = StringConcatArgs(...)
    
    if info == nil then
    
        Print("Please provide some text to annotate")
        return
        
    end
    
    local origin = PlayerUI_GetEyePos()
    
    local params =
    {
        version = ToString(Shared.GetBuildNumber()),
        map = Shared.GetMapName(),
        x = string.format("%.2f", origin.x),
        y = string.format("%.2f", origin.y),
        z = string.format("%.2f", origin.z),
        message = info
    }
    Shared.SendHTTPRequest(kStatisticsURL .. "/location", "POST", params, function(data) Shared.Message(data) end)
    
    // Automatically update the annotations in a little bit so the user sees this new one.
    ClientUI.GetScript("GUIMapAnnotations"):GetLatestAnnotationsLater(kAfterPostGetAnnotationsTime)
    
    Shared.Message("Annotation sent! Thank you!")
    
end

function OnCommandDisplayAnnotations(versionNum, mapName)

    local visible = ClientUI.GetScript("GUIMapAnnotations"):GetIsVisible()
    ClientUI.GetScript("GUIMapAnnotations"):SetIsVisible(not visible)
    if not visible then
    
        Shared.Message("Annotations are visible.")
        
        ClientUI.GetScript("GUIMapAnnotations"):GetLatestAnnotations(versionNum, mapName)
        ClientUI.GetScript("GUIMapAnnotations"):SetIsVisible(true)
        
    else
        Shared.Message("Annotations are invisible.")
    end
    
end

Event.Hook("Console_annotate", OnCommandAnnotate)
Event.Hook("Console_displayannotations", OnCommandDisplayAnnotations)