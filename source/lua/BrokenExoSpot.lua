
//----------------------------------------
//  A pile of marine equipment. Randomly spawns cool stuff upon certain events.
//  Server-side only, since clients should only know about
//----------------------------------------

// tweakable vars

local kExoDropTechIds = 
{
    kTechId.DropExosuit,
    kTechId.DropDualRailExo,
    kTechId.DropClawRailExo,
    kTechId.DropDualMiniExo
}

class 'BrokenExoSpot' (Entity)


function BrokenExoSpot:OnInitialized()

end

function BrokenExoSpot:OnCreate()

    if Server then
        table.insert( gGameEventListeners, self )
    end

    //self:SetUpdates(true)

end


function BrokenExoSpot:OnPreGameStart()

    DebugPrint("spawning exo")
    local origin = self:GetOrigin()
    origin = GetGroundAtPosition(origin, nil, PhysicsMask.AllButPCs)
    local teamNumber = 1

    // randomly choose
    local techIds = kExoDropTechIds
    local techId = techIds[ math.random( #techIds ) ]
    local exo = CreateEntityForTeam( techId, origin, teamNumber, nil )

end

function BrokenExoSpot:OnUpdate(dt)

end

Shared.LinkClassToMap( "BrokenExoSpot", "ls_exo", networkVars )

