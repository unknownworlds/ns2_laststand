// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\HUDCinematic.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Displays a cinematic in RenderScene.Zone_ViewModel. You can specify a background texture
//    (can also be a script material file for interactive backgrounds) and handles the client
//    resolution/FOV to position the background + cinematic properly. You can specify a custom
//    Z value which will increase the height and width of the primitve.
//
// TODO: apply correct rotation to cinematics so they will face always the camera
// TODO: add "CreateRenderModel"
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'HUDCinematic'

local kSquareTexCoords = { 1,1, 0,1, 0,0, 1,0 }
local kSquareIndices = { 3, 0, 1, 1, 2, 3 }
local kSquareColors = { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, }

local kCinematicOffset = 1.5

local function SetProjectionDirty(self)
    self.projectionDirty = true
end

local function GetWorldSpacePosition(screenSpaceVector)

    local player = Client.GetLocalPlayer()
    local viewCoords = player:GetCameraViewCoords()
    local relativWorldPos = Vector(0,0,0)

    local pickVec =  Client.CreatePickingRayXY(screenSpaceVector.x, screenSpaceVector.y)
    
    // get relativ vector
    relativWorldPos.x = viewCoords.xAxis:DotProduct(pickVec)
    relativWorldPos.y = viewCoords.yAxis:DotProduct(pickVec)
    relativWorldPos.z = viewCoords.zAxis:DotProduct(pickVec)
    
    // instersect with far plane
    local worldCoords = Coords.GetIdentity()
    local farPlaneOrigin = Vector(0,0, screenSpaceVector.z)
    relativWorldPos = GetLinePlaneIntersection(farPlaneOrigin, -worldCoords.zAxis, worldCoords.origin, relativWorldPos)
    
    return relativWorldPos
    
end

local function CreateHudCinematic(self, cinematicName)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
    cinematic:SetCinematic(cinematicName)
    cinematic:SetIsVisible(self.visible)
    cinematic:SetRepeatStyle(self.repeatStyle)
    
    return cinematic
    
end

function HUDCinematic:Initialize()

    self.backgroundCoords = {
        x1 = 0,
        y1 = 0,
        x2 = 0,
        y2 = 0
    }
    
    self.visible = true
    self.repeatStyle = Cinematic.Repeat_Loop
    
    // top left, top right, bottom right, bottom left
    self.meshVertices = {
        0,0,0,
        0,0,0,
        0,0,0,
        0,0,0,
    }
    
    self.zDistance = 0.3
    
    // will force recalculation of worldspace projection when true
    self.projectionDirty = false
    
end

function HUDCinematic:Destroy()

    if self.cinematic then
        Client.DestroyCinematic(self.cinematic)
        self.cinematic = nil
    end
    
    if self.dynamicMesh then
        Client.DestroyRenderDynamicMesh(self.dynamicMesh)
        self.dynamicMesh = nil
    end
    
    if self.model then
        Client.DestroyRenderModel(self.model)
        self.model = nil
    end

end

function HUDCinematic:SetBackgroundMaterial(materialName)

    if not self.dynamicMesh then
        self.dynamicMesh = CreateDynamicMesh(self)
    end
    
    self.dynamicMesh:SetMaterial(materialName)

end

function HUDCinematic:SetCinematic(cinematicName)

    if self.cinematic then
        Client.DestroyCinematic(self.cinematic)
    end

    self.cinematic = CreateHudCinematic(self, cinematicName)
    
end

function HUDCinematic:SetModel(modelName)

    if self.model then
        Client.DestroyRenderModel(self.model)
    end
    
    local modelIndex = Shared.GetModelIndex(modelName)
    self.model = Client.CreateRenderModel(RenderScene.Zone_ViewModel)
    self.model:SetModel(modelIndex)
    self.model:SetIsVisible(self.visible)

end

function HUDCinematic:SetRepeatStyle(repeatStyle)

    self.repeatStyle = repeatStyle
    if self.cinematic then
        self.cinematic:SetRepeatStyle(repeatStyle)
    end
    
