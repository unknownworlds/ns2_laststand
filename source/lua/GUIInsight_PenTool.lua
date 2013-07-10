// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_PenTool.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// Allows the spectator to draw on the screen
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_PenTool' (GUIScript)

local kDrawMode = enum( {'WorldPen', 'ScreenPen', 'None' } )
local drawMode

local worldPoints
local lineColors

local worldLines
local mapLines
local screenLines

local lastMouse
local lastTrace

function GUIInsight_PenTool:Initialize()

    drawMode = kDrawMode.None
    worldPoints = table.array(8)
    lineColors = table.array(8)
    
    worldLines = GUIManager:CreateLinesItem()
    worldLines:SetLayer(kGUILayerCountDown)
    
    --mapLines = GUIManager:CreateLinesItem()
    --mapLines:SetLayer(kGUILayerInsight)
    
    screenLines = GUIManager:CreateLinesItem()
    screenLines:SetLayer(kGUILayerCountDown)
    
    self.hasDrawn = false
    
end

function GUIInsight_PenTool:Uninitialize()
    
    worldPoints = nil
    GUI.DestroyItem(worldLines)
    --GUI.DestroyItem(mapLines)
    GUI.DestroyItem(screenLines)
    
end

function GUIInsight_PenTool:SetIsVisible(visible)

    worldLines:SetIsVisible(visible)
    screenLines:SetIsVisible(visible)
    
end

function GUIInsight_PenTool:SendKeyEvent(key, down)

    if down then
    
        if key == InputKey.Back and self.hasDrawn then
        
            self.hasDrawn = false
            worldPoints = table.array(8)
            lineColors = table.array(8)
            screenLines:ClearLines()
            return true
        
        end
    
        if key == InputKey.MouseButton1 then
        
            if drawMode == kDrawMode.None then
            
                table.insert(worldPoints, table.array(128))
                table.insert(lineColors, kPenToolColor)
                
            end
            drawMode = kDrawMode.WorldPen
            return true
            
        elseif key == InputKey.MouseButton2 then
        
            drawMode = kDrawMode.ScreenPen
            return true
        
        end
    
    else
    
        lastMouse = nil
        lastTrace = nil
    
    end
    
    drawMode = kDrawMode.None
    return false

end

function GUIInsight_PenTool:Update(deltaTime)

    if drawMode ~= kDrawMode.None then

        local mouseX, mouseY = Client.GetCursorPosScreen()
        if drawMode == kDrawMode.ScreenPen then
        
            local mouse = Vector(mouseX, mouseY, 0)
            if lastMouse then

                if mouse ~= lastMouse then
                
                    self.hasDrawn = true
                    screenLines:AddLine(lastMouse, mouse, kPenToolColor)
                
                end
                
            end
            lastMouse = mouse
            
        end
        
        if drawMode == kDrawMode.WorldPen then
        
            local player = Client.GetLocalPlayer()
            local pickVec = CreatePickRay(player, mouseX, mouseY)
            local trace = GetCommanderPickTarget(player, pickVec, false, false, true)
            
            if lastTrace then

                if trace ~= lastTrace then
                    self.hasDrawn = true
                    -- Don't allow drawing on walls or off the map
                    if trace.fraction < 1 and trace.normal:DotProduct(Vector(0, 1, 0)) > 0.9 then
                        table.insert(worldPoints[#worldPoints], trace.endPoint)
                    end
                    --local worldcoords = Coords.GetTranslation(trace.endPoint + trace.normal * 0.5)
                    --local mapcoords = Vector(PlotToMap(worldcoords.x, worldcoords.z, self.comMode, self.zoom))
                end

            end
            lastTrace = trace
           
        end
        
    end
    
    worldLines:ClearLines()
    for i = 1, #worldPoints do
        local linePoints = worldPoints[i]
        local firstPoint = linePoints[1]
        if firstPoint then
            local lineColor = lineColors[i]
            local player = Client.GetLocalPlayer()
            local viewCoordsZ = player:GetViewCoords().zAxis
            local eyePos = player:GetEyePos()
            
            local function InFront(point)
                return viewCoordsZ:DotProduct(GetNormalizedVector(point - eyePos)) > 0
            end
            
            local prevInFront = InFront(firstPoint)
            local previousPos = Client.WorldToScreen(firstPoint)
            for j = 2, #linePoints do
            
                local point = linePoints[j]
                local inFront = InFront(point)
                local screenPos = Client.WorldToScreen(point)
                if prevInFront and inFront then
                    worldLines:AddLine(previousPos, screenPos, lineColor)
                end
                prevInFront = inFront
                previousPos = screenPos
                
            end
            
        end
    
    end
    
end
