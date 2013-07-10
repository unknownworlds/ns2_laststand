// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Door:OnInitialized()

    ScriptActor.OnInitialized(self)

    // Save origin, angles, etc. so we can restore on reset
    self.savedOrigin = Vector(self:GetOrigin())
    self.savedAngles = Angles(self:GetAngles())
    
end

function Door:GetCanTakeDamageOverride()
    return self:GetState() == Door.kState.Welded
end

function Door:OnTakeDamage(damage, attacker, doer, point)

    if damage > 0 then
    
        local direction = attacker:GetOrigin() - point
        direction:Normalize()
        
        if direction:DotProduct(self:GetAngles():GetCoords().zAxis) < 0 then
            self.damageBackPose = Clamp( (1-(self:GetHealth() / self:GetMaxHealth())) * 100, 0, 100)
        else
            self.damageFrontPose = Clamp( (1-(self:GetHealth() / self:GetMaxHealth())) * 100, 0, 100)
        end
        
    
    end
    
end

function Door:ComputeDamageOverride(attacker, damage, damageType, time)
    
    if self:GetState() == Door.kState.Welded and damageType == kDamageType.Door then
        return damage, damageType
    end
    
    return 0    

end

