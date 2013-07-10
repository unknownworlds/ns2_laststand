
class 'GUIJetpackRealFuel' (GUIJetpackFuel)

function GUIJetpackRealFuel:GetBackgroundOffsetX()
    return GUIJetpackFuel.kBackgroundOffsetX + GUIJetpackFuel.kBackgroundWidth*1.5
end

function GUIJetpackRealFuel:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    
    if player and player.GetRealFuel then
        self:SetFuel(player:GetRealFuel())
    end

end


