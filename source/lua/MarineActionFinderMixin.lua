// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MarineActionFinderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

local kFindWeaponRange = 2.0
local kIconUpdateRate = 0.1

MarineActionFinderMixin = CreateMixin( MarineActionFinderMixin )
MarineActionFinderMixin.type = "MarineActionFinder"

MarineActionFinderMixin.expectedCallbacks =
{
    GetOrigin = "Returns the position of the Entity in world space"
}

function MarineActionFinderMixin:__initmixin()

    if Client and Client.GetLocalPlayer() == self then
    
        self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.actionIconGUI:SetColor(kMarineFontColor)
        self.lastMarineActionFindTime = 0

        // client-only cache for highlighting
        self.weaponTarget = nil 
        self.useTarget = nil
        
    end
    
end

function MarineActionFinderMixin:OnDestroy()

    if Client and self.actionIconGUI then
    
        GetGUIManager():DestroyGUIScript(self.actionIconGUI)
        self.actionIconGUI = nil
        
    end
    
end

function MarineActionFinderMixin:TraceForActionTargets(isValidTraceFunc)

    local viewDirection = self:GetViewCoords().zAxis
    local lineStart = self:GetEyePos()
    local lineEnd = lineStart + viewDirection*kFindWeaponRange

    // First try a thin ray
    local trace = Shared.TraceRay( lineStart, lineEnd, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(self, self:GetActiveWeapon()) )

    if isValidTraceFunc(self, trace) then
        return trace.entity
    end

    // Defer to a sphere (capsule with 0 height) trace
    trace = Shared.TraceCapsule( lineStart, lineEnd, 0.2, 0, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(self, self:GetActiveWeapon()) )

    if isValidTraceFunc(self, trace) then
        return trace.entity
    end

    // Found nothing
    return nil

end

function MarineActionFinderMixin:FindWeaponTarget()

    return self:TraceForActionTargets(
            function(player, trace)
                return trace.fraction < 1 and trace.entity and HasMixin(trace.entity, "Pickupable")
                and trace.entity:isa("Weapon") and trace.entity:GetIsValidRecipient(self)
            end)

end

function MarineActionFinderMixin:FindDismantleTarget()

    return self:TraceForActionTargets(
        function(player, trace)
            local e = trace.entity
            return e and HasMixin(e, "Digest") and e:GetCanDigest(self)
        end)

end

if Client then

    function MarineActionFinderMixin:GetOutlinedEntity()
        return self.weaponTarget or self.useTarget
    end

    function MarineActionFinderMixin:OnProcessMove(input)
    
        PROFILE("MarineActionFinderMixin:OnProcessMove")
        
        local actionsAllowed = GetGamerules():GetIsMarinePrepTime()
        local prediction = Shared.GetIsRunningPrediction()
        local now = Shared.GetTime()
        local enoughTimePassed = (now - self.lastMarineActionFindTime) >= kIconUpdateRate

        if not prediction and enoughTimePassed then

            // handle visuals for dropping/using targeting
        
            self.lastMarineActionFindTime = now
            
            local showIcon = false
            self.weaponTarget = nil
            self.useTarget = nil
            
            if actionsAllowed and self:GetIsAlive() and not GetIsVortexed(self) then
            
                self.weaponTarget = self:FindWeaponTarget()

                if self.weaponTarget then
                
                    self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), self.weaponTarget:GetClassName(), self.weaponTarget:GetClassName())
                    showIcon = true
                    
                else
                
                    self.useTarget = self:PerformUseTrace()

                    if self.useTarget and GetPlayerCanUseEntity(self, self.useTarget) and not self:GetIsUsing() then
                        
                        self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, self.useTarget:GetClassName())
                        showIcon = true
                        
                    end

                    // Try 
                    if not self.useTarget then

                        local target = self:FindDismantleTarget()

                        if target then
                            digestFraction = target:GetDigestFraction()
                            self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, "Dismantle", digestFraction)
                            self.useTarget = target
                            showIcon = true
                        end

                    end
                    
                end
                
            end
            
            if not showIcon then
                self.actionIconGUI:Hide()
            end
            
        end
        
    end
    
end
