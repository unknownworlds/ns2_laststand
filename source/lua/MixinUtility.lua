// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MixinUtility.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================   

Script.Load("lua/Table.lua")

/**
 * This function is used to create a mixin table. To allow for hot loading of scripts, the
 * existing mixin table should be passed in as the mixin parameter. This allows us to reuse
 * the mixin table.
 */
function CreateMixin(mixin)
    if mixin then
        assert( type(mixin) == "table" )
        for k in pairs(mixin) do
            mixin[k] = nil
        end
        return mixin
    else
        return {}
    end
end

local function CheckExpectedMixins(classInstance, theMixin)

    if theMixin.expectedMixins then
    
        assert(type(theMixin.expectedMixins) == "table", "Expected Mixins should be a table of Mixin type names and documentation on what the Mixin is needed for.")
        for mixinType, mixinInfo in pairs(theMixin.expectedMixins) do
        
            if not HasMixin(classInstance, mixinType) then
                error("Mixin type " .. mixinType .. " was expected on " .. ToString(classInstance) .. " while initializing mixin type " .. theMixin.type .. "\nInfo: " .. mixinInfo)
            end
            
        end
        
    end

end

/**
 * Test if @mixin require @expectedType
 *
 * @return boolean
 */
local function IsExpectedMixin(mixin, expectedType)
    if mixin.expectedMixins then

        for mixinType, mixinInfo in pairs(mixin.expectedMixins) do

            if mixinType == expectedType then
                return true
            end
        end

    end

    return false
end

local function CheckExpectedCallbacks(classInstance, theMixin)

    if theMixin.expectedCallbacks then
    
        assert(type(theMixin.expectedCallbacks) == "table", "Expected callbacks should be a table of callback function names and documentation on how the function is used")
        for callbackName, callbackInfo in pairs(theMixin.expectedCallbacks) do
        
            if type(classInstance[callbackName]) ~= "function" then
                error("Callback named " .. callbackName .. " was expected for mixin type " .. theMixin.type .. "\nInfo: " .. callbackInfo)
            end
            
        end
        
    end

end

local function CheckExpectedConstants(classInstance, theMixin)

    if theMixin.expectedConstants then
    
        for constantName, constantInfo in pairs(theMixin.expectedConstants) do
        
            if classInstance.__mixindata[constantName] == nil then
                error("Constant named " .. constantName .. " expected\nInfo: " .. constantInfo)
            end
            
        end
        
    end

end

local function CheckOverride(theMixin, functionName)

    if theMixin.overrideFunctions and table.contains(theMixin.overrideFunctions, functionName) then
        return true
    end
    
    return false

end

/**
 * Check if @mixin override @methodName
 */
local function IsOverriding(mixin, methodName)

    if mixin.overrideFunctions then
        for i, name in pairs(mixin.overrideFunctions) do
            if mixin == methodName then
                return true
            end
        end
    end
    
    return false

end

gTraceTables = gTraceTables or { }
// turn tracing for mixing-methods and/or classes by specifying them as "classname","functionName" pairs
// profiling this way is disabled in release builds
// gActiveTraces = gActiveTraces or { { nil, "OnPreUpdate"} }
gActiveTraces = gActiveTraces or { }

local function IsTraced(key)
    for _,v in ipairs(gActiveTraces) do
        local className, functionName = unpack(v)
        
        if className then
            if string.find(key, className .. ':') ~= 0 then
                return false
            end
        end
        if functionName then
            local match = functionName
            local sos, eos = string.find(key, match)
            return eos == string.len(key)
        end
        return true
    end
end

local function CheckTraces(key, table)
    for k,v in pairs(gTraceTables) do
        if IsTraced(k) then
            if not v[1] then
                Log("%s traced", k)
            end
            v[1] = k .. ":All"
        else
            v[1] = nil
        end
    end     
end

function TraceMixin(functionName, className)
    Log("Trace %s:%s", className, functionName)
    table.insert(gActiveTraces, { functionName, className })
    CheckTraces()
end

local function AddFunctionToCallerList(classInstance, classFunction, addFunction, functionName, theMixin)

    local functionsTable = classInstance[functionName .. "__functions"]
    local nameTable = classInstance[functionName .. "__functionNames"]
    local className = classInstance.GetClassName and classInstance:GetClassName() or "Unknown class"
    
    if functionsTable == nil then
        
        functionsTable = { }
        nameTable = { }
        local traceTable = gTraceTables[className .. ":" .. functionName ]
        if not traceTable then
            traceTable = {  }
            gTraceTables[className .. ":" .. functionName ] = traceTable
            CheckTraces()
        end
        
        // Insert existing function.
        table.insert(functionsTable, classFunction)
        // The nameTable supports profiling of mixin-calls without having to manually add profiling to each target
        // great for finding out where all the CPU goes for some "fat" mixin-calls
        table.insert(nameTable, className .. ":" .. functionName)
       
        classInstance[functionName .. "__functions"] = functionsTable
        classInstance[functionName .. "__functionNames"] = nameTable
        classInstance[functionName .. "__functionTrace"] = traceTable
        classInstance[functionName] = Mixin.RegisterFunction(functionsTable, nameTable, traceTable)
        
    end
    
    if not table.contains(functionsTable, addFunction) then
        table.insert(functionsTable, addFunction)
        table.insert(nameTable, theMixin.type .. ":" .. functionName )
    end
    
