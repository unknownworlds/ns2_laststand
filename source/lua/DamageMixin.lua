// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\DamageMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)  
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

DamageMixin = CreateMixin(DamageMixin)
DamageMixin.type = "Damage"

// LS
gMarineToAlienDamageScale = 1.0

if Server then

    Event.Hook("Console_ls_damage", function(client, arg)
                local t = tonumber(arg)
                Print("TWEAK Setting marine-to-alien damage scale to %0.2fs", t)
                gMarineToAlienDamageScale = t
            end)

end

function DamageMixin:__initmixin()
end

// damage type, doer and attacker don't need to be passed. that info is going to be fetched here. pass optional surface name
// pass surface "none" for not hit/flinch effect
function DamageMixin:DoDamage(damage, target, point, direction, surface, altMode, showtracer)

    // No prediction if the Client is spectating another player.
    if Client and not Client.GetIsControllingPlayer() then
        return false
    end
    
    local killedFromDamage = false
    local doer = self

    // attacker is always a player, doer is 'self'
    local attacker = nil
    local parentVortexed = false
    
    if target and target:isa("Ragdoll") then
        return false
    end
    
    if self:isa("Player") then
        attacker = self
    else

        if self:GetParent() and self:GetParent():isa("Player") then
            attacker = self:GetParent()
            parentVortexed = GetIsVortexed(attacker)
        elseif HasMixin(self, "Owner") and self:GetOwner() and self:GetOwner():isa("Player") then
            attacker = self:GetOwner()
        end  

    end
    
    if not attacker then
        attacker = doer
    end

    if attacker then
    
        // Get damage type from source
        local damageType = kDamageType.Normal
        if self.GetDamageType then
            damageType = self:GetDamageType()
        elseif HasMixin(self, "Tech") then
            damageType = LookupTechData(self:GetTechId(), kTechDataDamageType, kDamageType.Normal)
        end
        
        local armorUsed = 0
        local healthUsed = 0
        
        if target and HasMixin(target, "Live") and damage > 0 then  

            // LS
            if HasMixin(target, "Team") then
                if doer:GetTeamNumber() == kMarineTeamType and target:GetTeamNumber() == kAlienTeamType then
                    damage = damage * gMarineToAlienDamageScale
                end
            end

            damage, armorUsed, healthUsed = GetDamageByType(target, attacker, doer, damage, damageType)

            // check once the damage
            if damage > 0 then
            
                if not direction then
                    direction = Vector(0, 0, 1)
                end
                                
                // Many types of damage events are server-only, such as grenades.
                // Send the player a message so they get feedback about what damage they've done.
                // We use messages to handle multiple-hits per frame, such as splash damage from grenades.
                if Server and attacker:isa("Player") and (not doer.GetShowHitIndicator or doer:GetShowHitIndicator()) then
                    local showNumbers = GetAreEnemies(attacker,target) and target:GetIsAlive()
                    if showNumbers then
                        local msg = BuildDamageMessage(target, damage, point)
                        Server.SendNetworkMessage(attacker, "Damage", msg, false)
                    end
                    
                    // This makes the cross hair turn red. Show it when hitting anything
                    attacker.giveDamageTime = Shared.GetTime()
                end
                
                killedFromDamage = target:TakeDamage(damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType)
                
                if self.OnDamageDone then
                    self:OnDamageDone(doer, target)
                end

                if attacker and attacker.OnDamageDone then
                    attacker:OnDamageDone(doer, target)
                end
                
            end

        end
        
        // trigger damage effects (damage, deflect) with correct surface
        if surface ~= "none" then
        
            local armorMultiplier = ConditionalValue(damageType == kDamageType.Light, 4, 2)
            armorMultiplier = ConditionalValue(damageType == kDamageType.Heavy, 1, armorMultiplier)
        
            local playArmorEffect = armorUsed * armorMultiplier > healthUsed
            
            if parentVortexed or GetIsVortexed(self) or GetIsVortexed(target) then            
                surface = "ethereal"
                
            elseif HasMixin(target, "NanoShieldAble") and target:GetIsNanoShielded() then    
                surface = "nanoshield"
                
            elseif HasMixin(target, "Fire") and target:GetIsOnFire() then
                surface = "flame"
                
            elseif not target then
            
                if GetIsPointOnInfestation(point) then
                    surface = "infestation"
                end
                
                if not surface or surface == "" then
                    surface = "metal"
                end
            
            elseif not surface or surface == "" then
            
                surface = GetIsAlienUnit(target) and "organic" or "metal"

                // define metal_thin, rock, or other
                if target.GetSurfaceOverride then
                    surface = target:GetSurfaceOverride()
                    
                elseif GetAreEnemies(self, target) then

                    if target:isa("Alien") then
                        surface = "organic"
                    elseif target:isa("Marine") then
                        surface = "flesh"
                    else
                    
                        if HasMixin(target, "Team") then
                        
                            if target:GetTeamType() == kAlienTeamType then
                                surface = "organic"
                            else
                                surface = "metal"
                            end
                            
                        end
                    
                    end

                end

            end
            
            // send to all players in range, except to attacking player, he will predict the hit effect
            if Server then
            
                if GetShouldSendHitEffect() then
                                
                    local directionVectorIndex = 1
                    if direction then
                        directionVectorIndex = GetIndexFromVector(direction)
                    end
                    
                    local message = BuildHitEffectMessage(point, doer, surface, target, showtracer, altMode, damage, directionVectorIndex)
                    
                    local toPlayers = GetEntitiesWithinRange("Player", point, kHitEffectRelevancyDistance)                    
                    for _, spectator in ientitylist(Shared.GetEntitiesWithClassname("Spectator")) do
                    
                        if table.contains(toPlayers, Server.GetOwner(spectator):GetSpectatingPlayer()) then
                            table.insertunique(toPlayers, spectator)
                        end
                        
                    end
                    
                    table.removevalue(toPlayers, attacker)
                    
                    for _, player in ipairs(toPlayers) do
                        Server.SendNetworkMessage(player, "HitEffect", message, false) 
                    end
                
                end

            elseif Client then
            
                HandleHitEffect(point, doer, surface, target, showtracer, altMode, damage, direction)
                
                // If we are far away from our target, trigger a private sound so we can hear we hit something
                if target then
                
                    if (point - attacker:GetOrigin()):GetLength() > 5 then
                        attacker:TriggerEffects("hit_effect_local", tableParams)
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return killedFromDamage
    
end
