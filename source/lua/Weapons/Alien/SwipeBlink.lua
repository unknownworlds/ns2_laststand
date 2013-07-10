// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SwipeBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Swipe/blink - Left-click to attack, right click to show ghost. When ghost is showing,
// right click again to go there. Left-click to cancel. Attacking many times in a row will create
// a cool visual "chain" of attacks, showing the more flavorful animations in sequence.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Blink.lua")

class 'SwipeBlink' (Blink)
SwipeBlink.kMapName = "swipe"

local networkVars =
{
}

// Make sure to keep damage vs. structures less then Skulk
SwipeBlink.kSwipeEnergyCost = kSwipeEnergyCost
SwipeBlink.kDamage = kSwipeDamage
SwipeBlink.kRange = 1.6

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function SwipeBlink:OnCreate()

    Blink.OnCreate(self)
    
    self.lastSwipedEntityId = Entity.invalidId
    self.primaryAttacking = false

end

function SwipeBlink:GetAnimationGraphName()
    return kAnimationGraph
end

function SwipeBlink:GetEnergyCost(player)
    return SwipeBlink.kSwipeEnergyCost
end

function SwipeBlink:GetHUDSlot()
    return 1
end

function SwipeBlink:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeBlink:GetMeleeBase()
    return 1.5, 1.2
end

function SwipeBlink:GetDeathIconIndex()
    return kDeathMessageIcon.Swipe
end

function SwipeBlink:GetSecondaryTechId()
    return kTechId.Blink
end

function SwipeBlink:GetBlinkAllowed()
    return true
end

function SwipeBlink:OnPrimaryAttack(player)

    if not self:GetIsBlinking() and player:GetEnergy() >= self:GetEnergyCost() then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function SwipeBlink:OnPrimaryAttackEnd()
    
    Blink.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:OnHolster(player)

    Blink.OnHolster(self, player)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:OnTag(tagName)

    PROFILE("SwipeBlink:OnTag")
    
    if tagName == "hit" then
    
        local player = self:GetParent()
        if player then
            player:DeductAbilityEnergy(self:GetEnergyCost())
        end
        
        self:TriggerEffects("swipe_attack")    
        self:PerformMeleeAttack()
        
    end

end

function SwipeBlink:PerformMeleeAttack()

    local player = self:GetParent()
    if player then
        local didHit, hitObject, endPoint, surface = PerformGradualMeleeAttack(self, player, SwipeBlink.kDamage, SwipeBlink.kRange, nil, false, EntityFilterOneAndIsa(player, "Babbler"))
    end
    
end

function SwipeBlink:OnUpdateAnimationInput(modelMixin)

    PROFILE("SwipeBlink:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "swipe")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("SwipeBlink", SwipeBlink.kMapName, networkVars)