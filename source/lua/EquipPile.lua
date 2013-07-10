
//----------------------------------------
//  A pile of marine equipment. Randomly spawns cool stuff upon certain events.
//  Server-side only, since clients should only know about
//----------------------------------------

Script.Load("lua/Mixins/ModelMixin.lua")

// tweakable vars

local gEquipPiles = {}

class 'EquipPile' (Entity)

local networkVars = { }
AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

EquipPile.modelName = PrecacheAsset("models/marine_crate_02.model")
function EquipPile:GetModelName()
    return EquipPile.modelName
end

function EquipPile:OnInitialized()

    self:SetModel(self:GetModelName())

end

function EquipPile:OnCreate()

    table.insert( gEquipPiles, self )

    self:SetUpdates(true)

    if Server then
        table.insert( gGameEventListeners, self )
    end

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)

end

function EquipPile:SpewFrom(techIds, count)

    for i = 1,count do

        local origin = GetRandomSpawnForCapsule( 0.2, 0.2, self:GetOrigin()+Vector(0,1,0), 0.5, 6, EntityFilterAll )
        if not origin then
            DebugPrint("NO RANDOM SPAWN")
            origin = self:GetOrigin() + Vector(1.0+math.random()*1.0, 0, 1.0+math.random()*1.0 )
        end

        local teamNumber = 1

        // randomly choose
        local techId = techIds[ math.random( #techIds ) ]
        local ent = CreateEntityForTeam( techId, origin, teamNumber, nil )

        if ent.Dropped then
            ent:Dropped(nil)
        end
    
    end

end

function EquipPile:GetDropTechIds()
    return
    {
        kTechId.DropJetpack,
        kTechId.DropJetpack,
        kTechId.DropSentry,
        kTechId.DropSentry,
        kTechId.DropSentry,
        kTechId.DropWelder,
        kTechId.DropWelder,
        kTechId.DropMines,
        kTechId.DropMines,
        kTechId.DropMines,
        kTechId.DropMines,
        kTechId.DropShotgun,
        kTechId.DropShotgun,
        kTechId.DropShotgun,
        kTechId.DropShotgun,
        kTechId.DropGrenadeLauncher,
        kTechId.DropGrenadeLauncher,
        kTechId.DropFlamethrower,
        kTechId.DropFlamethrower
    }
end

function EquipPile:Spew()

    if Server then

        local numMarines = GetGamerules():GetNumMarinePlayers()
        self:SpewFrom( self:GetDropTechIds(), 2*numMarines )

    end

end

function EquipPile:OnPreGameStart()

    self:Spew()

end

function EquipPile:OnUpdate(dt)

end

Shared.LinkClassToMap( "EquipPile", "ls_equip_pile", networkVars )

//----------------------------------------
//  in-game tuning 
//----------------------------------------

Event.Hook("Console_ls_spew", function(client)
            for i, pile in pairs(gEquipPiles) do
                pile:Spew()
            end
        end)


//----------------------------------------
//  Overrides
//----------------------------------------

class 'MedsPile' (EquipPile)
Shared.LinkClassToMap("MedsPile", "ls_meds_pile", {})
function MedsPile:GetDropTechIds()
    return
    {
        kTechId.DropMedPack
    }
end

MedsPile.modelName = PrecacheAsset("models/marine_crate_01_med.model")
function MedsPile:GetModelName()
    return MedsPile.modelName
end

//----------------------------------------
//  
//----------------------------------------
class 'AmmoPile' (EquipPile)
Shared.LinkClassToMap("AmmoPile", "ls_ammo_pile", {})
function AmmoPile:GetDropTechIds()
    return
    {
        kTechId.DropAmmoPack
    }
end

AmmoPile.modelName = PrecacheAsset("models/marine_crate_01_ammo.model")
function AmmoPile:GetModelName()
    return AmmoPile.modelName
end

