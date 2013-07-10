//=============================================================================
//
// lua/Weapons/ViewModel.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

/**
 * ViewModel is the class which handles rendering and animating the view model
 * (i.e. weapon model) for a player. To use this class, create a 'view_model'
 * entity and set its parent to the player that it will belong to. There should
 * be one view model entity per player (the same view model entity is used for
 * all of the weapons).
 */
Script.Load("lua/Globals.lua")
Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/ModelMixin.lua")

class 'ViewModel' (Entity)

ViewModel.mapName = "view_model"

local networkVars =
{
    weaponId = "entityid"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function ViewModel:OnCreate()
    
    Entity.OnCreate(self)
    
    local constants = (Client and {kRenderZone = RenderScene.Zone_ViewModel}) or {}

    InitMixin(self, BaseModelMixin, constants)
    InitMixin(self, ModelMixin)
    
    self.weaponId = Entity.invalidId
    
    // Use a custom propagation callback to only propagate to the owning player.
    self:SetPropagate(Entity.Propagate_Callback)
    
    self:SetUpdates(true)

end

function ViewModel:SetWeapon(weapon)

    if weapon ~= nil then
        self.weaponId = weapon:GetId()
    else
        self.weaponId = Entity.invalidId
    end
    
end
AddFunctionContract(ViewModel.SetWeapon, { Arguments = { "ViewModel", { "Weapon", "nil" } }, Returns = { } })

function ViewModel:OnGetIsRelevant(player)
    
    // Only propagate the view model if it belongs to the player (since they're
    // the only one that can see it)
    return self:GetParent() == player
    
end

function ViewModel:GetCameraCoords()

    if self:GetNumModelCameras() > 0 then
    
        local camera = self:GetModelCamera(0)
        return true, camera:GetCoords()
        
    end

    return false, nil
    
end

// Pass along to weapon so melee attacks can be triggered at exact time of impact.
function ViewModel:OnTag(tagHit)

    PROFILE("ViewModel:OnTag")

    local weapon = self:GetWeapon()
    if weapon ~= nil and weapon.OnTag then
        weapon:OnTag(tagHit)
    end

end

if Client then

    // Override camera coords with custom camera animation
    function ViewModel:OnAdjustModelCoords(coords)
    
        PROFILE("ViewModel:OnAdjustModelCoords")
        
        local overrideCoords = Coords.GetIdentity()
        local standardAspect = 1900 / 1200 // Aspect ratio the view models are designed for.
        
        if self:GetNumModelCameras() > 0 then

            local camera = self:GetModelCamera(0)
            
            if self:GetParent() == Client.GetLocalPlayer() then
                Client.SetZoneFov( RenderScene.Zone_ViewModel, GetScreenAdjustedFov(camera:GetFov(), standardAspect) )
            end

            overrideCoords = camera:GetCoords():GetInverse()
            
        else
        
            if self:GetParent() == Client.GetLocalPlayer() then
                Client.SetZoneFov( RenderScene.Zone_ViewModel, GetScreenAdjustedFov(math.rad(65), standardAspect) )
            end
            
        end
        
        return overrideCoords
        
    end
    
    function ViewModel:OnUpdateRender()
    
        PROFILE("ViewModel:OnUpdateRender")
        
        // Hide view model when in third person.
        // Only show local player model and active weapon for local player when third person
        // or for other players (not ethereal Fades).
        self:SetIsVisible(self:GetIsVisible() and not self:GetParent():GetDrawWorld())
        
    end
    
end

function ViewModel:GetEffectParams(tableParams)
    
    tableParams[kEffectFilterClassName] = self:GetClassName()
    
    // Override classname with class of weapon we represent
    local weapon = self:GetWeapon()
    if weapon ~= nil then
        tableParams[kEffectFilterClassName] = weapon:GetClassName()
        weapon:GetEffectParams(tableParams)
    end
    
end

function ViewModel:GetWeapon()
    return Shared.GetEntity(self.weaponId)
end

function ViewModel:OnUpdateAnimationInput(modelMixin)

    PROFILE("ViewModel:OnUpdateAnimationInput")
    
    local parent = self:GetParent()
    assert(parent ~= nil)
    parent:OnUpdateAnimationInput(modelMixin)
    
end

Shared.LinkClassToMap("ViewModel", ViewModel.mapName, networkVars)