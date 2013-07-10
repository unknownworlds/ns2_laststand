// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\LSBuildSentry.lua
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'LSBuildSentry' (Weapon)

LSBuildSentry.kMapName = "buildsentry"

local kDropModelName = PrecacheAsset("models/marine/sentry/sentry.model")
local kHeldModelName = PrecacheAsset("models/marine/sentry/sentry.model")

local kViewModelName = PrecacheAsset("models/marine/mine/mine_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/mine/mine_view.animation_graph")

local kPlacementDistance = 2

local networkVars =
{
    droppingSentry = "boolean"
}

function LSBuildSentry:OnCreate()

    Weapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    
    self.droppingSentry = false
    
end

function LSBuildSentry:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(kHeldModelName)
    
end

function LSBuildSentry:GetIsValidRecipient(recipient)

    if self:GetParent() == nil and recipient and not GetIsVortexed(recipient) and recipient:isa("Marine") then
    
        local buildSentry = recipient:GetWeapon(LSBuildSentry.kMapName)
        return buildSentry == nil
        
    end
    
    return false
    
end

function LSBuildSentry:GetDropStructureId()
    return kTechId.Sentry
end

function LSBuildSentry:GetViewModelName()
    return nil
end

function LSBuildSentry:GetAnimationGraphName()
    return kAnimationGraph
end

function LSBuildSentry:GetSuffixName()
    return "sentry"
end

function LSBuildSentry:GetDropClassName()
    return "Sentry"
end

function LSBuildSentry:GetDropMapName()
    return Sentry.kMapName
end

function LSBuildSentry:GetHUDSlot()
    return 4
end

function LSBuildSentry:Build()

    local player = self:GetParent()
    if player then
    
        self:PerformPrimaryAttack(player)

        self:OnHolster(player)
        player:RemoveWeapon(self)
        player:SwitchWeapon(1)
            
        if Server then                
            DestroyEntity(self)
        end

    end
    
    self.droppingSentry = false
    
end

function LSBuildSentry:OnTag(tagName)
    
    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "mine" then
        self:Build()        
    end
    
end

function LSBuildSentry:OnPrimaryAttackEnd(player)
    self.droppingSentry = false
end

function LSBuildSentry:GetIsDroppable()
    return true
end

function LSBuildSentry:OnPrimaryAttack(player)

    // Ensure the current location is valid for placement.
    if not player:GetPrimaryAttackLastFrame() then
    
        local showGhost, coords, valid = self:GetPositionForStructure(player)
        if valid then
            self.droppingSentry = true
            self:Build()
        else
            self.droppingSentry = false
            
            if Client then
                player:TriggerInvalidSound()
            end
            
        end
        
    end
    
end

local function DropStructure(self, player)

    if Server then
    
        local showGhost, coords, valid = self:GetPositionForStructure(player)
        if valid then
        
            // Create mine.
            local mine = CreateEntity(self:GetDropMapName(), coords.origin, player:GetTeamNumber())
            if mine then
            
                mine:SetOwner(player)
                
                // Check for space
                if mine:SpaceClearForEntity(coords.origin) then
                
                    local angles = Angles()
                    angles:BuildFromCoords(coords)
                    mine:SetAngles(angles)
                    
                    player:TriggerEffects("create_" .. self:GetSuffixName())
                    
                    // Jackpot.
                    return true
                    
                else
                
                    player:TriggerInvalidSound()
                    DestroyEntity(mine)
                    
                end
                
            else
                player:TriggerInvalidSound()
            end
            
        else
        
            if not valid then
                player:TriggerInvalidSound()
            end
            
        end
        
    elseif Client then
        return true
    end
    
    return false
    
end

function LSBuildSentry:PerformPrimaryAttack(player)

    local success = true
        
    player:TriggerEffects("start_create_" .. self:GetSuffixName())
    
    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    success = DropStructure(self, player)
    
    if success then
    end
            
    return success
    
end

function LSBuildSentry:OnHolster(player, previousWeaponMapName)

    Weapon.OnHolster(self, player, previousWeaponMapName)
    
    self.droppingSentry = false
    
end

function LSBuildSentry:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
    self.droppingSentry = false
    
    self:SetModel(kHeldModelName)
    
end

function LSBuildSentry:Dropped(prevOwner)

    self.doNotDynamicServer = true
    Weapon.Dropped(self, prevOwner)
    
    self:SetModel(kDropModelName)
    
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function LSBuildSentry:GetPositionForStructure(player)

    local isPositionValid = false
    local foundPositionInRange = false
    local structPosition = nil
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
    
    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
        trace = Shared.TraceRay(origin, origin - Vector(0, kPlacementDistance, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end

    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
        
        foundPositionInRange = true
    
        if trace.entity == nil then
            isPositionValid = true
        elseif not trace.entity:isa("ScriptActor") and not trace.entity:isa("Clog") then
            isPositionValid = true
        end
        
        displayOrigin = trace.endPoint
        
        // Can not be built on infestation
        if GetIsPointOnInfestation(displayOrigin) then
            isPositionValid = false
        end
    
        // Don't allow dropped structures to go too close to techpoints and resource nozzles
        if GetPointBlocksAttachEntities(displayOrigin) then
            isPositionValid = false
        end
    
        // Don't allow placing above or below us and don't draw either
        local structureFacing = player:GetViewAngles():GetCoords().zAxis
    
        if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
            structureFacing = trace.normal:GetPerpendicular()
        end
    
        // Coords.GetLookIn will prioritize the direction when constructing the coords,
        // so make sure the facing direction is perpendicular to the normal so we get
        // the correct y-axis.
        local perp = Math.CrossProduct(trace.normal, structureFacing)
        structureFacing = Math.CrossProduct(perp, trace.normal)
    
        structPosition = Coords.GetLookIn(displayOrigin, structureFacing, trace.normal)
        
    end
    
    return foundPositionInRange, structPosition, isPositionValid
    
end

function LSBuildSentry:GetGhostModelName()
    return LookupTechData(self:GetDropStructureId(), kTechDataModel)
end

function LSBuildSentry:OnUpdateAnimationInput(modelMixin)
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.droppingSentry, "primary", "none"))
    
end

if Client then

    function LSBuildSentry:OnProcessIntermediate(input)
    
        local player = self:GetParent()
        
        if player then
        
            self.showGhost, self.ghostCoords, self.placementValid = self:GetPositionForStructure(player)
            
        end
        
    end
    
    function LSBuildSentry:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/GUIMineDisplay.lua" }
    end
    
end

function LSBuildSentry:GetShowGhostModel()
    return self.showGhost
end

function LSBuildSentry:GetGhostModelCoords()
    return self.ghostCoords
end   

function LSBuildSentry:GetIsPlacementValid()
    return self.placementValid
end

Shared.LinkClassToMap("LSBuildSentry", LSBuildSentry.kMapName, networkVars)
