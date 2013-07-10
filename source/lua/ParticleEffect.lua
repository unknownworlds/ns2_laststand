// ======= Copyright © 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/ParticleEffect.lua
//
//    Created by:   Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'ParticleEffect' (Entity)

local kMapName = "particleeffect"

local networkVars =
{
    assetIndex = "resource",
    predictor  = "entityid"
}

if Server then

    local function UpdateLifetime(self, deltaTime)
    
        local lifeTime = self.lifeTime - deltaTime
        if lifeTime <= 0 then
            DestroyEntity(self)
        else
            self.lifeTime = lifeTime
        end
        
    end
    
    function ParticleEffect:OnCreate()
    
        self:SetUpdates(true)
        self.predictor = Entity.invalidId
        
        self:SetPropagate(Entity.Propagate_Mask)
        self:SetRelevancyDistance(kMaxRelevancyDistance)
        
    end
    
    function ParticleEffect:OnUpdate(deltaTime)
        UpdateLifetime(self, deltaTime)
    end
    
    function ParticleEffect:OnProcessMove(input)
        UpdateLifetime(self, input.time)
    end
    
end

if Client then

    // utility function, used for effects that attach to a weapon or view model
    function CreateMuzzleCinematic(weapon, firstPersonEffectName, thirdpersonEffectName, attachPoint, attachTo, repeatStyle)
    
        local parent = weapon:GetParent()
        if parent and ( parent:GetIsVisible() or (parent:isa("Player") and parent:GetIsLocalPlayer()) ) then
        
            local effectName
            local model
            local cinematic
            local zone
        
            if parent:GetIsLocalPlayer() and not parent:GetIsThirdPerson() then
                effectName = firstPersonEffectName
                zone = RenderScene.Zone_ViewModel
                attachTo = parent:GetViewModelEntity()
            else
                effectName = thirdpersonEffectName
                zone = RenderScene.Zone_Default
                if not attachTo then
                    attachTo = weapon
                end
                
            end

            // childs may not provide a muzzle effect
            if attachPoint and effectName and attachTo then

                local cinematic = Client.CreateCinematic(zone)
                cinematic:SetCinematic(effectName)
                cinematic:SetParent(attachTo)
                cinematic:SetCoords(Coords.GetIdentity())
                cinematic:SetAttachPoint(attachTo:GetAttachPointIndex(attachPoint))
                
                if repeatStyle then
                    cinematic:SetRepeatStyle(repeatStyle)
                end
                
                return cinematic

            end
        
        end
    
    end
    
    function ParticleEffect:OnInitialized()
    
        if self.cinematic == nil then
        
            // Check if this particle was predicted on the client. If it was, then
            // we don't need to create it again
            if self.predictor ~= Entity.invalidId then
            
                local predictor = Shared.GetEntity(self.predictor)
                if Client.GetLocalPlayer() == predictor then
                    return
                end
                
            end
            
            local cinematic = Client.CreateCinematic()
            
            cinematic:SetCinematic(Shared.GetCinematicFileName(self.assetIndex))
            cinematic:SetParent(self:GetParent())
            
            // Get the coords through the angles to retrive them in child/object
            // space instead of through self:GetCoords() which is in world space.
            cinematic:SetCoords(self:GetAngles():GetCoords(self:GetOrigin()))
            
            cinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            cinematic:SetAttachPoint(self:GetAttachPoint())
            
            self.cinematic = cinematic
            
        end
        
    end
    
    function ParticleEffect:OnDestroy()
    
        Entity.OnDestroy(self)
        
        if self.cinematic ~= nil then
            Client.DestroyCinematic(self.cinematic)
        end
        
    end
    
end

if Server then

    local function CreateEffect(player, effectName, parent, coords, attachPoint)
    
        if string.len(effectName) == 0 then
            return
        end
        
        local assetIndex = Shared.GetCinematicIndex(effectName)
        if assertIndex == 0 then
        
            Shared.Message("Effect " .. effectName .. " wasn't precached")
            return
            
        end
        
        local entity = Server.CreateEntity(kMapName)
        entity.assetIndex = assetIndex
        entity:SetParent(parent)
        
        if player ~= nil then
            entity.predictor = player:GetId()
        end
        
        if coords ~= nil then
            entity:SetCoords(coords)
        end
        
        if attachPoint ~= nil then
            entity:SetAttachPoint(attachPoint)
        end
        
        entity.lifeTime = Server.GetCinematicLength(assetIndex)
        
        return entity
        
    end
    
    function Shared.CreateEffect(player, effectName, parent, coords)
        return CreateEffect(player, effectName, parent, coords)
    end
    
    function Shared.CreateAttachedEffect(player, effectName, parent, coords, attachPoint, view)
    
        // We only attach effects to the view model on the client (i.e. during prediction)
        assert(view == nil or view == false)
        return CreateEffect(player, effectName, parent, coords, attachPoint)
        
    end
    
end

if Client then

    local function CreateEffect(player, effectName, parent, coords, attachPoint, view)
    
        local zone = RenderScene.Zone_Default
        if view then
            zone = RenderScene.Zone_ViewModel
        end
        
        local cinematic = Client.CreateCinematic(zone)
        
        cinematic:SetCinematic(effectName)
        cinematic:SetParent(parent)
        
        if coords ~= nil then
            cinematic:SetCoords(coords)
        end
        
        if attachPoint ~= nil then
            cinematic:SetAttachPoint(parent:GetAttachPointIndex(attachPoint))
        end
        
    end
    
    function Shared.CreateEffect(player, effectName, parent, coords)
    
        if player == nil or not Shared.GetIsRunningPrediction() then
            CreateEffect(player, effectName, parent, coords)
        end
        
    end
    
    function Shared.CreateAttachedEffect(player, effectName, parent, coords, attachPoint, view)
    
        if player == nil or not Shared.GetIsRunningPrediction() then
            CreateEffect(player, effectName, parent, coords, attachPoint, view)
        end
        
    end
    
end

Shared.LinkClassToMap("ParticleEffect", kMapName, networkVars)