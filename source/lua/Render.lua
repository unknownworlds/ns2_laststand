/**
 * Syncrhonizes the render settings on the camera with the stored render options
 */
function Render_SyncRenderOptions()

    local ambientOcclusion  = Client.GetOptionString("graphics/display/ambient-occlusion", "off")
    local atmospherics      = Client.GetOptionBoolean("graphics/display/atmospherics", true)
    local bloom             = Client.GetOptionBoolean("graphics/display/bloom", true)
    local shadows           = Client.GetOptionBoolean("graphics/display/shadows", true)
    local antiAliasing      = Client.GetOptionBoolean("graphics/display/anti-aliasing", true)
    local fog               = Client.GetOptionBoolean("graphics/display/fog", false)
    local particleQuality   = Client.GetOptionString("graphics/display/particles", "low")
    local reflections       = Client.GetOptionBoolean("graphics/reflections", false)

    Client.SetRenderSetting("mode", "lit")
    Client.SetRenderSetting("ambient_occlusion", ambientOcclusion)
    Client.SetRenderSetting("atmospherics", ToString(atmospherics))
    Client.SetRenderSetting("bloom"  , ToString(bloom))
    Client.SetRenderSetting("shadows", ToString(shadows))
    Client.SetRenderSetting("anti_aliasing", ToString(antiAliasing))
    Client.SetRenderSetting("fog", ToString(fog))
    Client.SetRenderSetting("particles", particleQuality)
    Client.SetRenderSetting("reflections", ToString(reflections))

end

local function RenderConsoleHandler(name, key)
    return function (enabled)
        if enabled == nil then
            enabled = "true"
        end
        Client.SetRenderSetting(name, ToString(enabled))
        Client.SetOptionBoolean(key, enabled == "true")
    end
end

local function OnConsoleRenderMode(mode)
    if Shared.GetCheatsEnabled() then
        if mode == nil then
            mode = "lit"
        end
        Client.SetRenderSetting("mode", mode)
    end
end

Client.AddTextureLoadRule("*_spec.dds", 1)  // Load all specular maps at 1/2 resolution
Client.AddTextureLoadRule("ui/*.*", -100)   // Don't reduce resolution on UI textures

Event.Hook("Console_r_mode",            OnConsoleRenderMode )
Event.Hook("Console_r_shadows",         RenderConsoleHandler("shadows", "graphics/display/shadows") )
Event.Hook("Console_r_ao",              RenderConsoleHandler("ambient_occlusion", "graphics/display/ambient-occlusion") )
Event.Hook("Console_r_atmospherics",    RenderConsoleHandler("atmospherics", "graphics/display/atmospherics") )
Event.Hook("Console_r_aa",              RenderConsoleHandler("anti_aliasing", "graphics/display/anti-aliasing") )
Event.Hook("Console_r_bloom",           RenderConsoleHandler("bloom", "graphics/display/bloom") )
Event.Hook("Console_r_fog",             RenderConsoleHandler("fog", "graphics/display/fog") )

Event.Hook("Console_r_pq",
function(arg)
    if arg == "high" then
        Client.SetRenderSetting("particles", "high")
        Client.SetOptionString("graphics/display/particles", "high")
    else
        Client.SetRenderSetting("particles", "low")
        Client.SetOptionString("graphics/display/particles", "low")
    end
end)

