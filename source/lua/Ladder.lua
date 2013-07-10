// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Ladder.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// Represents a climbable ladder that is placed in the world.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Ladder' (Trigger)

Ladder.kMapName = "ladder"

function Ladder:OnInitialized()

    Trigger.OnInitialized(self)
    
    self:SetTriggerCollisionEnabled(true)
    
end

function Ladder:OnTriggerEntered(enterEnt, triggerEnt)
    
    if enterEnt.SetIsOnLadder and (enterEnt.GetCanClimb and enterEnt:GetCanClimb()) then
        enterEnt:SetIsOnLadder(true, self)
    end
    
end

function Ladder:OnTriggerExited(exitEnt, triggerEnt)
    
    if exitEnt.SetIsOnLadder then
        exitEnt:SetIsOnLadder(false, nil)
    end
    
end

Shared.LinkClassToMap("Ladder", Ladder.kMapName, {})