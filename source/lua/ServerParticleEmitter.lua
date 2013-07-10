// ======= Copyright © 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/ServerParticleEmitter.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'ServerParticleEmitter' (Entity)

ServerParticleEmitter.kMapName = "serverparticleemitter"

local networkVars =
{
}

if Server then

    function ServerParticleEmitter:OnCreate()
    
        Entity.OnCreate(self)
        
        InitMixin(self, SignalListenerMixin)
        
        self:SetUpdates(false)
        self:SetPropagate(Entity.Propagate_Never)
        
    end
    
    local function EmitParticleEffect(self)
        Shared.CreateEffect(nil, self.cinematicName, nil, self:GetCoords())
    end
    
    function ServerParticleEmitter:OnInitialized()
        self:RegisterSignalListener(function() EmitParticleEffect(self) end, self.startsOnMessage)
    end
    
end

Shared.LinkClassToMap("ServerParticleEmitter", ServerParticleEmitter.kMapName, networkVars)