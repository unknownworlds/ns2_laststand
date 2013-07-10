// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAnimatedScript.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages creation/destruction and update of animated gui items. There are no looping or oscilating
// animation types pre defined, but those can be easily realised through callbacks which gives way more
// control if desired.
//
// API:
//
// derive your gui script from GUIAnimatedScript and use self: to create GUIAnimatedItems
//
// self:CreateAnimatedGraphicItem() returns GUIAnimatedItem
// self:CreateAnimatedTextItem() returns GUIAnimatedItem
//
// implement optionally OnAnimationCompleted(animatedItem, animationName) to react on finished animations
//
// you don't need to clean up GUIAnimatedItems, this will be done in GUIAnimatedScript:Uninitialize()
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIAnimationUtility.lua")
Script.Load("lua/GUIAnimatedItem.lua")

class 'GUIAnimatedScript' (GUIScript)

function GUIAnimatedScript:Initialize()

    self.guiItems = {}
    self.guiAnimatedItems = {}
    self.scale = Client.GetScreenHeight() / kBaseScreenHeight
    
end

function GUIAnimatedScript:Reset()

    local prevPos = Vector(0,0,0)
    local prevSize = Vector(0,0,0)
    local fontSize = 0
    
    for index, item in ipairs(self.guiItems) do
        item:SetUniformScale(self.scale)
    end
    
end

function GUIAnimatedScript:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight
    self:Reset()
    
end    

// clean up animation items, make sure child classes call this or don't have an Uninitialize function of their own
function GUIAnimatedScript:Uninitialize()
   
    local guiItems = self.guiItems
    while #guiItems > 0 do
        local item = guiItems[1]
        item:Destroy()
    end
    
end

function GUIAnimatedScript:Update(deltaTime)

    PROFILE("GUIAnimatedScript:Update")

    if deltaTime then
        UpdateAnimTime(deltaTime)
    end

    local animatingItems    = self.guiAnimatedItems
    local numAnimatingtems  = #animatingItems
   
    local animationCompleteEvents = {}
    local completedItems = {}
    local removeItems = {}
    
    // update the animations
    
    for index = 1, numAnimatingtems do
    
        local item = animatingItems[index]
        ASSERT(item.guiItem ~= nil)
        
        local events, finished = item:Update(deltaTime)

        if events ~= nil then
            for index, event in ipairs(events) do
                table.insert(animationCompleteEvents, event)
            end
            if finished then
                table.insert(completedItems, item)
                table.insert(removeItems, item)
            end
        else
            table.insert(removeItems, item)
        end
        
    end
        
    // Remove all of the items which have finished animating.
    local RemoveAnimatingItem = self.RemoveAnimatingItem
    for index = 1, #removeItems do
        local removeItem = removeItems[index]
        RemoveAnimatingItem(self, removeItem)    
    end
    
    // call event hook for OnAnimationCompleted
    for index, completedAnim in ipairs(animationCompleteEvents) do
    
        if completedAnim.Name then
            self:OnAnimationCompleted(completedAnim.Handle, completedAnim.Name, completedAnim.ItemHandle)
        end
        
        // pass the object handle of this script and the GUIAnimatedItem to give more freedom with callbacks
        if completedAnim.Callback then
            completedAnim.Callback(self, completedAnim.ItemHandle)
        end
    end
    
    for index, completedItem in ipairs(completedItems) do
        self:OnAnimationsEnd(completedItem)
    end

end

local function AddItem(self, item)

    ASSERT( item.listIndex == nil )
    
    table.insert(self.guiItems, item)
    item.listIndex = #self.guiItems

end

function GUIAnimatedScript:RemoveItem(item)

    PROFILE("GUIAnimatedScript:RemoveItem")
    
    ASSERT(item.listIndex ~= nil)
    
    if item.animatedListIndex ~= nil then
        self:RemoveAnimatingItem(item)
    end        
    
    local listItems = self.guiItems
    local numItems = #listItems
    
    local lastItem = listItems[numItems]
    
    listItems[item.listIndex] = lastItem
    lastItem.listIndex = item.listIndex
    table.remove(listItems)
    
    item.listIndex = nil
    
end

function GUIAnimatedScript:AddAnimatingItem(item)
    if item.animatedListIndex == nil then
        table.insert(self.guiAnimatedItems, item)
        item.animatedListIndex = #self.guiAnimatedItems
    end        
end

function GUIAnimatedScript:RemoveAnimatingItem(item)
    
    PROFILE("GUIAnimatedScript:RemoveAnimatingItem")
    
    ASSERT(item.animatedListIndex ~= nil)
    
    local animatedItems = self.guiAnimatedItems
    local numAnimatedItems = #animatedItems
    
    local lastItem = animatedItems[numAnimatedItems]
    
    animatedItems[item.animatedListIndex] = lastItem
    lastItem.animatedListIndex = item.animatedListIndex
    table.remove(animatedItems)
    
    item.animatedListIndex = nil
    
end

function GUIAnimatedScript:CreateAnimatedGraphicItem()

    local newItem = GUIAnimatedItem()    
    newItem:Initialize(self)
    newItem:SetUniformScale(self.scale)
    
    AddItem(self, newItem)
    
    return newItem

end

function GUIAnimatedScript:CreateAnimatedTextItem()

    local newItem = GUIAnimatedItem()
    newItem:Initialize(self)
    newItem:SetUniformScale(self.scale)
    newItem.guiItem:SetOptionFlag(GUIItem.ManageRender)
    
    AddItem(self, newItem)
    
    return newItem

end

function GUIAnimatedScript:NotifyGUIItemDestroyed(destroyedItem)

    for _, animatedItem in ipairs(self.guiAnimatedItems) do
        animatedItem:NotifyGUIItemDestroyed(destroyedItem)
    end

end

function GUIAnimatedScript:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end

// called when the last animation remaining has completed this frame
function GUIAnimatedScript:OnAnimationsEnd(item)
end