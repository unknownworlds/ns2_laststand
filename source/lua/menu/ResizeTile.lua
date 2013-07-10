// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\ResizeTile.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

local kDefaultSize = Vector(32, 32, 0)
local kDefaultTexture = ""
local kDefaultColor = Color(0.7, 0.7, 0.7)

class 'ResizeTile' (MenuElement)

function ResizeTile:Initialize()

    MenuElement.Initialize(self)
    
    self:SetBackgroundSize(kDefaultSize)
    self:SetBackgroundTexture(kDefaultTexture)
    self:SetBackgroundColor(kDefaultColor)
    
    self.isDragged = false
    
    local eventCallBacks = {
    
        OnMouseOver = function (self, mousePressed)
            self:Drag(mousePressed)
        end,

        OnMouseOut = function (self, mousePressed)
            self:Drag(mousePressed)
        end,

        OnMouseDown = function (self)
            self.isDragged = true
        end,

        OnMouseUp = function (self)
            self.isDragged = false
        end,
    
    }
    
    self:AddEventCallbacks(eventCallBacks)

end

function ResizeTile:GetTagName()
    return "resizetile"
end    

function ResizeTile:Drag(mousePressed)

    if self.isDragged then
    
        if not mousePressed or not self:GetParent() then
            self.isDragged = false
            return
        end

        // resize the window
        local windowSize = self:GetParent():GetBackground():GetSize()
        windowSize = windowSize + MouseTracker_GetMouseMovement()

        self:GetParent():SetBackgroundSize(windowSize)
    
    end

end
 