end

function HUDCinematic:GetIsVisible()
    return self.visible
end

function HUDCinematic:SetIsVisible(visible)
    
    self.visible = visible
    if self.cinematic then
        self.cinematic:SetIsVisible(visible)
    end
    
    if self.dynamicMesh then
        self.dynamicMesh:SetIsVisible(visible)
    end
    
end

function HUDCinematic:SetZDistance(zDistance)
    self.zDistance = zDistance
    SetProjectionDirty(self)
end

function HUDCinematic:SetPosition(posVector)

    local width = self.backgroundCoords.x2 - self.backgroundCoords.x1
    local height = self.backgroundCoords.y2 - self.backgroundCoords.y1

    self.backgroundCoords.x1 = posVector.x
    self.backgroundCoords.y1 = posVector.y
    self.backgroundCoords.x2 = self.backgroundCoords.x1 + width
    self.backgroundCoords.y2 = self.backgroundCoords.y1 + height
    
    SetProjectionDirty(self)

end

function HUDCinematic:SetSize(sizeVector)

    self.backgroundCoords.x2 = self.backgroundCoords.x1 + sizeVector.x
    self.backgroundCoords.y2 = self.backgroundCoords.y1 + sizeVector.y
    
    SetProjectionDirty(self)

end

function HUDCinematic:_InternalUpdateProjection()

    local screenPos1 = Vector(
        self.backgroundCoords.x1,
        self.backgroundCoords.y1,
        self.zDistance)
        
    local screenPos2 = Vector(
        self.backgroundCoords.x2,
        self.backgroundCoords.y2,
        self.zDistance)
        
    local cinematicOffset = kCinematicOffset * (Client.GetScreenWidth() / Client.GetScreenHeight())
        
    local averageScreenPos = Vector(
        self.backgroundCoords.x1 + (self.backgroundCoords.x2 - self.backgroundCoords.x1)/2,
        self.backgroundCoords.y1 + (self.backgroundCoords.y2 - self.backgroundCoords.y1)/2,
        cinematicOffset)
    
    local worldPos1 = GetWorldSpacePosition(screenPos1)
    local worldPos2 = GetWorldSpacePosition(screenPos2)
    
    self.meshVertices = {
    
        // bottom left
        worldPos1.x, worldPos2.y, worldPos1.z,
        
        // bottom right
        worldPos2.x, worldPos2.y, worldPos1.z,
        
        // top right
        worldPos2.x, worldPos1.y, worldPos1.z,
        
        // top left
        worldPos1.x, worldPos1.y, worldPos1.z,
    }

    
    if not self.dynamicMesh then
        self.dynamicMesh = CreateDynamicMesh(self)
    end
    
    self.dynamicMesh:SetIndices(kSquareIndices, #kSquareIndices)
    self.dynamicMesh:SetTexCoords(kSquareTexCoords, #kSquareTexCoords)
    self.dynamicMesh:SetVertices(self.meshVertices, #self.meshVertices)
    self.dynamicMesh:SetColors(kSquareColors, #kSquareColors)
    
    // update cinematic coords:
    
    local cinematicCoords = Coords.GetIdentity()
    cinematicCoords.origin = GetWorldSpacePosition(averageScreenPos)
    cinematicCoords.origin.z = cinematicOffset * Client.GetLocalPlayer():GetRenderFov()

    if self.cinematic then
        self.cinematic:SetCoords(cinematicCoords)
    end
    
    if self.model then
        self.model:SetCoords(cinematicCoords)
    end
    

end

// update the position and angles
function HUDCinematic:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    
    if player then

        local viewCoords = player:GetCameraViewCoords()
        
        if self.dynamicMesh then
            self.dynamicMesh:SetCoords(viewCoords)
        end
    
    end

    if self.projectionDirty then
        self:_InternalUpdateProjection()
        self.projectionDirty = false
    end

end





