Debug = { }

local Search
local SearchTable
local SearchUserdata
local SearchFunction

local function Describe(v)

    if type(v) == "function" then
        local name = debug.getinfo(v, "n").name
        if name then
            return "function " .. name
        end
    elseif type(v) == "userdata" then
        return tostring(v) .. " (" .. debug.typename(v) .. ")"
    end

    return tostring(v)
end

function TestValue(v, path, className)

    if not debug.isvalid(v) then
        local typeName = debug.typename(v)
        // Remove the "unregistered " part from the type name.
        typeName = typeName:sub(14)
        if classisa(typeName, className) then
            Shared.Message(path .. " > " .. Describe(v))
        end
        // Always return true so that we don't try to process.
        return true
    elseif type(v) == className then
        Shared.Message(path .. " > " .. Describe(v))
        return true
    elseif type(v) == "userdata" then
        local mt = getmetatable(v)
        if mt and mt.__index and v.isa and v:isa(className) then
            Shared.Message(path .. " > " ..  Describe(v))
            return true
        end
    end        
    
    return false
    
end

function SearchUserdata(u, path, className, visited)

    local mt = getmetatable(u)
    if mt and mt.__towatch then
        local name, t = mt.__towatch(u)
        if t then
            SearchTable(t, path, className, visited)
        end
    end

end

function SearchFunction(f, path, className, visited)
    
    local up = 1
    while true do
        local k, v = debug.getupvalue(f, up)
        if k == nil then
            break
        end
        Search(k, path .. " > upval name " ..  Describe(k), className, visited)
        Search(v, path .. " > upval " ..  Describe(k), className, visited)
        up = up + 1
    end

end

function SearchTable(t, path, className, visited)
    for k,v in pairs(t) do
        Search(k, path .. " > key " ..  Describe(k), className, visited)
        Search(v, path .. " > " ..  Describe(k), className, visited)
    end
end

function Search(v, path, className, visited)

    if v == nil or visited[v] then
        return
    end

    visited[v] = true

    if not TestValue(v, path, className) then
        if type(v) == "table" then
            SearchTable(v, path, className, visited)
        elseif type(v) == "function" then
            SearchFunction(v, path, className, visited)
        elseif type(v) == "userdata" then
            SearchUserdata(v, path, className, visited)
        end
    end        
    
    local env = debug.getfenv(v)
    Search(env, path .. " > fenv(" ..  Describe(v) .. ")", className, visited)
    
    local mt = getmetatable(v)
    Search(mt, path .. " > mt(" ..  Describe(v) .. ")", className, visited)
    
end

function Debug.FindTypeReferences(className)
    
    local visited = { }

    // Search the registry.
    Search(debug.getregistry(), "Registry", className, visited )
    
    // Search the global table.
    Search(_G, "_G", className, visited )
    
end