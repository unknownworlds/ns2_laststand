// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NanoShieldMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

NanoShieldMixin = CreateMixin( NanoShieldMixin )
NanoShieldMixin.type = "NanoShieldAble"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/nanoshield.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/nanoshield_view.surface_shader")

local kNanoLoopSound = PrecacheAsset("sound/NS2.fev/marine/commander/nano_loop")
local kNanoDamageSound = PrecacheAsset("sound/NS2.fev/marine/commander/nano_damage")

// These are functions that override existing same-named functions instead
// of the default case of combining with them.
NanoShieldMixin.overrideFunctions =
{
    "ComputeDamageOverride"
}

NanoShieldMixin.expectedMixins =
{
    Live = "NanoShieldMixin makes only sense if this entity can take damage (has LiveMixin).",
}

NanoShieldMixin.optionalCallbacks =
{
    GetCanBeNanoShieldedOverride = "Return true or false if the entity has some specific conditions under which nano shield is allowed.",
    GetNanoShieldOffset = "Return a vector defining an offset for the nano shield effect"
}

NanoShieldMixin.networkVars =
{
    nanoShielded = "boolean"
}

function NanoShieldMixin:__initmixin()

    if Server then
    
        self.timeNanoShieldInit = 0
        self.nanoShielded = false
        
    end
    
end

local function ClearNanoShield(self, destroySound)

    self.nanoShielded = false
    self.timeNanoShieldInit = 0    
    
    if Client then
        self:_RemoveEffect()
    end
    
    if Server and self.shieldLoopSound and destroySound then
        DestroyEntity(self.shieldLoopSound)
    end
    
    self.shieldLoopSound = nil
    
end

function NanoShieldMixin:OnDestroy()

    if self:GetIsNanoShielded() then
        ClearNanoShield(self, false)
    end
    
end

function NanoShieldMixin:OnTakeDamage(damage, attacker, doer, point)

    if self:GetIsNanoShielded() then
        StartSoundEffectAtOrigin(kNanoDamageSound, self:GetOrigin())
    end
    
end

function NanoShieldMixin:ActivateNanoShield()

    if self:GetCanBeNanoShielded() then
    
        self.timeNanoShieldInit = Shared.GetTime()
        self.nanoShielded = true
        
        if Server then
        
            assert(self.shieldLoopSound == nil)
            self.shieldLoopSound = Server.CreateEntity(SoundEffect.kMapName)
            self.shieldLoopSound:SetAsset(kNanoLoopSound)
            self.shieldLoopSound:SetParent(self)
            self.shieldLoopSound:Start()
            
        end
        
    end
    
end

function NanoShieldMixin:GetIsNanoShielded()
    return self.nanoShielded
end

function NanoShieldMixin:GetCanBeNanoShielded()

    local resultTable = { shieldedAllowed = not self.nanoShielded }
    
    if self.GetCanBeNanoShieldedOverride then
        self:GetCanBeNanoShieldedOverride(resultTable)
    end
    
    return resultTable.shieldedAllowed
    
end

local function UpdateClientNanoShieldEffects(self)

    assert(Client)
    
    if self:GetIsNanoShielded() and self:GetIsAlive() then
        self:_CreateEffect()
    else
        self:_RemoveEffect() 
    end
    
end

local function SharedUpdate(self)

    if Server then
    
        if not self:GetIsNanoShielded() then
            return
        end
        
        // See if nano shield time is over
        if self.timeNanoShieldInit + kNanoShieldDuration < Shared.GetTime() then
            ClearNanoShield(self, true)
        end
       
    elseif Client and not Shared.GetIsRunningPrediction() then
        UpdateClientNanoShieldEffects(self)
    end
    
end

function NanoShieldMixin:ComputeDamageOverrideMixin(attacker, damage, damageType, time)

    if self.nanoShielded == true then
        return damage * kNanoShieldDamageReductionDamage, damageType
    end
    
    return damage
    
end

function NanoShieldMixin:OnUpdate(deltaTime)   
    SharedUpdate(self)
end

function NanoShieldMixin:OnProcessMove(input)   
    SharedUpdate(self)
end

if Client then

    /** Adds the material effect to the entity and all child entities (hat have a Model mixin) */
    local function AddEffect(entity, material, viewMaterial, entities)
    
        local numChildren = entity:GetNumChildren()
        
        if HasMixin(entity, "Model") then
            local model = entity._renderModel
            if model ~= nil then
                if model:GetZone() == RenderScene.Zone_ViewModel then
                    model:AddMaterial(viewMaterial)
                else
                    model:AddMaterial(material)
                end
                table.insert(entities, entity:GetId())
            end
        end
        
        for i = 1, entity:GetNumChildren() do
            local child = entity:GetChildAtIndex(i - 1)
            AddEffect(child, material, viewMaterial, entities)
        end
    
    end
    
    local function RemoveEffect(entities, material, viewMaterial)
    
        for i =1, #entities do
            local entity = Shared.GetEntity( entities[i] )
            if entity ~= nil and HasMixin(entity, "Model") then
                local model = entity._renderModel
                if model ~= nil then
                    if model:GetZone() == RenderScene.Zone_ViewModel then
                        model:RemoveMaterial(viewMaterial)
                    else
                        model:RemoveMaterial(material)
                    end
                end                    
            end
        end
        
    end

    function NanoShieldMixin:_CreateEffect()
   
        if not self.nanoShieldMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/nanoshield.material")

            local viewMaterial = Client.CreateRenderMaterial()
            viewMaterial:SetMaterial("cinematics/vfx_materials/nanoshield_view.material")
            
            self.nanoShieldEntities = {}
            self.nanoShieldMaterial = material
            self.nanoShieldViewMaterial = viewMaterial
            AddEffect(self, material, viewMaterial, self.nanoShieldEntities)
            
        end    
        
    end

    function NanoShieldMixin:_RemoveEffect()

        if self.nanoShieldMaterial then
            RemoveEffect(self.nanoShieldEntities, self.nanoShieldMaterial, self.nanoShieldViewMaterial)
            Client.DestroyRenderMaterial(self.nanoShieldMaterial)
            Client.DestroyRenderMaterial(self.nanoShieldViewMaterial)
            self.nanoShieldMaterial = nil
            self.nanoShieldViewMaterial = nil
            self.nanoShieldEntities = nil
        end            

    end
    
end