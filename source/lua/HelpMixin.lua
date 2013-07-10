// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\HelpMixin.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kStartHelpSound = "sound/NS2.fev/common/tooltip_on"
local kLearnedHelpSound = "sound/NS2.fev/common/tooltip_off"
Client.PrecacheLocalSound(kStartHelpSound)
Client.PrecacheLocalSound(kLearnedHelpSound)

local kHelpWidgetAnimateInTime = 4
local function CreateFadeInElasticAnimation(guiItem, size, position, optionalCallback)

    guiItem:DestroyAnimations()
    guiItem:SetSize(Vector(size.x / 2, size.y / 2, 0))
    guiItem:SetSize(Vector(size.x, size.y, 0), kHelpWidgetAnimateInTime,  nil, AnimateElastic)
    guiItem:SetPosition(position / 2)
    guiItem:SetPosition(position, kHelpWidgetAnimateInTime, nil, AnimateElastic)
    guiItem:SetColor(Color(1, 1, 1, 0))
    guiItem:SetColor(Color(1, 1, 1, 1), kHelpWidgetAnimateInTime / 4,  nil, AnimateLinear, optionalCallback)
    
end

function HelpWidgetAnimateIn(guiItem)

    StartSoundEffect(kStartHelpSound)
    
    local size = guiItem:GetSize()
    local position = Vector(-size.x / 2, -size.y, 0)
    CreateFadeInElasticAnimation(guiItem, size, position)
    
end

local kCheckMarkFileName = "ui/checkmark.dds"
local kCheckMarkSize = 128
local function CreateCheckMarkAnimation(guiScript)

    if guiScript:isa("GUIAnimatedScript") then
    
        assert(guiScript.checkMarkItem == nil)
        
        local item = guiScript:CreateAnimatedGraphicItem()
        item:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
        item:SetSize(Vector(kCheckMarkSize, kCheckMarkSize, 0))
        item:SetPosition(Vector(-kCheckMarkSize / 2, -kCheckMarkSize + kHelpBackgroundYOffset, 0))
        item:SetTexture(kCheckMarkFileName)
        
        // Fade out after some time.
        local function fadeOutFunc()
            item:SetColor(Color(1, 1, 1, 0), 2,  nil, AnimateQuadratic)
        end
        
        CreateFadeInElasticAnimation(item, item:GetSize(), item:GetPosition(), fadeOutFunc)
        
        guiScript.checkMarkItem = item
        
    end
    
end

function HelpWidgetIncreaseUse(guiScript, className)

    StartSoundEffect(kLearnedHelpSound)
    
    local classNameLower = string.lower(className)
    Client.SetOptionInteger("help/" .. classNameLower, Client.GetOptionInteger("help/" .. classNameLower, 0) + 1)
    
    CreateCheckMarkAnimation(guiScript)
    
end

HelpMixin = CreateMixin(HelpMixin)
HelpMixin.type = "Help"

assert(Server == nil)

kHelpBackgroundYOffset = -150

function HelpMixin:__initmixin()
    self.activeHelpWidget = nil
end

function HelpMixin:AddHelpWidget(setGUIName, limit)

    // Do not display while spectating.
    if self == Client.GetLocalPlayer() and Client.GetIsControllingPlayer() then
    
        // Only draw if we have hints enabled.
        if Client.GetOptionBoolean("showHints", true) then
        
            // Only one help widget allowed at a time.
            if self.activeHelpWidget == nil then
            
                -- Don't display widgets the ready room
                if self:GetTeamNumber() ~= kNeutralTeamType then
                
                    local optionName = "help/" .. string.lower(setGUIName)
                    local currentAmount = Client.GetOptionInteger(optionName, 0)
                    if currentAmount < limit then
                        self.activeHelpWidget = GetGUIManager():CreateGUIScript(setGUIName)
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

local function DestroyUI(self)

    if self.activeHelpWidget then
    
        if self.activeHelpWidget.checkMarkItem then
        
            self.activeHelpWidget.checkMarkItem:Destroy()
            self.activeHelpWidget.checkMarkItem = nil
            
        end
        
        GetGUIManager():DestroyGUIScript(self.activeHelpWidget)
        
    end
    self.activeHelpWidget = nil
    
end

function HelpMixin:OnKillClient()
    DestroyUI(self)
end

function HelpMixin:OnDestroy()
    DestroyUI(self)
end