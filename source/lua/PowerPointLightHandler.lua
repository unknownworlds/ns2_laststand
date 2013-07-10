// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPointLightHandler.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Responsible for working the lights on a map. This is a performance critical area, as there are
// lots of lights and they may need to be updated each client frame. Also, ALL lights over the whole
// map is updated at all times, as the player can see light coming from powerpoints located very far
// from his actual position.
//
// Care must be taken to ensure that updating does not take too much time. 
//
// Design 
//
// For each PowerPoint, a PowerPointLightHandler class is created. 
//
// The PowerPointLightHandler contains a LightWorker for each kLightMode that the powerpoint can be in.
// Each frame, the PowerPointLightHandler for each powerpoint is called. It checks what worker should be
// run this frame and makes sure that if the mode has changed, the new worker is initialized.
// Then, the selected worker is Run().
//
// Normally, a worker has a table of activeLights, and as time passes, the activeLights table
// empties and you end up with no lights in the activeTable, and thus basically no CPU spent.
//
// If you end up in a non-static state, try skipping some updates (keeping changes in ligth to 20 updates per sec)
// or optimize it similar to the NoPowerLightWorkers use of LightGroups.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kMinCommanderLightIntensityScalar = 0.3

local kPowerDownTime = 1
local kOffTime = 15
local kLowPowerCycleTime = 1
local kLowPowerMinIntensity = 0.4
local kDamagedCycleTime = 0.8
local kDamagedMinIntensity = 0.7
local kAuxPowerCycleTime = 3
local kAuxPowerMinIntensity = 0
local kAuxPowerMinCommanderIntensity = 3

// set the intensity and color for a light. If the renderlight is ambient, we set the color
// the same in all directions
local function SetLight(renderLight, intensity, color)

    if intensity then
        renderLight:SetIntensity(intensity)
    end
    
    if color then
    
        renderLight:SetColor(color)
        
        if renderLight:GetType() == RenderLight.Type_AmbientVolume then
        
            renderLight:SetDirectionalColor(RenderLight.Direction_Right,    color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Left,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Up,       color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Down,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Backward, color)
            
        end
        
    end
    
end

class 'PowerPointLightHandler'

function PowerPointLightHandler:Init(powerPoint)

    self.powerPoint = powerPoint
    self.lightTable = { }
    self.probeTable = { }
    
    // all lights for this powerPoint, and filter away those that
    // shouldn't be affected by the power changes
    for _, light in ipairs(GetLightsForLocation(powerPoint:GetLocationName())) do
    
        if not light.ignorePowergrid then
            self.lightTable[light] = true
        end
        
    end
    
    for _, probe in ipairs(GetReflectionProbesForLocation(powerPoint:GetLocationName())) do
        self.probeTable[probe] = true
    end

    self.lastWorker = nil
    self.lastTimeOfChange = nil
    
    self.workerTable = {
        [kLightMode.Normal] = NormalLightWorker():Init(self, "normal"),
        [kLightMode.NoPower] = NoPowerLightWorker():Init(self, "nopower"),
        [kLightMode.LowPower] = LowPowerLightWorker():Init(self, "lowpower"),
        [kLightMode.Damaged] = DamagedLightWorker():Init(self, "damaged"),
    }
    
    return self
    
end

function PowerPointLightHandler:Run(mode)

    local worker = self.workerTable[mode]
    local timeOfChange = self.powerPoint:GetTimeOfLightModeChange()
    
    if self.lastWorker ~= worker or self.lastTimeOfChange ~= timeOfChange then
    
        worker:Activate()
        self.lastWorker = worker
        self.lastTimeOfChange = timeOfChange
        
    end
    worker:Run()
    
end

//
// Base class for all LightWorkers, ie per-mode workers.
//
class 'BaseLightWorker'

function BaseLightWorker:Init(handler, name)

    self.handler = handler
    self.name = name
    self.activeLights = {}
    self.activeProbes = false
    
    return self
    
end

// called whenever the mode changes so this Worker is activated
function BaseLightWorker:Activate()

    for light,_ in pairs(self.handler.lightTable) do
    
        self.activeLights[light] = true
        light.randomValue = Shared.GetRandomFloat()
        light.flickering = nil
        
    end
    
    self.activeProbes = true
    
end

