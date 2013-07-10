// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\TokenBucket.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Implementation of the token bucket algorithm, a rate limiter.
//
// Call CreateTokenBucket() passing in the number of tokens added per second and
// the maximum number allowed in the bucket. Then call bucket:RemoveTokens(number)
// with the number of tokens to remove and the function will return true if that
// number of tokens were able to be removed from the bucket. This can be used to
// limit the rate that chat messages are sent or how many bytes of a file are sent
// per second for example.
//
// Basically, imagine there is a bucket. So far so good? Now imagine that a cookie
// is added to that bucket every second. Mmmmmmm. That bucket can only fit 10 cookies.
// So at most there will be 10 cookies in the cookie bucket. You can eat them as fast
// as you want but once there are no more cookies in the cookie bucket you just have
// to wait for more cookies. Who eats more than 10 cookies at a time anyway?
//
// See http://en.wikipedia.org/wiki/Token_bucket for more information.
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

local function AddTokens(self)

    local now = Shared.GetTime()
    
    local timeSinceLastTokenAdded = now - self.lastTimeTokensAdded
    if timeSinceLastTokenAdded >= 1 / self.tokensAddedPerSecond then
    
        local numberOfTokensToAdd = math.floor(timeSinceLastTokenAdded * self.tokensAddedPerSecond)
        if numberOfTokensToAdd > 0 then
        
            self.tokens = math.min(self.maxTokensAllowed, self.tokens + numberOfTokensToAdd)
            self.lastTimeTokensAdded = now
            
        end
        
    end
    
end

local function RemoveTokens(self, numberToRemove)

    // Add tokens to bucket first.
    AddTokens(self)
    
    // Check if we are able to remove the requested number of tokens from the bucket.
    local tokensRemoved = self.tokens >= numberToRemove
    if tokensRemoved then
        self.tokens = self.tokens - numberToRemove
    end
    
    return tokensRemoved
    
end

local function GetNumberOfTokens(self)

    AddTokens(self)
    
    return self.tokens
    
end

function CreateTokenBucket(tokensAddedPerSecond, maxTokensAllowed)

    local now = Shared.GetTime()
    
    return { lastTimeTokensAdded = now, tokens = maxTokensAllowed,
             tokensAddedPerSecond = tokensAddedPerSecond, maxTokensAllowed = maxTokensAllowed,
             RemoveTokens = RemoveTokens, GetNumberOfTokens = GetNumberOfTokens }
    
end