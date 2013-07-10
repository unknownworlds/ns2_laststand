// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Client only.
assert(Server == nil)

kGUILayerDebugText = 0
kGUILayerDeathScreen = 1
kGUILayerTipVideos = 2
kGUILayerChat = 3
kGUILayerPlayerNameTags = 4
kGUILayerPlayerHUDBackground = 5
kGUILayerPlayerHUD = 6
kGUILayerPlayerHUDForeground1 = 7
kGUILayerPlayerHUDForeground2 = 8
kGUILayerPlayerHUDForeground3 = 9
kGUILayerPlayerHUDForeground4 = 10
kGUILayerCommanderAlerts = 11
kGUILayerCommanderHUD = 12
kGUILayerLocationText = 13
kGUILayerMinimap = 14
kGUILayerScoreboard = 15
kGUILayerCountDown = 16
kGUILayerTestEvents = 17
kGUILayerMainMenu = 20
// The Web layer must be much higher than the MainMenu layer
// because the MainMenu layer inserts items above
// kGUILayerMainMenu procedurally.
kGUILayerMainMenuWeb = 50

// Check required because of material scripts.
if Client and Event then

    Script.Load("lua/menu/WindowManager.lua")
    Script.Load("lua/InputHandler.lua")
    
end

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")

local function CreateManager()
    local manager = GUIManager()
    manager:Initialize()
    return manager
end

class 'GUIManager'

function GUIManager:Initialize()

    self.scripts = { }
    self.scriptsSingle = { }
end

function GetGUIManager()
    return gGUIManager
end

function GUIManager:GetNumberScripts()
    return table.count(self.scripts) + table.count(self.scriptsSingle)
end

local function SharedCreate(scriptName)

    Script.Load("lua/" .. scriptName .. ".lua")
    
    local result = StringSplit(scriptName, "/")    
    scriptName = result[table.count(result)]
    
    local creationFunction = _G[scriptName]
    if creationFunction == nil then
    
        Shared.Message("Error: Failed to load GUI script named " .. scriptName)
        return nil
        
    else
    
        local newScript = creationFunction()
        newScript._scriptName = scriptName
        newScript:Initialize()
        return newScript
        
    end
    
end

function GUIManager:CreateGUIScript(scriptName)

    local createdScript = SharedCreate(scriptName)
    
    if createdScript ~= nil then
        table.insert(self.scripts, createdScript)
    end
    
    return createdScript
    
end

// Only ever create one of this named script.
// Just return the already created one if it already exists.
function GUIManager:CreateGUIScriptSingle(scriptName)
    
    // Check if it already exists
    for index, script in ipairs(self.scriptsSingle) do
    
        if script[2] == scriptName then
            return script[1]
        end
        
    end
    
    // Not found, create the single instance.
    local createdScript = SharedCreate(scriptName)
    
    if createdScript ~= nil then
    
        table.insert(self.scriptsSingle, { createdScript, scriptName })
        return createdScript
        
    end
    
    return nil
    
end

function GUIManager:SetHUDMapEnabled(enabled)

    for index, script in ipairs(self.scripts) do
    
        if script.SetHUDMapEnabled then
            script:SetHUDMapEnabled(enabled)
        end
    
    end
    
    for index, scriptSingle in ipairs(self.scriptsSingle) do
    
        if scriptSingle.SetHUDMapEnabled then
            scriptSingle:SetHUDMapEnabled(enabled)
        end
    
    end

end

function GUIManager:DestroyGUIScript(scriptInstance)

    // Only uninitialize it if the manager has a reference to it.
    local success = false
    if table.removevalue(self.scripts, scriptInstance) then
    
        scriptInstance:Uninitialize()
        success = true
        
    end
    
    return success

end

// Destroy a previously created single named script.
// Nothing will happen if it hasn't been created yet.
function GUIManager:DestroyGUIScriptSingle(scriptName)

    local success = false
    for index, script in ipairs(self.scriptsSingle) do
    
        if script[2] == scriptName then
        
            if table.removevalue(self.scriptsSingle, script) then
            
                script[1]:Uninitialize()
                success = true
                break
                
            end
            
        end
        
    end
    
    return success
    
end

function GUIManager:GetGUIScriptSingle(scriptName)

    for index, script in ipairs(self.scriptsSingle) do
    
        if script[2] == scriptName then
            return script[1]
        end
        
    end
    
    return nil

end

function GUIManager:NotifyGUIItemDestroyed(destroyedItem)

    if gDebugGUI then

        for index, script in ipairs(self.scripts) do
            script:NotifyGUIItemDestroyed(destroyedItem)
        end
        
        for index, script in ipairs(self.scriptsSingle) do
            script[1]:NotifyGUIItemDestroyed(destroyedItem)
        end
    
    end

end

function GUIManager:Update(deltaTime)

    PROFILE("GUIManager:Update")
    
    if gDebugGUI then
        Client.ScreenMessage(gDebugGUIMessage)
    end
    
    // Backwards iteration in case Update() causes a script to be removed.
    for s = #self.scripts, 1, -1 do
        self.scripts[s]:Update(deltaTime)
    end
    
    for s = #self.scriptsSingle, 1, -1 do
        self.scriptsSingle[s][1]:Update(deltaTime)
    end
    
end

function GUIManager:SendKeyEvent(key, down, amount)

    if not Shared.GetIsRunningPrediction() then

        for index, script in ipairs(self.scripts) do
        
            if script:SendKeyEvent(key, down, amount) then
                return true
            end
            
        end
        
        for index, script in ipairs(self.scriptsSingle) do
        
            if script[1]:SendKeyEvent(key, down, amount) then
                return true
            end
            
        end

    end
    
    return false
    
end

function GUIManager:SendCharacterEvent(character)

    for index, script in ipairs(self.scripts) do
    
        if script:SendCharacterEvent(character) then
            return true
        end
        
    end
    
    for index, script in ipairs(self.scriptsSingle) do
    
        if script[1]:SendCharacterEvent(character) then
            return true
        end
        
    end
    
    return false
    
end

function GUIManager:OnResolutionChanged(oldX, oldY, newX, newY)

    for index, script in ipairs(self.scripts) do
        script:OnResolutionChanged(oldX, oldY, newX, newY)
    end
    
    for index, script in ipairs(self.scriptsSingle) do
        script[1]:OnResolutionChanged(oldX, oldY, newX, newY)
    end

end

function GUIManager:CreateGraphicItem()
    return GUI.CreateItem()
end

function GUIManager:CreateTextItem()

    local item = GUI.CreateItem()

    // Text items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item

end 

function GUIManager:CreateLinesItem()

    local item = GUI.CreateItem()

    // Lines items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item
    
end

local function OnUpdateGUIManager(deltaTime)

    if gGUIManager then
        gGUIManager:Update(deltaTime)
    end
    
end

local function OnResolutionChanged(oldX, oldY, newX, newY)
    GetGUIManager():OnResolutionChanged(oldX, oldY, newX, newY)
end

// check required because of material scripts
if Event then
Event.Hook("UpdateClient",              OnUpdateGUIManager)
Event.Hook("ResolutionChanged", OnResolutionChanged)
end

gGUIManager = gGUIManager or CreateManager()