// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\ClientResources.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Creates and evaluates validity of resources used for the local player entity.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

ClientResources = { }

local resources = { }

function ClientResources.AddResource(name, playerType, createFunc, destroyFunc)

    assert(not resources[name], "Error: Resource already added")
    resources[name] = { playerType = playerType, createFunc = createFunc, destroyFunc = destroyFunc, instance = nil }
    
end

function ClientResources.GetResource(name)
    return resources[name].instance
end

local function RemoveResources(forPlayer)

    for name, resource in pairs(resources) do
    
        if resource.instance and not forPlayer:isa(resource.playerType) then
        
            resource.destroyFunc(resource.instance)
            resource.instance = nil
            
        end
        
    end
    
end

local function AddResources(forPlayer)

    for name, resource in pairs(resources) do
    
        if not resource.instance and forPlayer:isa(resource.playerType) then
            resource.instance = resource.createFunc(forPlayer)
        end
        
    end
    
end

function ClientResources.EvaluateResourceVisibility(forPlayer)

    RemoveResources(forPlayer)
    AddResources(forPlayer)
    
end

local function PrintResources()

    for name, resource in pairs(resources) do
    
        if resource.instance then
            Shared.Message(name)
        end
        
    end
    
end
Event.Hook("Console_print_client_resources", PrintResources)