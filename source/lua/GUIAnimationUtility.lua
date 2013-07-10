// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAnimationUtility.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Collection of utility functions for gui animations.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
                          
local gAnimTime = 0                          

function UpdateAnimTime(deltaTime)
    if not Client or not Client.GetTime then
        gAnimTime = gAnimTime + deltaTime
    end
end

function GetAnimTime()
    if Client and Client.GetTime then
        return Client.GetTime()
    end

    return gAnimTime
end

// callbacks which return a fraction value (0 to 1) of the animation

// as the function name says, linear animation
function AnimateLinear(startTime, duration)
    return  Clamp( (GetAnimTime() - startTime) / duration, 0, 1)
end

// slow start, very fast approach
function AnimateQuadratic(startTime, duration)
    local fraction = Clamp( (GetAnimTime() - startTime) / duration, 0, 1)
    return fraction * fraction
end

// very fast start, slow approach
function AnimateSqRt(startTime, duration)
    local fraction = Clamp( (GetAnimTime() - startTime) / duration, 0, 1)
    return math.sqrt(fraction)
end

// fast start, slow approach
function AnimateSin(startTime, duration)
    local piFraction = Clamp( (GetAnimTime() - startTime) / duration, 0, 1) * (math.pi / 2)
    return math.sin(piFraction)
end

// slow start, fast approach
function AnimateCos(startTime, duration)
    local piFraction = Clamp( (GetAnimTime() - startTime) / duration, 0, 1) * (math.pi / 2)
    return math.cos(piFraction + math.pi) + 1
end

function AnimateElastic(startTime, duration)

    local n = Clamp((GetAnimTime() - startTime) / duration, 0, 1)
    return 1 * math.pow(2, -10 * n) * math.cos((n - 0.075) * (2 * math.pi) / 0.3) + 1
    
end