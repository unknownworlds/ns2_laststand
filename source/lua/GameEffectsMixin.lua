// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GameEffectsMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * GameEffectsMixin keeps track of anything that has an effect on an entity and
 * provides methods to query these effects.
 */
GameEffectsMixin = CreateMixin( GameEffectsMixin )
GameEffectsMixin.type = "GameEffects"

GameEffectsMixin.optionalCallbacks =
{
    OnGameEffectMaskChanged = "Called when a game effect is turned on or off.",
}

GameEffectsMixin.networkVars =
{
    // kGameEffectMax comes from Globals file.
    gameEffectsFlags = "integer (0 to " .. (kGameEffectMax - 1) .. ")"
}

function GameEffectsMixin:__initmixin()

    // Flags to indicate if we're under effect of anything (but doesn't include count).
    self.gameEffectsFlags = 0
    
end

function GameEffectsMixin:GetGameEffectMask(effect)
    return bit.band(self.gameEffectsFlags, effect) ~= 0
end
AddFunctionContract(GameEffectsMixin.GetGameEffectMask, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

// Sets or clears a game effect flag
function GameEffectsMixin:SetGameEffectMask(effectBitMask, state)

    assert(effectBitMask ~= nil)
    assert(type(state) == "boolean")
    
    local startGameEffectsFlags = self.gameEffectsFlags
    
    if state then
    
        // Set game effect bit
        if self.OnGameEffectMaskChanged and not self:GetGameEffectMask(effectBitMask) then
            self:OnGameEffectMaskChanged(effectBitMask, true)
        end
        
        self.gameEffectsFlags = bit.bor(self.gameEffectsFlags, effectBitMask)
        
    else
    
        // Clear game effect bit
        if self.OnGameEffectMaskChanged and self:GetGameEffectMask(effectBitMask) then
            self:OnGameEffectMaskChanged(effectBitMask, false)
        end

        local notEffect = bit.bnot(effectBitMask)
        self.gameEffectsFlags = bit.band(self.gameEffectsFlags, notEffect)
        
    end
    
    // Return if state changed
    return startGameEffectsFlags ~= self.gameEffectsFlags
    
end
AddFunctionContract(GameEffectsMixin.SetGameEffectMask, { Arguments = { "Entity", "number", "boolean" }, Returns = { "boolean" } })

function GameEffectsMixin:ClearGameEffects()

    if self.OnGameEffectMaskChanged then
    
        if self.gameEffectsFlags then
        
            for i, effect in pairs(kGameEffect) do 

                if bit.band(self.gameEffectsFlags, effect) ~= 0 then
                    self:OnGameEffectMaskChanged(effect, false)
                end
                
            end
            
        end
        
    end
    
    self.gameEffectsFlags = 0
    
end
AddFunctionContract(GameEffectsMixin.ClearGameEffects, { Arguments = { "Entity" }, Returns = { } })

function GameEffectsMixin:OnKill()

    self:ClearGameEffects()

end
AddFunctionContract(GameEffectsMixin.OnKill, { Arguments = { "Entity" }, Returns = { } })
