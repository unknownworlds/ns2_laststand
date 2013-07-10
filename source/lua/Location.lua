// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Location.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Represents a named location in a map, so players can see where they are.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Trigger.lua")

Shared.PrecacheSurfaceShader("materials/power/powered_decal.surface_shader")

class 'Location' (Trigger)

Location.kMapName = "location"

local networkVars =
{
    showOnMinimap = "boolean",
}

Shared.PrecacheString("")

function Location:OnInitialized()

    Trigger.OnInitialized(self)
    
    // Precache name so we can use string index in entities
    Shared.PrecacheString(self.name)
    
    // Default to show.
    if self.showOnMinimap == nil then
        self.showOnMinimap = true
    end
    
    self:SetTriggerCollisionEnabled(true)
    
    self:SetPropagate(Entity.Propagate_Always)
    
end

function Location:Reset()

end    

function Location:OnDestroy()

    Trigger.OnDestroy(self)
    
    if Client then
        self:HidePowerStatus()
    end

end

function Location:GetShowOnMinimap()
    return self.showOnMinimap
end

if Server then

    function Location:OnTriggerEntered(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            //Log("%s enter loc %s ('%s') from '%s'", entity, self, self:GetName(), entity:GetLocationName())
            // only if we have no location do we set the location here
            // otherwise we wait until we exit the location to set it
            if not entity:GetLocationEntity() then
                entity:SetLocationName(triggerEnt:GetName())
                entity:SetLocationEntity(self)
            end
        end
            
    end
    
    function Location:OnTriggerExited(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            local enteredLoc = GetLocationForPoint(entity:GetOrigin(), self)
            local name = enteredLoc and enteredLoc:GetName() or ""
            //Log("%s exited location %s('%s'), entered '%s'", entity, self, self:GetName(), name)
            entity:SetLocationName(name)
            entity:SetLocationEntity(enteredLoc)
        end            
    end
end

// used for marine commander to show/hide power status in a location
if Client then

    function Location:ShowPowerStatus(powered)

        if not self.powerDecal then
            self.materialLoaded = nil  
        end

        if powered then
        
            if self.materialLoaded ~= "powered" then
            
                if self.powerDecal then
                    Client.DestroyRenderDecal(self.powerDecal)
                    Client.DestroyRenderMaterial(self.powerMaterial)
                end
                
                self.powerDecal = Client.CreateRenderDecal()
                
                local material = Client.CreateRenderMaterial()
                material:SetMaterial("materials/power/powered_decal.material")
        
                self.powerDecal:SetMaterial(material)
                self.materialLoaded = "powered"
                self.powerMaterial = material
                
            end

        else
            
            if self.powerDecal then
                Client.DestroyRenderDecal(self.powerDecal)
                Client.DestroyRenderMaterial(self.powerMaterial)
                self.powerDecal = nil
                self.powerMaterial = nil
                self.materialLoaded = nil
            end
            
            /*
            
            if self.materialLoaded ~= "unpowered" then
            
                if self.powerDecal then
                    Client.DestroyRenderDecal(self.powerDecal)
                end
                
                self.powerDecal = Client.CreateRenderDecal()
        
                self.powerDecal:SetMaterial("materials/power/unpowered_decal.material") 
                self.materialLoaded = "unpowered"
            
            end
            
            */
            
        end
        
    end

    function Location:HidePowerStatus()

        if self.powerDecal then
            Client.DestroyRenderDecal(self.powerDecal)
            Client.DestroyRenderMaterial(self.powerMaterial)
            self.powerDecal = nil
            self.powerMaterial = nil
        end

    end
    
    function Location:OnUpdateRender()
    
        PROFILE("Location:OnUpdateRender")
        
        local player = Client.GetLocalPlayer()      

        local showPowerStatus = player and player.GetShowPowerIndicator and player:GetShowPowerIndicator()
        local powerPoint

        if showPowerStatus then
            powerPoint = GetPowerPointForLocation(self.name)
            showPowerStatus = powerPoint ~= nil   
        end  
        
        if showPowerStatus then
                
            self:ShowPowerStatus(powerPoint:GetIsPowering())
            if self.powerDecal then
            
                // TODO: Doesn't need to be updated every frame, only setup on creation.
            
                local origin = self:GetOrigin()
                local extents = self.scale * 0.23
                extents.y = 10
                origin.y = powerPoint:GetOrigin().y - 2

                local coords = Coords.GetTranslation(origin)
                
                // Get the origin in the object space of the decal.
                local osOrigin = coords:GetInverse():TransformPoint( powerPoint:GetOrigin() )
                self.powerMaterial:SetParameter("osOrigin", osOrigin)

                self.powerDecal:SetCoords(coords)
                self.powerDecal:SetExtents(extents)
                
            end
            
        else
            self:HidePowerStatus()
        end   
        
    end
    
end

Shared.LinkClassToMap("Location", Location.kMapName, networkVars)