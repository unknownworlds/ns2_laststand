// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PickupableMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/EquipmentOutline.lua")

PickupableMixin = CreateMixin( PickupableMixin )
PickupableMixin.type = "Pickupable"

PickupableMixin.expectedMixins =
{
}

PickupableMixin.expectedCallbacks =
{
    OnTouch = "Called when a player is close enough for pick up with the player as the parameter",
    GetOrigin = "Returns the position of this pickupable item",
    GetIsValidRecipient = "Should return true if the passed in Entity can receive this pickup"
}

PickupableMixin.optionalCallbacks =
{
    GetIsPermanent = "Return true when this item has unlimited life time."
}

PickupableMixin.expectedConstants =
{
    kRecipientType = "The class type that is allowed to pick this up"
}

local kCheckForPickupRate = 0.1
local kPickupRange = 1

function PickupableMixin:__initmixin()

    if Server then
    
        if not self.GetCheckForRecipient or self:GetCheckForRecipient() then
            self:AddTimedCallback(PickupableMixin._CheckForPickup, kCheckForPickupRate)
        end
        
        // LS never destroy
        /*
        if not self.GetIsPermanent or not self:GetIsPermanent() then
            self:AddTimedCallback(PickupableMixin._DestroySelf, kItemStayTime)
        end
        */
        
    end
    
end

function PickupableMixin:_GetNearbyRecipient()

    local potentialRecipients = GetEntitiesWithinRange(self:GetMixinConstants().kRecipientType, self:GetOrigin(), kPickupRange)
    
    for index, recipient in pairs(potentialRecipients) do
    
        if self:GetIsValidRecipient(recipient) then
            return recipient
        end
        
    end
    
    return nil
    
end

function PickupableMixin:_CheckForPickup()

    assert(Server)
    
    // Scan for nearby friendly players that need medpacks because we don't have collision detection yet
    local player = self:_GetNearbyRecipient()

    if player ~= nil then
    
        self:OnTouch(player)
        DestroyEntity(self)
        
    end
    
    // Continue the callback.
    return true
    
end

function PickupableMixin:_DestroySelf()

    assert(Client == nil)
    
    DestroyEntity(self)

end

function PickupableMixin:OnUpdate(deltaTime)

    if Client then    
        EquipmentOutline_UpdateModel(self)    
    end

end
