// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\EventTester.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// EventTester is a tool to help ensure gameplay events are triggered during play testing.
// Gameplay code is scanned during load for function calls to "TEST_EVENT()".
// These event names are sent to Clients when event testing is enabled and displayed
// as a list. As these functions are called, the event name is "checked off" the list.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local testEvents = { }
local eventTestingEnabled = false

local kEventTestingEnabled =
{
    enabled = "boolean"
}
Shared.RegisterNetworkMessage("EventTestingEnabled", kEventTestingEnabled)

local kMaxEventNameLength = 128
local kEventTested =
{
    name = "string (" .. kMaxEventNameLength .. ")",
    timesTested = "integer"
}
Shared.RegisterNetworkMessage("EventTested", kEventTested)

if Server then

    local function SyncEventTestingEnabled(client, enabled)
    
        if client then
            Server.SendNetworkMessage(client, "EventTestingEnabled", { enabled = enabled }, true)
        else
            Server.SendNetworkMessage("EventTestingEnabled", { enabled = enabled }, true)
        end
        
    end
    
    local function SyncEventTested(client, eventName, timesTested)
    
        if client then
            Server.SendNetworkMessage(client, "EventTested", { name = eventName, timesTested = timesTested }, true)
        else
            Server.SendNetworkMessage("EventTested", { name = eventName, timesTested = timesTested }, true)
        end
        
    end
    
    local function SyncEventTestingState(client)
    
        SyncEventTestingEnabled(client, eventTestingEnabled)
        
        if eventTestingEnabled then
        
            for name, timesTested in pairs(testEvents) do
                SyncEventTested(client, name, timesTested)
            end
            
        end
        
    end
    
    function SetEventTestingEnabled(setEnabled)
    
        if eventTestingEnabled ~= setEnabled then
        
            eventTestingEnabled = setEnabled
            SyncEventTestingState()
            
        end
        
    end
    
    local function SharedTestEvent(eventName)
    
        if eventTestingEnabled then
        
            testEvents[eventName] = (testEvents[eventName] and testEvents[eventName] + 1) or 1
            SyncEventTested(nil, eventName, testEvents[eventName])
            
        end
        
    end
    
    function TEST_EVENT(eventName)
        SharedTestEvent(eventName)
    end
    
    local function OnEventTested(client, message)
        SharedTestEvent(message.name)
    end
    Server.HookNetworkMessage("EventTested", OnEventTested)
    
    local function OnClientConnect(client)
        SyncEventTestingState(client)
    end
    Event.Hook("ClientConnect", OnClientConnect)
    
elseif Client then

    local function SetGUIEventTesterEnabled(enabled, testEvents)
    
        local eventTester = GetGUIManager():CreateGUIScriptSingle("GUIEventTester")
        
        eventTester:SetTestEvents(testEvents)
        eventTester:SetIsVisible(enabled)
        
    end
    
    local function OnEventTestingEnabled(message)
    
        if eventTestingEnabled ~= message.enabled then
        
            eventTestingEnabled = message.enabled
            SetGUIEventTesterEnabled(eventTestingEnabled, testEvents)
            
        end
        
    end
    Client.HookNetworkMessage("EventTestingEnabled", OnEventTestingEnabled)
    
    local function OnEventTested(message)
    
        testEvents[message.name] = message.timesTested
        
        local eventTester = GetGUIManager():CreateGUIScriptSingle("GUIEventTester")
        eventTester:SetTestEvents(testEvents)
        
    end
    Client.HookNetworkMessage("EventTested", OnEventTested)
    
    function TEST_EVENT(eventName)
    
        // The Client doesn't send the number of times tested.
        if eventTestingEnabled then
            Client.SendNetworkMessage("EventTested", { name = eventName, timesTested = 0 }, true)
        end
        
    end
    
    local function SetUIOpacity(opacity)
        GetGUIManager():CreateGUIScriptSingle("GUIEventTester"):SetOpacity(tonumber(opacity))
    end
    Event.Hook("Console_test_events_opacity", SetUIOpacity)
    
elseif Predict then

    /**
     * Do nothing while predicting.
     */
    function TEST_EVENT(eventName)
    end
    
end

function GetEventTestingEnabled()
    return eventTestingEnabled
end

local function OnScriptLoaded(fileName)

    local file = io.open("game://" .. fileName, "r")
    if file then
    
        local fileStr = file:read("*all")
        io.close(file)
        
        for eventName in string.gmatch(fileStr, "TEST_EVENT%(\".-\"%)") do
        
            local cleanEventName = string.match(eventName, "\".-\"")
            cleanEventName = string.gsub(cleanEventName, "\"", "")
            if string.len(cleanEventName) > kMaxEventNameLength then
                Shared.Message(cleanEventName " is too long. " .. kMaxEventNameLength .. " is the max length.")
            else
                testEvents[cleanEventName] = 0
            end
            
        end
        
    end
    
end

local scriptLoad = Script.Load
function Script.Load(fileName)

    scriptLoad(fileName)
    
    OnScriptLoaded(fileName)
    
end