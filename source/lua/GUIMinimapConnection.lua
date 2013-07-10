// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimapConnection.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used for rendering connections on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMinimapConnection'

local kLineColor = Color(1, 1, 1, 0.3)

function GUIMinimapConnection:Setup(startPoint, endPoint, parent)

    assert(startPoint:isa("Vector"))
    assert(endPoint:isa("Vector"))
    assert(parent)
    
    if startPoint ~= self.startPoint or endPoint ~= self.endPoint or self.parent ~= parent then

        local direction = GetNormalizedVector(startPoint - endPoint)
        local rotation = math.atan2(direction.x, direction.y)
        if rotation < 0 then
            rotation = rotation + math.pi * 2
        end

        rotation = rotation + math.pi * 0.5

        self.startPoint = Vector(startPoint)
        self.endPoint = Vector(endPoint)
        self.parent = parent
        self.rotationVec = Vector(0, 0, rotation)
        
        local delta = self.endPoint - self.startPoint
        self.length = math.sqrt(delta.x ^ 2 + delta.y ^ 2)
        
        self:Render()
    
    end

end

function GUIMinimapConnection:SetStencilFunc(func)

    if self.line then
        self.line:SetStencilFunc(func)
    end
    
    self.stencilFunc = func
    
end

function GUIMinimapConnection:Uninitialize()

    if self.line then
        GUI.DestroyItem(self.line)
        self.line = nil
    end

end

function GUIMinimapConnection:Render()

    if not self.line then

        self.line = GetGUIManager():CreateGraphicItem()
        self.line:SetColor(kLineColor)
        self.line:SetAnchor(GUIItem.Center, GUIItem.Middle)
        self.line:SetStencilFunc(self.stencilFunc)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end
    
    self.line:SetSize(Vector(self.length, 2, 0))
    self.line:SetPosition(self.startPoint)
    self.line:SetRotationOffset(Vector(-self.length, 0, 0))
    self.line:SetRotation(self.rotationVec)
    
    // update line parent
    local currentParent = self.line:GetParent()
    if currentParent and currentParent ~= self.parent then
    
        currentParent:RemoveChild(self.line)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end

end
