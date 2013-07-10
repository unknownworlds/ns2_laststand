// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_Overhead.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Spectator Overhead: Displays mouse over text and loads healthbars
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_Overhead' (GUIScript)

local mouseoverBackground
local mouseoverText
local mouseoverTextBack

local kFontName = "fonts/AgencyFB_medium.fnt"
local kFontScale = GUIScale(Vector(1, 0.8, 0))

local showHints

local isFollowing

function GUIInsight_Overhead:Initialize()

    isFollowing = false

    mouseoverBackground = GUIManager:CreateGraphicItem()
    mouseoverBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    mouseoverBackground:SetLayer(kGUILayerPlayerHUD)
    mouseoverBackground:SetColor(Color(1, 1, 1, 0))
    mouseoverBackground:SetIsVisible(false)

    mouseoverText = GUIManager:CreateTextItem()
    mouseoverText:SetFontName(kFontName)
    mouseoverText:SetScale(kFontScale)
    mouseoverText:SetColor(Color(1, 1, 1, 1))
    mouseoverText:SetFontIsBold(true)
    
    mouseoverTextBack = GUIManager:CreateTextItem()
    mouseoverTextBack:SetFontName(kFontName)
    mouseoverTextBack:SetScale(kFontScale)
    mouseoverTextBack:SetColor(Color(0, 0, 0, 0.8))
    mouseoverTextBack:SetFontIsBold(true)
    mouseoverTextBack:SetPosition(GUIScale(Vector(3,3,0)))

    mouseoverBackground:AddChild(mouseoverTextBack)
    mouseoverBackground:AddChild(mouseoverText)
    
    showHints = Client.GetOptionBoolean("showHints", true) == true

    if showHints then
        GetGUIManager():CreateGUIScriptSingle("GUIInsight_Logout")
    end
    //GetGUIManager():CreateGUIScriptSingle("GUIMarqueeSelection")
    
end

function GUIInsight_Overhead:Uninitialize()

    GUI.DestroyItem(mouseoverBackground)
    
    if self.playerHealthbars then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_PlayerHealthbars")
        self.playerHealthbars = nil
    end
    if self.otherHealthbars then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_OtherHealthbars")
        self.otherHealthbars = nil
    end
    if showHints then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_Logout")
    end
    //GetGUIManager():DestroyGUIScriptSingle("GUIMarqueeSelection")
    
end

local function GetEntityUnderCursor(player)

    local xScalar, yScalar = Client.GetCursorPos()
    local x = xScalar * Client.GetScreenWidth()
    local y = yScalar * Client.GetScreenHeight()
    local pickVec = CreatePickRay(player, x, y)
    
    local origin = player:GetOrigin()
    local trace = Shared.TraceRay(origin, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(self))
    local recastCount = 0
    while trace.entity == nil and trace.fraction < 1 and trace.normal:DotProduct(Vector(0, 1, 0)) < 0 and recastCount < 3 do
        // We've hit static geometry with the normal pointing down (ceiling). Re-cast from the point of impact.
        local recastFrom = 1000 * trace.fraction + 0.1
        trace = Shared.TraceRay(origin + pickVec*recastFrom, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(self))
        recastCount = recastCount + 1
    end
    
    return trace.entity
    
end

function GUIInsight_Overhead:SendKeyEvent(key, down)

    local previous = isFollowing
    isFollowing = down and GetIsBinding(key, "Weapon2")
    
    // Attempt to teleport to the mapblip with the same entityId
    // this will prevent issues where the entity is not available on the client due to range
    if not previous and isFollowing then
        local player = Client.GetLocalPlayer()
        local entityId = player.selectedId
        if entityId then 
            
            for _, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do

                if blip.ownerEntityId == entityId then
                
                    local player = Client.GetLocalPlayer()
                    local blipOrig = blip:GetOrigin()
                    player:SetWorldScrollPosition(blipOrig.x-5, blipOrig.z)
                    
                end            
            end
        end 
    end

end

function GUIInsight_Overhead:Update(deltaTime)
    
    local player = Client.GetLocalPlayer()
    if player == nil then
        return
    end
    
    -- Only initialize healthbars after the camera has finished animating
    -- Should help smooth transition to overhead
    if not PlayerUI_IsCameraAnimated() then
    
        if self.playerHealthbars == nil then
            self.playerHealthbars = GetGUIManager():CreateGUIScriptSingle("GUIInsight_PlayerHealthbars")
        end
        if self.otherHealthbars == nil then
            self.otherHealthbars = GetGUIManager():CreateGUIScriptSingle("GUIInsight_OtherHealthbars")
        end
        
        // Follow selected player
        if isFollowing and player.selectedId then
            local entity = Shared.GetEntity(player.selectedId)
            if entity then
                local origin = entity:GetOrigin()
                player:SetWorldScrollPosition(origin.x-5, origin.z)
            end     
        end
            
    end
    
    -- Store entity under cursor
    player.entityUnderCursor = GetEntityUnderCursor(player)
    local entity = player.entityUnderCursor
    
    if entity ~= nil and HasMixin(entity, "Live") and entity:GetIsAlive() then

        local text = ToString(math.ceil(entity:GetHealthScalar() * 100)) .. "%"
        
        if HasMixin(entity, "Construct") then
            if not entity:GetIsBuilt() then
            
                local builtStr
                if entity:GetTeamNumber() == kTeam1Index then
                    builtStr = "Built"
                else
                    builtStr = "Grown"
                end
                local constructionStr = string.format(" (%d%% %s)", math.ceil(entity:GetBuiltFraction()*100), builtStr)
                text = text .. constructionStr   
                
            end
        end
 
        local xScalar, yScalar = Client.GetCursorPos()
        local x = xScalar * Client.GetScreenWidth()
        local y = yScalar * Client.GetScreenHeight()
        mouseoverBackground:SetPosition(Vector(x + 10, y + 18, 0))
        mouseoverBackground:SetIsVisible(true)
        
        mouseoverText:SetText(text)
        mouseoverTextBack:SetText(text)

    else

        mouseoverBackground:SetIsVisible(false)

    end
    
end