// if a light should try to flicker, call with the light and the chance to flicker
function BaseLightWorker:CheckFlicker(renderLight, chance, scalar)

    if renderLight.flickering == nil then
        renderLight.flickering = math.random() < chance
    end
    
    if renderLight.flickering then
        return self:FlickerLight(scalar)
    end
    
    return 1
    
end

function BaseLightWorker:FlickerLight(scalar)

    if scalar < 0.5 then
    
        local flicker_intensity = Clamp(math.sin(math.pow((1 - scalar) * 6, 8)) + 1, .8, 2) / 2.0
        return flicker_intensity * flicker_intensity
        
    end
    return 1
    
end


function BaseLightWorker:RestoreColor(renderLight)

    renderLight:SetColor(renderLight.originalColor)

    if renderLight:GetType() == RenderLight.Type_AmbientVolume then

        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    renderLight.originalRight)
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     renderLight.originalLeft)
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       renderLight.originalUp)
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     renderLight.originalDown)
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  renderLight.originalForward)
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, renderLight.originalBackward)
        
    end

end

//
// handles kLightMode.Normal
//
class 'NormalLightWorker' (BaseLightWorker)

function NormalLightWorker:Activate()

    BaseLightWorker.Activate(self)
    
    self.lastUpdateTimePassed = -1
    
end