end

/**
 * This will add the mixin network vars to the passed in network var
 * table. It will do nothing if the mixin does not have network vars.
 */
function AddMixinNetworkVars(theMixin, networkVars)

    assert(theMixin)
    assert(networkVars)
    
    if theMixin.networkVars then
    
        for varName, varType in pairs(theMixin.networkVars) do
        
            if networkVars[varName] ~= nil then
                error("Variable " .. varName .. " already exists in network vars while adding mixin " .. theMixin.type)
            end
            
            networkVars[varName] = varType
            
        end
        
    end
    
end

// InitMixin takes a class instance and adds the passed in mixin functions to it if the class instance
// doesn't yet have the mixin. If the mixin was previously added, it reinitializes the mixin for the instance.
function InitMixin(classInstance, theMixin, optionalMixinData)

    // Don't add the mixin to the class instance again.
    if not HasMixin(classInstance, theMixin) then
    
        // Add the Mixin type as a tag for the classInstance if it is an Entity.
        if Shared and Shared.AddTagToEntity and classInstance:isa("Entity") then
            Shared.AddTagToEntity(classInstance:GetId(), theMixin.type)
        end
        
        // Ensure the class has the expected Mixins.
        CheckExpectedMixins(classInstance, theMixin)
        
        // Ensure the class instance implements the expected callbacks.
        CheckExpectedCallbacks(classInstance, theMixin)
        
        for k, v in pairs(theMixin) do

            if type(v) == "function" and k ~= "__initmixin" then

                // If this function name is in the overrideFunctions table then it is
                // the only function that will be called with this name.
                local overrideAllowed = CheckOverride(theMixin, k)

                // Directly set the function for this class instance.
                // Only affects this instance.
                local classFunction = classInstance[k]

                if classFunction == nil or overrideAllowed then
                    classInstance[k] = v

                // If the function already exists then it is added to a list of functions to call.
                // The return values from the first called function in this list is returned.
                else
                    AddFunctionToCallerList(classInstance, classFunction, v, k, theMixin)
                end
                
            end
            
        end
        
        // Keep track that this mixin has been added to the class instance.
        if classInstance.__mixinlist == nil then
            classInstance.__mixinlist = { }
        end
        
        assert(classInstance.__mixinlist[theMixin.type] == nil,
               "Different Mixin with the same type name already exists in table!")
        
        classInstance.__mixinlist[theMixin.type] = true
        
        // Add the static mixin data to this class instance.
        if classInstance.__mixindata == nil then
        
            classInstance.__mixindata = { }
            function classInstance:GetMixinConstants() 
                return self.__mixindata 
            end

            function classInstance:GetMixinConstant(constantName)
                return self.__mixindata[constantName]
            end
            
        end

        if theMixin.defaultConstants then

            for k, v in pairs(theMixin.defaultConstants) do
                classInstance.__mixindata[k] = v
            end

        end
        
        if optionalMixinData then
        
            for k, v in pairs(optionalMixinData) do
                classInstance.__mixindata[k] = v
            end
            
        end
        
        // Ensure the expected constants are present.
        CheckExpectedConstants(classInstance, theMixin)
        
    end
    
    // Finally, initialize the mixin on this class instance.
    // This can be done multiple times for a class instance.
    if theMixin.__initmixin then
        theMixin.__initmixin(classInstance)
    end

end

/**
 * Returns true if the passed in class instance has a Mixin that
 * matches the passed in mixin type name.
 * Note, this type name can be shared by multiple Mixin types.
 * It is more of an implicit interface the Mixin adheres to.
 */
function HasMixin(classInstance, mixinTypeName)

	// Note: The check for a non-nil classInstance was added as a temporarily fix for Mantis report: 3003.
	if not classInstance then
		return false
	end

    local mixinlist = classInstance.__mixinlist
	return (mixinlist and mixinlist[mixinTypeName]) or false
    
end

// Returns the number of mixins the passed in class instance currently is using.
function NumberOfMixins(classInstance)

    ASSERT(type(classInstance) == "userdata", "First parameter to InitMixin() must be a class instance")
    
    if classInstance.__mixinlist then
        return table.countkeys(classInstance.__mixinlist)
    end

    return 0

end
