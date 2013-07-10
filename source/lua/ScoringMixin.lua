// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ScoringMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * ScoringMixin keeps track of a score. It provides function to allow changing the score.
 */
ScoringMixin = CreateMixin( ScoringMixin )
ScoringMixin.type = "Scoring"

ScoringMixin.expectedCallbacks =
{
    SetScoreboardChanged = "Called to notify the entity that the score has changed and should be updated on the client's scoreboard."
}

function ScoringMixin:__initmixin()

    self.score = 0
    // Some types of points are added continuously. These are tracked here.
    self.continuousScores = { }
    
end

function ScoringMixin:GetScore()
    return self.score
end
AddFunctionContract(ScoringMixin.GetScore, { Arguments = { "Entity" }, Returns = { "number" } })

function ScoringMixin:AddScore(points, res)

    // Should only be called on the Server.
    if Server then
    
        // Tell client to display cool effect.
        if points ~= nil and points ~= 0 then
        
            local displayRes = ConditionalValue(type(res) == "number", res, 0)
            Server.SendCommand(self, string.format("points %s %s", tostring(points), tostring(displayRes)))
            self.score = Clamp(self.score + points, 0, self:GetMixinConstants().kMaxScore or 100)
            self:SetScoreboardChanged(true)

        end
    
    end
    
end

// Only award the pointsGivenOnScore once the amountNeededToScore are added into the score
// determined by the passed in name.
// An example, to give points based on health healed:
// AddContinuousScore("Heal", amountHealed, 100, 1)
function ScoringMixin:AddContinuousScore(name, addAmount, amountNeededToScore, pointsGivenOnScore)

    if Server then
    
        self.continuousScores[name] = self.continuousScores[name] or { amount = 0 }
        self.continuousScores[name].amount = self.continuousScores[name].amount + addAmount
        while self.continuousScores[name].amount >= amountNeededToScore do
        
            self:AddScore(pointsGivenOnScore, 0)
            self.continuousScores[name].amount = self.continuousScores[name].amount - amountNeededToScore
            
        end
        
    end
    
end

function ScoringMixin:ResetScores()
    self.score = 0
end