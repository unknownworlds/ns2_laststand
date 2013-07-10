// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function TriggerFirstPersonTracer(weapon, endPosition)

    if weapon and weapon:GetParent() then
    
        local player = weapon:GetParent()
        local tracerStart = weapon.GetBarrelPoint and weapon:GetBarrelPoint() or weapon:GetOrigin()
        local tracerVelocity = GetNormalizedVector(endPosition - tracerStart) * kTracerSpeed
        CreateTracer(tracerStart, endPosition, tracerVelocity, weapon)
    
    end

end

function Weapon:Dropped(prevOwner)
end

function Weapon:GetPreventCameraAnimation(player)
    return not Client.GetOptionBoolean("CameraAnimation", false)
end

function Weapon:UpdateDropped()

    if self:GetPhysicsType() == PhysicsType.DynamicServer and not self.dropped then
    
        self:Dropped(nil)
        self.dropped = true
        
    elseif self:GetPhysicsType() == PhysicsType.None then
        self.dropped = false
    end
        
end

function Weapon:OnGetIsVisible(visTable)

    local localPlayer = Client.GetLocalPlayer()
    local parent = self:GetParent()
    
    if localPlayer then
    
        if parent then
        
            visTable.Visible = visTable.Visible and self == self:GetParent():GetActiveWeapon()
            visTable.Visible = visTable.Visible and parent:GetIsVisible()
            
        else
        
            if localPlayer:isa("Commander") then
                visTable.Visible = not GetAreEnemies(localPlayer, self)
            end
            
        end
        
    end
    
    // There is a little delay before a newly switched to weapon appears so we don't
    // see the attach point rotate strangely (along with the weapon).
    visTable.Visible = visTable.Visible and (self.activeSince + 0.17 < Shared.GetTime())
    
end

// Return true or false and the camera coords to use for the parent player if weapon chooses
// to override camera.
function Weapon:GetCameraCoords()
    return false, nil
end

// this function on the local client whenever the active weapon changes. use for canceling client side ghost structures or for canceling effects/sounds
function Weapon:OnHolsterClient()

    local parent = self:GetParent()
    if parent then
    
        local viewModel = parent:GetViewModelEntity()
        Client.DestroyAttachedCinematics(viewModel)
        
    end
    
    self:TriggerEffects("holster")
    
    self.activeSince = 0
    
end

function Weapon:OnDrawClient()
    self.activeSince = Shared.GetTime()
end

// child classes can override this to prevent damage indicator to be shown
function Weapon:GetShowDamageIndicator()
    return true
end

function Weapon:GetPrimaryAttacking()
    return self.primaryAttacking
end

function Weapon:GetSecondaryAttacking()
    return self.secondaryAttacking
end
