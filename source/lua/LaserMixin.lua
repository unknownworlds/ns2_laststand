// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LaserMixin.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Attaches a laser to an entity. Rendering and events is done client side only,
//    the server controls only the status (active or not active). 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DynamicMeshUtility.lua")

LaserMixin = CreateMixin( LaserMixin )
LaserMixin.type = "Laser"

LaserMixin.kLaserMaterial = "ui/laser.material"

LaserMixin.kLaserLength = 50
LaserMixin.kLaserWidth = 0.065

LaserMixin.kLightRadius = 0.2
LaserMixin.kLightIntensity = 12

LaserMixin.networkVars =
{
    laserActive = "boolean"
}

if Client then

    LaserMixin.expectedCallbacks = 
    {
        GetLaserAttachCoords = "Coords for the laser, updated every frame on the client.",
        GetIsLaserActive = "Return if the laser should be turned on currently."
    }
    
    LaserMixin.optionalCallbacks = 
    {
        OnActivateLaser = "Called on the client when the laser is activated.",
        OnDeactivateLaser = "Called on the client when the laser is activated.",
        OverrideLaserLength = "Return optional max length of laser.",
        OverrideLaserWidth = "Return optional mesh width.",
        OverrideStartColor = "Return a start color for the laser.",
        OverrideEndColor = "Return an end color for the laser."
    }

end

function LaserMixin:__initmixin()

    if Server then
        self.laserActive = false        
    elseif Client then
    
        self:InitializeLaser()
        self:_SetLaserVisible(self.laserActive)
        self.clientLaserActive = self.laserActive
        
    end
    
end

function LaserMixin:OnDestroy()

    if Client then
        self:UninitializeLaser()
    end
    
end

if Client then

    function LaserMixin:_SetLaserVisible(visible)
    
        self.dynamicMesh1:SetIsVisible(visible)
        self.dynamicMesh2:SetIsVisible(visible)
        self.laserLight:SetIsVisible(visible)
    
    end

    function LaserMixin:InitializeLaser()

        if not self.dynamicMesh1 then
            self.dynamicMesh1 = DynamicMesh_Create()
            self.dynamicMesh1:SetMaterial(LaserMixin.kLaserMaterial)
        end
        
        if not self.dynamicMesh2 then
            self.dynamicMesh2 = DynamicMesh_Create()
            self.dynamicMesh2:SetMaterial(LaserMixin.kLaserMaterial)
        end
        
        if not self.laserLight then
        
            self.laserLight = Client.CreateRenderLight()
            
            self.laserLight:SetType( RenderLight.Type_Point )
            self.laserLight:SetCastsShadows( false )


            self.laserLight:SetRadius( LaserMixin.kLightRadius )
            self.laserLight:SetIntensity( LaserMixin.kLightIntensity ) 
            
            local color = Color(1, 0, 0, 1)
            
            // using the start color here because the end color usually has too low alpha
            if self.OverrideStartColor then
                color = self:OverrideStartColor()
            end    
            
            self.laserLight:SetColor( color )
            
        end
        
    end

    function LaserMixin:UninitializeLaser()

        if self.dynamicMesh1 then
            DynamicMesh_Destroy(self.dynamicMesh1)
        end    
        
        if self.dynamicMesh2 then
            DynamicMesh_Destroy(self.dynamicMesh2)
        end
        
        if self.laserLight then        
            Client.DestroyRenderLight(self.laserLight)            
        end
        
    end

    local function SharedUpdate(self)
    
        PROFILE("LaserMixin:SharedUpdate")
    
        self.laserActive = self:GetIsLaserActive()
        
        // optional callback
        if self.clientLaserActive ~= self.laserActive then
        
            self.clientLaserActive = self.laserActive
            self:_SetLaserVisible(self.laserActive)
            
            if self.laserActive and self.OnActivateLaser then
                self:OnActivateLaser()
            end
            
            if not self.laserActive and self.OnDeactivateLaser then
                self:OnDeactivateLaser()
            end    
            
        end
        
        if not self.laserActive then
            return
        end
        
        local coords = self:GetLaserAttachCoords()
        
        local maxLength = LaserMixin.kLaserLength
        local width = LaserMixin.kLaserWidth
        
        if self.OverrideLaserLength then
            maxLength = self:OverrideLaserLength()
        end    
        
        if self.OverrideLaserWidth then
            width = self:OverrideLaserWidth()
        end
        
        local trace = Shared.TraceRay(coords.origin, coords.origin + coords.zAxis * maxLength, CollisionRep.Default, PhysicsMask.Bullets)
        local length = math.abs( (trace.endPoint - coords.origin):GetLength() )
        
        local coordsLeft = Coords.GetIdentity()
        coordsLeft.origin = coords.origin
        coordsLeft.zAxis = coords.zAxis
        coordsLeft.yAxis = coords.xAxis
        coordsLeft.xAxis = -coords.yAxis
        
        local coordsRight = Coords.GetIdentity()
        coordsRight.origin = coords.origin
        coordsRight.zAxis = coords.zAxis
        coordsRight.yAxis = -coords.xAxis
        coordsRight.xAxis = coords.yAxis
        
        local startColor = Color(1, 0, 0, 0.7)
        local endColor = Color(1, 0, 0, 0.07)
        
        if self.OverrideStartColor then
            startColor = self:OverrideStartColor()
        end  
        
        if self.OverrideEndColor then
            endColor = self:OverrideEndColor()
        end     

        DynamicMesh_SetLine(self.dynamicMesh1, coordsLeft, width, length, startColor, endColor)
        DynamicMesh_SetLine(self.dynamicMesh2, coordsRight, width, length, startColor, endColor)
        
        coords.origin = trace.endPoint - trace.normal * 0.17
        self.laserLight:SetCoords(coords)
        
    end
    
    function LaserMixin:OnUpdate(deltaTime)   
        SharedUpdate(self)
    end

    function LaserMixin:OnProcessMove(input)   
        SharedUpdate(self)
    end
    
end