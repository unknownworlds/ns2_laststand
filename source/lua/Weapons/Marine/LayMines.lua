// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\LayMines.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'LayMines' (Weapon)

LayMines.kMapName = "mine"

local kDropModelName = PrecacheAsset("models/marine/mine/mine_pile.model")
local kHeldModelName = PrecacheAsset("models/marine/mine/mine_3p.model")

local kViewModelName = PrecacheAsset("models/marine/mine/mine_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/mine/mine_view.animation_graph")

local kPlacementDistance = 2

local networkVars =
{
    minesLeft = string.format("integer (0 to %d)", kNumMines),
    droppingMine = "boolean"
}

function LayMines:OnCreate()

    Weapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    
    self.minesLeft = kNumMines
    self.droppingMine = false
    
end

function LayMines:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(kHeldModelName)
    
end

function LayMines:GetIsValidRecipient(recipient)

    if self:GetParent() == nil and recipient and not GetIsVortexed(recipient) and recipient:isa("Marine") then
    
        local laymines = recipient:GetWeapon(LayMines.kMapName)
        return laymines == nil
        
    end
    
    return false
    
end

function LayMines:GetDropStructureId()
    return kTechId.Mine
end

function LayMines:GetMinesLeft()
    return self.minesLeft
end

function LayMines:GetViewModelName()
    return kViewModelName
end

function LayMines:GetAnimationGraphName()
    return kAnimationGraph
end

function LayMines:GetSuffixName()
    return "mine"
end

function LayMines:GetDropClassName()
    return "Mine"
end

function LayMines:GetDropMapName()
    return Mine.kMapName
end

function LayMines:GetHUDSlot()
    return 4
end

function LayMines:OnTag(tagName)

    PROFILE("LayMines:OnTag")
    
    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "mine" then
    
        local player = self:GetParent()
        if player then
        
            self:PerformPrimaryAttack(player)
            
            if self.minesLeft == 0 then
            
                self:OnHolster(player)
                player:RemoveWeapon(self)
                player:SwitchWeapon(1)
                
                if Server then                
                    DestroyEntity(self)
                end
                
            end
            
        end
        
        self.droppingMine = false
        
    end
    
end

function LayMines:OnPrimaryAttackEnd(player)
    self.droppingMine = false
end

function LayMines:GetIsDroppable()
    return true
end

function LayMines:OnPrimaryAttack(player)

    // Ensure the current location is valid for placement.
    if not player:GetPrimaryAttackLastFrame() then
    
        local showGhost, coords, valid = self:GetPositionForStructure(player)
        if valid then
        
            if self.minesLeft > 0 then
                self.droppingMine = true
            else
            
                self.droppingMine = false
                
                if Client then
                    player:TriggerInvalidSound()
                end
                
            end
            
        else
        
            self.droppingMine = false
            
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

function LayMines:Refill(amount)
    self.minesLeft = amount
end

function LayMines:PerformPrimaryAttack(player)

    local success = true
    
    if self.minesLeft > 0 then
    
        player:TriggerEffects("start_create_" .. self:GetSuffixName())
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        
        success = DropStructure(self, player)
        
        if success then
            self.minesLeft = Clamp(self.minesLeft - 1, 0, kNumMines)
        end
        
    end
    
    return success
    
end

function LayMines:OnHolster(player, previousWeaponMapName)

    Weapon.OnHolster(self, player, previousWeaponMapName)
    
    self.droppingMine = false
    
end

function LayMines:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
    self.droppingMine = false
    
    self:SetModel(kHeldModelName)
    
end

function LayMines:Dropped(prevOwner)

    Weapon.Dropped(self, prevOwner)
    
    self:SetModel(kDropModelName)
    
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function LayMines:GetPositionForStructure(player)

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

function LayMines:GetGhostModelName()
    return LookupTechData(self:GetDropStructureId(), kTechDataModel)
end

function LayMines:OnUpdateAnimationInput(modelMixin)

    PROFILE("LayMines:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.droppingMine, "primary", "none"))
    
end

if Client then

    function LayMines:OnProcessIntermediate(input)
    
        local player = self:GetParent()
        
        if player then
        
            self.showGhost, self.ghostCoords, self.placementValid = self:GetPositionForStructure(player)
            self.showGhost = self.showGhost and self.minesLeft > 0
            
        end
        
    end
    
    function LayMines:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/GUIMineDisplay.lua" }
    end
    
end

function LayMines:GetShowGhostModel()
    return self.showGhost
end

function LayMines:GetGhostModelCoords()
    return self.ghostCoords
end   

function LayMines:GetIsPlacementValid()
    return self.placementValid
end

Shared.LinkClassToMap("LayMines", LayMines.kMapName, networkVars)
