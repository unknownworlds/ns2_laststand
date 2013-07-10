
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDial.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a circular dial. Used to show health, armor, progress, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIDial' (GUIScript)

function GUIDial:Initialize(settingsTable)

    self.percentage = 1
    
    // Background.
    self.dialBackground = GUIManager:CreateGraphicItem()
    self.dialBackground:SetSize(Vector(settingsTable.BackgroundWidth, settingsTable.BackgroundHeight, 0))
    self.dialBackground:SetAnchor(settingsTable.BackgroundAnchorX, settingsTable.BackgroundAnchorY)
    self.dialBackground:SetPosition(Vector(0, -settingsTable.BackgroundHeight, 0) + settingsTable.BackgroundOffset)

    if settingsTable.BackgroundTextureName ~= nil then
        self.dialBackground:SetTexture(settingsTable.BackgroundTextureName)
    else
        self.dialBackground:SetColor(Color(1, 1, 1, 0))
    end
    
    self.dialBackground:SetTexturePixelCoordinates(settingsTable.BackgroundTextureX1, settingsTable.BackgroundTextureY1,
                                                   settingsTable.BackgroundTextureX2, settingsTable.BackgroundTextureY2)
                                              
    self.dialBackground:SetClearsStencilBuffer(true)                                            


    // Left side.

    self.leftSideMask = GUIManager:CreateGraphicItem()
    self.leftSideMask:SetIsStencil(true)
    self.leftSideMask:SetSize(Vector(settingsTable.BackgroundWidth, settingsTable.BackgroundHeight * 2, 0))
    self.leftSideMask:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.leftSideMask:SetPosition(Vector(0, -(settingsTable.BackgroundHeight), 0))
    self.leftSideMask:SetRotationOffset(Vector(-settingsTable.BackgroundWidth, 0, 0))
    self.leftSideMask:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    
    self.leftSide = GUIManager:CreateGraphicItem()
    self.leftSide:SetStencilFunc(GUIItem.Equal)
    self.leftSide:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight, 0))
    self.leftSide:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.leftSide:SetPosition(Vector(-settingsTable.BackgroundWidth / 2, -(settingsTable.BackgroundHeight / 2), 0))
    self.leftSide:SetRotationOffset(Vector(settingsTable.BackgroundWidth / 2, 0, 0))
    self.leftSide:SetTexture(settingsTable.ForegroundTextureName)
    self.leftSide:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    // Cut off so only the left side of the texture is displayed on the self.leftSide.
    local x2 = settingsTable.ForegroundTextureX2 - settingsTable.ForegroundTextureWidth / 2
    self.leftSide:SetTexturePixelCoordinates(settingsTable.ForegroundTextureX1, settingsTable.ForegroundTextureY1,
                                             x2, settingsTable.ForegroundTextureY2)

    // Right side.
    self.rightSideMask = GUIManager:CreateGraphicItem()
    self.rightSideMask:SetIsStencil(true)
    self.rightSideMask:SetSize(Vector(settingsTable.BackgroundWidth, settingsTable.BackgroundHeight * 2, 0))
    self.rightSideMask:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.rightSideMask:SetPosition(Vector(-settingsTable.BackgroundWidth, -(settingsTable.BackgroundHeight), 0))
    self.rightSideMask:SetRotationOffset(Vector(settingsTable.BackgroundWidth, 0, 0))
    self.rightSideMask:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    
    self.rightSide = GUIManager:CreateGraphicItem()
    self.rightSide:SetStencilFunc(GUIItem.Equal)
    self.rightSide:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight, 0))
    self.rightSide:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.rightSide:SetPosition(Vector(0, -(settingsTable.BackgroundHeight / 2), 0))
    self.rightSide:SetTexture(settingsTable.ForegroundTextureName)
    self.rightSide:SetRotationOffset(Vector(-settingsTable.BackgroundWidth / 2, 0, 0))
    self.rightSide:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    // Cut off so only the right side of the texture is displayed on the self.rightSide.
    local x1 = settingsTable.ForegroundTextureX1 + settingsTable.ForegroundTextureWidth / 2
    self.rightSide:SetTexturePixelCoordinates(x1, settingsTable.ForegroundTextureY1,
                                              settingsTable.ForegroundTextureX2, settingsTable.ForegroundTextureY2)
    
    
    self.globalRotation = Vector(0,0,0)
    
    self.dialBackground:AddChild(self.leftSideMask)
    self.dialBackground:AddChild(self.leftSide)
    
    self.dialBackground:AddChild(self.rightSideMask)
    self.dialBackground:AddChild(self.rightSide)
    
end

function GUIDial:Uninitialize()

    GUI.DestroyItem(self.dialBackground)
    self.dialBackground = nil
    
end

// 'global' rotation. rotates all elements
function GUIDial:SetRotation(rotation)
    self.globalRotation.z = rotation
end

function GUIDial:SetForegroundTexture(texture)

    self.leftSide:SetTexture(texture)
    self.rightSide:SetTexture(texture)

end

function GUIDial:SetBackgroundTexture(texture)
    //self.dialBackground:SetTexture(texture)
end

function GUIDial:Update(deltaTime)

    PROFILE("GUIDial:Update")

    local leftPercentage = math.max(0, (self.percentage - 0.5) / 0.5)
    self.leftSideMask:SetRotation(self.globalRotation + Vector(0, 0, math.pi * (1 - leftPercentage)))
    
    local rightPercentage = math.max(0, math.min(0.5, self.percentage) / 0.5)
    self.rightSideMask:SetRotation(self.globalRotation + Vector(0, 0, math.pi * (1 - rightPercentage)))
    
    self.dialBackground:SetRotation(self.globalRotation)
    self.leftSide:SetRotation(self.globalRotation)
    self.rightSide:SetRotation(self.globalRotation)
    

end

function GUIDial:SetPercentage(setPercentage)

    self.percentage = setPercentage

end

function GUIDial:GetBackground()

    return self.dialBackground

end

function GUIDial:GetLeftSide()

    return self.leftSide
    
end

function GUIDial:GetRightSide()

    return self.rightSide
    
end

function GUIDial:SetIsVisible(isVisible)
    self.dialBackground:SetIsVisible(isVisible)
end    
