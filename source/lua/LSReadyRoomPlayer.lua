Script.Load("lua/Player.lua")

Script.Load("lua/Mixins/CameraHolderMixin.lua")


class 'LSReadyRoomPlayer' (Player)

LSReadyRoomPlayer.kMapName = "ls_ready_room_player"

local networkVars = { }

AddMixinNetworkVars(CameraHolderMixin, networkVars)



function LSReadyRoomPlayer:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    
    Player.OnCreate(self)

end


function LSReadyRoomPlayer:OnInitialized()

    Player.OnInitialized(self)
   
    self:SetIsVisible(false)     
    
    if Client and Client.GetLocalPlayer() == self then
        self.joinMenu = GetGUIManager():CreateGUIScript("LSGUIJoinTeam")
        self.joinMenu.player = self
        MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)     
    end
    
end

function LSReadyRoomPlayer:OnDestroy()

    if self.joinMenu ~= nil then
        GetGUIManager():DestroyGUIScript(self.joinMenu)
        MouseTracker_SetIsVisible(false)
    end
    
end

function LSReadyRoomPlayer:GetPlayerStatusDesc()
    return kPlayerStatus.Void
end

function LSReadyRoomPlayer:GetVelocity()
    return Vector(0, 0, 0)
end

function LSReadyRoomPlayer:GetVelocityFromPolar()
    return Vector(0, 0, 0)
end

// Update origin and velocity from input.
function LSReadyRoomPlayer:OnProcessMove(input)
    
    local gamerules = GetGamerules()
    
    if gamerules ~= nil and gamerules.GetTeam ~= nil then
    
        local marineTeam = gamerules:GetTeam(kMarineTeamType)
        local marineSpawn = marineTeam:GetSpawnPosition()

        self:SetOrigin(marineSpawn + Vector(-15, 20, 0))
    end
    
end

function LSReadyRoomPlayer:UpdateViewAngles()

    local yawDegrees = 90
    local pitchDegrees = 70
    local angles = Angles((pitchDegrees / 90) * math.pi / 2, (yawDegrees / 90) * math.pi / 2, 0)
    
    // Update to the current view angles.
    self:SetViewAngles(angles)

end

function LSReadyRoomPlayer:GetIsOverhead()
    return true
end

function LSReadyRoomPlayer:GetGravityEnabled()
    return true
end

function LSReadyRoomPlayer:SetGravityEnabled(enabled)
end

Shared.LinkClassToMap("LSReadyRoomPlayer", LSReadyRoomPlayer.kMapName, networkVars)
