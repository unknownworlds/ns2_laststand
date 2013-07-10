// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\LogView.lua
//
//    Created by:   Marc Delorme (marcdelorme@unknownworlds.com)
//
//    Display text line by line
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/RingBuffer.lua")

class 'LogView' (MenuElement)

function LogView:Render()

	self:ClearChildren()

	self.fonts = {}

	for i, item in ipairs(self.texts:ToTable()) do

		table.insert(self.fonts, CreateMenuElement(self, "Font") )
        self.fonts[i]:SetText(item.text)
        if item.class then
        	self.fonts[i]:SetCSSClass(item.class)
        end

	end

	self:UpdateBackgroundSize()

end

function LogView:GetTagName()
    return "logview"
end

function LogView:AddText(text, class)

	self.texts:Insert({text=text, class=class})
	self:Render()

end

function LogView:UpdateBackgroundSize()

	local bgSize = Vector(0, 0, 0)

	for i, el in ipairs(self.fonts) do

		if i > 1 then
            self.fonts[i]:SetTopOffset( bgSize.y )
        end

        bgSize.x = math.max(bgSize.x, el:GetWidth())
        bgSize.y = bgSize.y + el:GetHeight()

    end

    self:SetBackgroundSize(bgSize, true)

    self:ReloadCSSClass()

end

function LogView:Initialize()

	MenuElement.Initialize(self)
	self.texts = CreateRingBuffer(10)

end

function LogView:Update(deltatime)
end