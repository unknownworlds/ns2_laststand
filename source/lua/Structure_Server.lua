// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure_Server.lua
//
//    Kept for reference (all classes which were structures previously need this functionality, needs to be added somewhere)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// missing on CLIENT: TODO: IdleMixin.lua, should also trigger effects and maybe shaders

// missing on SERVER

function Structure:GetCanCatalystOverride()
    return self:GetIsAlive() and self:GetIsResearching()
end

// Replace structure with new structure. Used when upgrading structures.
function Structure:Replace(className)

    local newStructure = CreateEntity(className, self:GetOrigin())
    
    // Copy over relevant fields 
    self:OnReplace(newStructure)
           
    // Now destroy old structure
    DestroyEntity(self)

    return newStructure

end

function Structure:OnInitialized()    

    ScriptActor.OnInitialized(self)

    // Log building creation
    PostGameViz(string.format("%s built", SafeClassName(self)), self)
    
end

function Structure:OnReplace(newStructure)

    // Copy over relevant fields 
    newStructure:SetTeamNumber( self:GetTeamNumber() )
    newStructure:SetAngles( self:GetAngles() )

    // Copy attachments
    newStructure:SetAttached(self.attached)

    newStructure.buildTime = self.buildTime
    newStructure.buildFraction = self.buildFraction

end


