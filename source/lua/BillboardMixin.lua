// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\BillboardMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

// order defines priority
kBillboard = enum({
    'None',
    'HealingSource',
    'NeedsWelding',
    'VoiceChatting',
})

BillboardMixin = CreateMixin( BillboardMixin )
BillboardMixin.type = "Billboard"

BillboardMixin.networkVars =
{
    activeBillboard = "enum kBillboard"
}

BillboardMixin.expectedMixins = 
{
}

function BillboardMixin:__initmixin()

    self.activeBillboard = kBillboard.None
    if Server then
    
        // TimeExpires = time, Billboard = enum kBillboard 
        self.billboardQueue =   {}
    
    end
    
end

if Server then

    local function SortByPriority(billboard1, billboard2)
        return billboard1.Billboard <= billboard2.Billboard
    end

    // pass either duration or a callback to define when billboard should be cleaned
    function BillboardMixin:SetBillboard(billboard, duration, callback)
    
        local timeExpires = nil
        if duration then
            timeExpires = Shared.GetTime() + duration
        end

        table.insert(self.billboardQueue, {TimeExpires = timeExpires, Billboard = billboard, Callback = callback} )        
        table.sort(self.billboardQeue, SortByPriority)

    end
    
    local function CheckRemoveBillboardEntry(self, billboardEntry)
    
        return ( billboardEntry.TimeExpires and billboardEntry.TimeExpires < Shared.GetTime() ) or 
           ( billboardEntry.Callback and not billboardEntry.Callback(self) )
    
    end

    function BillboardMixin:OnUpdate(deltaTime)

        for i = 1, #self.billboardQueue do
        
            if CheckRemoveBillboardEntry(self, self.billboardQueue[1]) then
                table.remove(self.billboardQueue, 1)
            else
                self.activeBillboard = self.billboardQueue[1].Billboard
                break
            end
        
        end
        
        if #self.billboardQueue == 0 then
            self.activeBillboard = kBillboard.None
        end 

    end

elseif Client then

    function BillboardMixin:OnUpdateRender()

        // TODO: set billboard texture and move with unit

    end
    
end    
