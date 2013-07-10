//
// Console commands for ScenarioHandler
//
Script.Load("lua/ScenarioHandler.lua")

function HandleData(data)
    ScenarioHandler.instance:Load(data)
end

function OnCommandScenSave(client)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        ScenarioHandler.instance:Save()
    end
end

function OnCommandScenLoad(client, name, url)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
    
        ScenarioHandler.instance:LoadScenario(name,url)
        
    end
    
end

function OnCommandScenCheckpoint(client)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        Shared.Message("Checkpoint scenario")
        ScenarioHandler.instance:Checkpoint()
    end
end


Event.Hook("Console_scensave",      OnCommandScenSave)
Event.Hook("Console_scenload",      OnCommandScenLoad)
Event.Hook("Console_scencp",        OnCommandScenCheckpoint)
