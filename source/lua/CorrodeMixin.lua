// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CorrodeMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com) and
//                  Andreas Urwalek (andi@unknownworlds.com)   
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

CorrodeMixin = CreateMixin( CorrodeMixin )
CorrodeMixin.type = "Corrode"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/bilebomb.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/bilebomb_exoview.surface_shader")

CorrodeMixin.networkVars =
{
    isCorroded = "boolean"
}

local kCorrodeShaderDuration = 4

function CorrodeMixin:__initmixin()

    if Server then
        
        self.isCorroded = false
        self.timeCorrodeStarted = 0
        
    end
    
end

function CorrodeMixin:OnDestroy()
    
    if Client and self.corrodeMaterial then
        Client.DestroyRenderMaterial(self.corrodeMaterial)
        self.corrodeMaterial = nil
    end    
    
end

function CorrodeMixin:OnTakeDamage(damage, attacker, doer, point, direction)

    if Server then
    
        if doer and doer.GetDamageType and doer:GetDamageType() == kDamageType.Corrode then
            self:SetCorroded()
        end
    
    end
    
end

if Server then

    function CorrodeMixin:SetCorroded()
        self.isCorroded = true
        self.timeCorrodeStarted = Shared.GetTime()
    end
    
end

local function UpdateCorrodeMaterial(self)

    if self._renderModel then
    
        if self.isCorroded and not self.corrodeMaterial then

            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/bilebomb.material")

            local viewMaterial = Client.CreateRenderMaterial()
            if self:isa("Exo") then
                viewMaterial:SetMaterial("cinematics/vfx_materials/bilebomb_exoview.material")
            else
                viewMaterial:SetMaterial("cinematics/vfx_materials/bilebomb.material")
            end
            
            self.corrodeEntities = {}
            self.corrodeMaterial = material
            self.corrodeMaterialViewMaterial = viewMaterial
            AddMaterialEffect(self, material, viewMaterial, self.corrodeEntities)
        
        elseif not self.isCorroded and self.corrodeMaterial then

            RemoveMaterialEffect(self.corrodeEntities, self.corrodeMaterial, self.corrodeMaterialViewMaterial)
            Client.DestroyRenderMaterial(self.corrodeMaterial)
            Client.DestroyRenderMaterial(self.corrodeMaterialViewMaterial)
            self.corrodeMaterial = nil
            self.corrodeMaterialViewMaterial = nil
            self.corrodeEntities = nil
            
        end
        
    end
    
end

local function CheckTunnelCorrode(self)

    if (not self.timeLastTunnelCorrodeCheck or self.timeLastTunnelCorrodeCheck + 1 < Shared.GetTime() ) and GetIsPointInGorgeTunnel(self:GetOrigin()) then
        
        // drain armor only
        self:DeductHealth(kGorgeArmorTunnelDamagePerSecond, nil, nil, false, true)
        
        self.isCorroded = true
        self.timeCorrodeStarted = Shared.GetTime()
        self.timeLastTunnelCorrodeCheck = Shared.GetTime()

    end

end

local function SharedUpdate(self, deltaTime)
    
    if Server then
    
        if self.isCorroded and self.timeCorrodeStarted + kCorrodeShaderDuration < Shared.GetTime() then        
            self.isCorroded = false   
        end
        
        if not GetIsVortexed(self) then
            CheckTunnelCorrode(self)
        end
        
    elseif Client then
        UpdateCorrodeMaterial(self)
    end
    
end


function CorrodeMixin:OnUpdate(deltaTime)   
    SharedUpdate(self, deltaTime)
end

function CorrodeMixin:OnProcessMove(input)   
    SharedUpdate(self, input.time)
end

if Server then

    function OnCommandCorrode(client)

        if Shared.GetCheatsEnabled() then
            
            local player = client:GetControllingPlayer()
            if player.SetCorroded then
                player:SetCorroded()
            end
            
        end

    end

    Event.Hook("Console_corrode",                 OnCommandCorrode)

end