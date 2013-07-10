// ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\HudModel.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Manages displaying a 3d hud. Use client side only.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineHudModel = PrecacheAsset("models/marine/hud/hud_bg.model")
kInitMarineHudCinematic = PrecacheAsset("cinematics/marine/hud/init_hud.cinematic")
kInitMarineHudCinematicDuration = 3

kAlienHudModel = nil

local gAnimFunc = nil
// each entry should look like: { Name = "someName", GetFunc = SomeFunction }
local gMaterialParams = {}
local gRenderModel = nil

function HudModel_SetMaterialParameter(paramName, value)

    if gRenderModel ~= nil then
        gRenderModel:SetMaterialParameter(paramName, value)  
    end

end

local function GetIsLocal(player)
    return player == Client.GetLocalPlayer()
end

function HudModel_CreateMarineHud(player)

    local materialParams = {
    
        { Name = "currentHealth", GetFunc = PlayerUI_GetPlayerHealth },
        { Name = "currentArmor", GetFunc = PlayerUI_GetPlayerArmor },
        { Name = "parasiteState", GetFunc = PlayerUI_GetPlayerParasiteState },
        { Name = "jetpackFuel", GetFunc = PlayerUI_GetPlayerJetpackFuel },
        { Name = "maxHealth", GetFunc = PlayerUI_GetPlayerMaxHealth },
        { Name = "maxArmor", GetFunc = PlayerUI_GetPlayerMaxArmor },
        
    }

    HudModel_Create(player, kMarineHudModel, HudModel_AnimateBobbing, materialParams)

end

function HudModel_CreateAlienHud(player)

    local materialParams = {
    
        { Name = "alienCurrentHealth", GetFunc = PlayerUI_GetPlayerHealth },
        { Name = "alienCurrentArmor", GetFunc = PlayerUI_GetPlayerArmor },
    
    }
    
    HudModel_Create(player, kAlienHudModel, HudModel_AnimateFollow, materialParams)

end

// animate call back functions

// bobbing effect
local kCorrectAnglesPerSecond = 0.01
local kBobbingToleranz = 0.01
local kBobbingFactor = 0.03

local gBobbingVars = {}
gBobbingVars.hudAngles = nil
gBobbingVars.lastPlayerAngles = nil
gBobbingVars.timeCinematicStart = nil

function HudModel_AnimateBobbing(player, deltaTime)

    if not gBobbingVars.hudAngles then
        gBobbingVars.hudAngles = Angles(0, 0, 0)
    end
        
    if not gBobbingVars.lastPlayerAngles then
        gBobbingVars.lastPlayerAngles = player:GetViewAngles()
    end
        
    local currentAngles = player:GetViewAngles()
    
    local angleDiff = Angles(GetAnglesDifference(currentAngles.pitch, gBobbingVars.lastPlayerAngles.pitch ) *  kBobbingFactor, GetAnglesDifference(currentAngles.yaw, gBobbingVars.lastPlayerAngles.yaw) * kBobbingFactor, 0)
    
    gBobbingVars.hudAngles.yaw = Clamp(gBobbingVars.hudAngles.yaw + angleDiff.yaw, -kBobbingToleranz, kBobbingToleranz)
    gBobbingVars.hudAngles.pitch = Clamp(gBobbingVars.hudAngles.pitch + angleDiff.pitch, -kBobbingToleranz, kBobbingToleranz)
    
    local toCorrect = kCorrectAnglesPerSecond * deltaTime
    
    if gBobbingVars.hudAngles.yaw < 0 then
        gBobbingVars.hudAngles.yaw = Clamp(gBobbingVars.hudAngles.yaw + toCorrect, -kBobbingToleranz, 0)
    else
        gBobbingVars.hudAngles.yaw = Clamp(gBobbingVars.hudAngles.yaw - toCorrect,  0, kBobbingToleranz)
    end
    
    if gBobbingVars.hudAngles.pitch < 0 then
        gBobbingVars.hudAngles.pitch = Clamp(gBobbingVars.hudAngles.pitch + toCorrect, -kBobbingToleranz, 0)
    else
        gBobbingVars.hudAngles.pitch = Clamp(gBobbingVars.hudAngles.pitch - toCorrect,  0, kBobbingToleranz)
    end
  
    local coords = gBobbingVars.hudAngles:GetCoords()
        
    // update model and cinematics positions
    gRenderModel:SetCoords(coords)
    
    local hudParams = Client.GetLocalPlayer():GetHudParams() 
        
    // store for next frame
    gBobbingVars.lastPlayerAngles = player:GetViewAngles()

end

// simple follow
local function HudModel_AnimateFollow()
    //gRenderModel:SetCoords(player:GetViewAngles():GetCoords())
end

function HudModel_Create(player, modelName, animFunc, materialParams)

    if GetIsLocal(player) then
    
        if gRenderModel then        
            Client.DestroyRenderModel(gRenderModel)        
        end

        gAnimFunc = animFunc
        gMaterialParams = materialParams
        gRenderModel = Client.CreateRenderModel(RenderScene.Zone_ViewModel)
        gRenderModel:SetCastsShadows(false)
        gRenderModel:SetModel(modelName)
        
        if gAnimFunc == nil then
            gAnimFunc = HudModel_AnimateFollow
        end
        
        HudModel_Update(player, 0) 
        
    end

end

local function HudModel_UpdateMaterialParams(player, materialParams)

    for index, param in ipairs(materialParams) do
    
        if param.GetFunc == nil then
            Print("WARNING: function for material parameter %s is nil.", tostring(param.Name))
        else    
            gRenderModel:SetMaterialParameter(param.Name, param.GetFunc())  
        end  
    end

end

function HudModel_Update(player, deltaTime)

    if GetIsLocal(player) then
    
        if gRenderModel == nil then
            Print("WARNING: no hud model specified")
            return
        end
        
        gRenderModel:SetIsVisible(not Client.GetLocalPlayer():GetIsThirdPerson())
    
        // update material parameters
        HudModel_UpdateMaterialParams(player, gMaterialParams)
        
        // update hud model specific
        gAnimFunc(player, deltaTime)
    
    end

end

function HudModel_Destroy(player)

    if GetIsLocal(player) then
    
        if gRenderModel then
            Client.DestroyRenderModel(gRenderModel)
        end
        gRenderModel = nil
        gMaterialParams = {}
        gAnimFunc = nil
    
    end

end