// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========    
//    
// lua\EquipmentOutline.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

local _renderMask = 0x4
local _invRenderMask = bit.bnot(_renderMask)
local _maxDistance = 38
local _maxDistance_Commander = 60
local _enabled = true

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/highlightmodel.surface_shader")

function EquipmentOutline_Initialize()

    EquipmentOutline_camera = Client.CreateRenderCamera()
    EquipmentOutline_camera:SetTargetTexture("*equipment_outline", true)
    EquipmentOutline_camera:SetRenderMask(_renderMask)
    EquipmentOutline_camera:SetIsVisible(false)
    EquipmentOutline_camera:SetCullingMode(RenderCamera.CullingMode_Frustum)
    EquipmentOutline_camera:SetRenderSetup("shaders/Mask.render_setup")
    
    EquipmentOutline_screenEffect = Client.CreateScreenEffect("shaders/EquipmentOutline.screenfx")
    EquipmentOutline_screenEffect:SetActive(false)
    
end

function EquipmentOutline_Shudown()

    Client.DestroyRenderCamera(_camera)
    EquipmentOutline_camera = nil
    
    Client.DestroyScreenEffect(_screenEffect)
    EquipmentOutline_screenEffect = nil
    
end

/** Enables or disabls the hive vision effect. When the effect is not needed it should 
 * be disabled to boost performance. */
function EquipmentOutline_SetEnabled(enabled)

    EquipmentOutline_camera:SetIsVisible(enabled and _enabled)
    EquipmentOutline_screenEffect:SetActive(enabled and _enabled)
    
end

/** Must be called prior to rendering */
function EquipmentOutline_SyncCamera(camera, forCommander)

    local distance = ConditionalValue(forCommander, _maxDistance_Commander, _maxDistance)
    
    EquipmentOutline_camera:SetCoords(camera:GetCoords())
    EquipmentOutline_camera:SetFov(camera:GetFov())
    EquipmentOutline_camera:SetFarPlane(distance + 1)
    EquipmentOutline_screenEffect:SetParameter("time", Shared.GetTime())
    EquipmentOutline_screenEffect:SetParameter("maxDistance", distance)
    
end

/** Adds a model to the hive vision */
function EquipmentOutline_AddModel(model)

    local renderMask = model:GetRenderMask()
    model:SetRenderMask(bit.bor(renderMask, _renderMask))
    
end

/** Removes a model from the hive vision */
function EquipmentOutline_RemoveModel(model)

    local renderMask = model:GetRenderMask()
    model:SetRenderMask(bit.band(renderMask, _invRenderMask))
    
end

function EquipmentOutline_UpdateModel(ent)

    local player = Client.GetLocalPlayer()

    if not player or not HasMixin(ent, "Model") or not ent:GetRenderModel() then
        return
    end

    local shouldOutline = false
    if player.GetOutlinedEntity then
        shouldOutline = player:GetOutlinedEntity() == ent
    end

    local model = ent:GetRenderModel()
    
    if shouldOutline ~= model.isOutlined then

        if not model.highlightMaterial then
            model.highlightMaterial = AddMaterial(model, "cinematics/vfx_materials/highlightmodel.material")
        end
    
    
        if shouldOutline then
            model.highlightMaterial:SetParameter("intensity", 0.1)
            EquipmentOutline_AddModel(model)
        else
            model.highlightMaterial:SetParameter("intensity", 0.0)
            EquipmentOutline_RemoveModel(model)
        end
        model.isOutlined = shouldOutline
        
    end
    
end

// For debugging.
local function OnCommandOutline(enabled)
    _enabled = enabled ~= "false"
end
Event.Hook("Console_outline", OnCommandOutline)