// Turning on full power. 
// When turn on full power, the lights are never decreased in intensity.
//
function NormalLightWorker:Run()

    PROFILE("NormalLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange    

    if self.activeProbes then
    
        local startFullLightTime = PowerPoint.kMinFullLightDelay
        local fullFullLightTime = startFullLightTime + PowerPoint.kFullPowerOnTime      
        
        local probeTint = nil
        
        if timePassed < startFullLightTime then
            // we don't change lights or color during this period        
            probeTint = nil
        else
            probeTint = Color(1, 1, 1, 1)
            self.activeProbes = false
        end

        if probeTint ~= nil then
            for probe,_ in pairs(self.handler.probeTable) do
                probe:SetTint( Color(1, 1, 1, 1) )
            end
         end
        
    end

    for renderLight,_ in pairs(self.activeLights) do

        local intensity = nil
        local randomValue = renderLight.randomValue
    
        local startFullLightTime = PowerPoint.kMinFullLightDelay + PowerPoint.kMaxFullLightDelay * randomValue
        // time when full lightning is achieved
        local fullFullLightTime = startFullLightTime + PowerPoint.kFullPowerOnTime  
 
        if timePassed < startFullLightTime then

            // we don't change lights or color during this period        
            intensity = nil
          
        elseif timePassed < fullFullLightTime then
            
            // the period when lights start to come on, possibly with a little flickering
            local t = timePassed - startFullLightTime
            local scalar = math.sin(( t / PowerPoint.kFullPowerOnTime  ) * math.pi / 2)
            intensity = renderLight.originalIntensity * scalar
            
            if renderLight.flickering == nil and intensity < renderLight:GetIntensity() then
                // don't change anything until we exceed the origin light intensity.
                intensity = nil
            else
            
                if renderLight.flickering == nil then
                    self:RestoreColor(renderLight)
                end
                intensity = intensity * self:CheckFlicker(renderLight,PowerPoint.kFullFlickerChance, scalar)
                
            end
            
        else
            
            intensity = renderLight.originalIntensity
            
            self:RestoreColor(renderLight)
            
            // remove this light from processing
            self.activeLights[renderLight] = nil
            
        end
        
        // color are only changed once during the full-power-on
        SetLight(renderLight, intensity, nil)

    end

end

//
// Handles Damaged. In damaged state, all lights cycle once whenever they are damaged 
// then and the go back to steady state. Whenever we are damaged anew, we are reset and
// start over
//
class 'DamagedLightWorker' (BaseLightWorker)

function DamagedLightWorker:Run()

    PROFILE("DamagedLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange
    
    local scalar = math.sin(Clamp(timePassed / kDamagedCycleTime, 0, 1) * math.pi)
    
    for renderLight, _ in pairs(self.activeLights) do
    
        local intensity = renderLight.originalIntensity * (1 - scalar * (1 - kDamagedMinIntensity))
        SetLight(renderLight, intensity, nil)
        
    end
    
    if timePassed > kDamagedCycleTime then
        self.activeLights = { }
        self.activeProbes = false
    end
    
end

// Handles LowPower warning.
// This cycles the light constantly 
class 'LowPowerLightWorker' (BaseLightWorker)

function LowPowerLightWorker:Run()

    PROFILE("LowPowerLightWorker:Run")
    
    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange 
    
    local scalar = math.cos((timePassed / (kLowPowerCycleTime / 2)) * math.pi / 2)
    local minIntensity = kLowPowerMinIntensity
    local halfIntensity = (1 - minIntensity) / 2
    
    for renderLight,_ in pairs(self.activeLights) do
    
         // Cycle lights up and down telling everyone that there's an imminent threat
        local intensity = renderLight.originalIntensity * minIntensity + halfIntensity + scalar * halfIntensity
        SetLight(renderLight, intensity, nil)
        
    end
    
end


// Handles NoPower. This is a bit complex, as we end up in a continouosly varying light
// state, where the auxilary light cycles now and then. To 
class 'NoPowerLightWorker' (BaseLightWorker)

NoPowerLightWorker.kNumGroups = 10

function NoPowerLightWorker:Init(handler, name)

    BaseLightWorker.Init(self, handler, name)
    
    self.lightGroups = {}
    
    for i = 0, NoPowerLightWorker.kNumGroups, 1 do
        self.lightGroups[i] = LightGroup():Init()
    end
    
    return self
    
end

function NoPowerLightWorker:Activate()

    BaseLightWorker.Activate(self)
    for i = 0, NoPowerLightWorker.kNumGroups, 1 do
        self.lightGroups[i].lights = {}
    end
    
end

//
// handles lights when the powerpoint has no power. This involves a time with no lights,
// and then a period when lights are coming on line into aux power setting. Once the aux light
// has stabilized, the lights will stay mostly steady, but will sometimes cycle a bit.
//
// Performance wise, we shift lights from the activeLights table over to lightgroups. Each group
// of lights stay fixed for a while, then starts to cycle as one for another span of time. Done
// this way so that we can avoid running the lights most of the time.
//
function NoPowerLightWorker:Run()

    PROFILE("NoPowerLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange    
    
    local startAuxLightTime = kPowerDownTime + kOffTime
    local fullAuxLightTime = startAuxLightTime + kAuxPowerCycleTime
    local startAuxLightFailTime = fullAuxLightTime + PowerPoint.kAuxLightSafeTime
    local totalAuxLightFailTime = startAuxLightFailTime + PowerPoint.kAuxLightDyingTime
    
    local probeTint
    
    if timePassed < kPowerDownTime then
        local intensity = math.sin(Clamp(timePassed / kPowerDownTime, 0, 1) * math.pi / 2)
        probeTint = Color(intensity, intensity, intensity, 1)
    elseif timePassed < startAuxLightTime then
        probeTint = Color(0, 0, 0, 1)
    elseif timePassed < fullAuxLightTime then
    
        // Fade red in smoothly. t will stay at zero during the individual delay time
        local t = timePassed - startAuxLightTime
        // angle goes from zero to 90 degres in one kAuxPowerCycleTime
        local angleRad = (t / kAuxPowerCycleTime) * math.pi / 2
        // and scalar goes 0->1
        local scalar = math.sin(angleRad)

        probeTint = Color(PowerPoint.kDisabledColor.r * scalar,
                          PowerPoint.kDisabledColor.g * scalar,
                          PowerPoint.kDisabledColor.b * scalar,
                          1)
 
    else
        self.activeProbes = false
    end

    if self.activeProbes then    
        for probe,_ in pairs(self.handler.probeTable) do
            probe:SetTint( probeTint )
        end
    end

    
    for renderLight,_ in pairs(self.activeLights) do
        
        local randomValue = renderLight.randomValue
        // aux light starting to come on
        local startAuxLightTime = kPowerDownTime + kOffTime + randomValue * PowerPoint.kMaxAuxLightDelay 
        // ... fully on
        local fullAuxLightTime = startAuxLightTime + kAuxPowerCycleTime
        // aux lights starts to fade
        local startAuxLightFailTime = fullAuxLightTime + PowerPoint.kAuxLightSafeTime + randomValue * PowerPoint.kAuxLightFailTime
        // ... and dies completly
        local totalAuxLightFailTime = startAuxLightFailTime + PowerPoint.kAuxLightDyingTime
        
        local intensity = nil
        local color = nil
        
        local showCommanderLight = false
        
        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
            showCommanderLight = true
        end
        
        if timePassed < kPowerDownTime then
        
            local scalar = math.sin(Clamp(timePassed / kPowerDownTime, 0, 1) * math.pi / 2)
            scalar = (1 - scalar)
            if showCommanderLight then
                scalar = math.max(kMinCommanderLightIntensityScalar, scalar)
            end
            intensity = renderLight.originalIntensity * (1 - scalar)

        elseif timePassed < startAuxLightTime then
        
            if showCommanderLight then
                intensity = renderLight.originalIntensity * kMinCommanderLightIntensityScalar
            else
                intensity = 0  
            end     
            
        elseif timePassed < fullAuxLightTime then
        
            // Fade red in smoothly. t will stay at zero during the individual delay time
            local t = timePassed - startAuxLightTime
            // angle goes from zero to 90 degres in one kAuxPowerCycleTime
            local angleRad = (t / kAuxPowerCycleTime) * math.pi / 2
            // and scalar goes 0->1
            local scalar = math.sin(angleRad)
            
            if showCommanderLight then
                scalar = math.max(kMinCommanderLightIntensityScalar, scalar)
            end
            
            intensity = scalar * renderLight.originalIntensity

            intensity = intensity * self:CheckFlicker(renderLight,PowerPoint.kAuxFlickerChance, scalar)
            
            if showCommanderLight then
                color = PowerPoint.kDisabledCommanderColor
            else
                color = PowerPoint.kDisabledColor
            end
     
        else
        
            // Deactivate from initial state
            self.activeLights[renderLight] = nil
            
            // in steady state, we shift lights between a constant state and a varying state.
            // We assign each light to one of several groups, and then randomly start/stop cycling for each group. 
            local lightGroupIndex = math.floor(math.random() * NoPowerLightWorker.kNumGroups)
            self.lightGroups[lightGroupIndex].lights[renderLight] = true

        end
        
        SetLight(renderLight, intensity, color)
        
    end

    // handle the light-cycling groups.
    for _,lightGroup in pairs(self.lightGroups) do
        lightGroup:Run(timePassed)
    end

end

// used to cycle lights periodically in groups
class 'LightGroup'

function LightGroup:Init()

    self.lights = {}
    self.cycleUsedTime = 0
    self.cycleEndTime = 0
    self.cycleStartTime = 0
    self.nextThinkTime = 0
    self.stateFunction = LightGroup.RunFixed
    
    return self
    
end

function LightGroup:Run(time)

    if time >= self.nextThinkTime then
        self:stateFunction(time)
    end
    
end

function LightGroup:RunFixed(time)

    // shift this group from fixed to cycling
    self.stateFunction = LightGroup.RunCycle
    self.cycleBaseTime = time
    self.cycleStartTime = time
    self.cycleEndTime = time + math.random(10)
    self.nextThinkTime = time
    
end

function LightGroup:RunCycle(time)

    if time > self.cycleEndTime then
    
        // end varying cycle and fix things for a while. Note that the intensity will
        // stay a bit random, which is all to the good.
        self.stateFunction = LightGroup.RunFixed
        self.nextThinkTime = time + math.random(10)
        self.cycleUsedTime = self.cycleUsedTime + (time - self.cycleStartTime)
        
    else
    
        // this is the time used to calc intensity. This is calculated so that when
        // we restart after a pause, we continue where we left off.
        local t = time - self.cycleStartTime + self.cycleUsedTime 
        
        local showCommanderLight = false
        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
            showCommanderLight = true
        end
        
        for renderLight,_ in pairs(self.lights) do
        
            // Fade disabled color in and out to make it very clear that the power is out        
            local scalar = math.cos((t / (kAuxPowerCycleTime / 2)) * math.pi / 2)
            local halfAmplitude = (1 - kAuxPowerMinIntensity) / 2
            
            local minIntensity = kAuxPowerMinIntensity
            color = PowerPoint.kDisabledColor
            
            if showCommanderLight then
            
                minIntensity = kAuxPowerMinCommanderIntensity
                color = PowerPoint.kDisabledCommanderColor
                
            end
            
            local disabledIntensity = (kAuxPowerMinIntensity + halfAmplitude + scalar * halfAmplitude)
            intensity = renderLight.originalIntensity * disabledIntensity
            
            SetLight(renderLight, intensity, color)
            
        end
        
    end
    
end