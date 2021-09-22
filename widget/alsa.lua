--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luca CPZ
      * (c) 2010, Adrian C. <anrxc@sysphere.org>

--]]

local helpers = require("lain.helpers")
local shell   = require("awful.util").shell
local wibox   = require("wibox")
local string  = string
local gears = require("gears")

local function get_connections(mixer)
    t = { headphones = false, microphone = false}
    for name, status in string.gmatch(mixer, 
            "name='([%a%s%-]+)'.-: values=([%a]+)") do
        status = true and (status == "on") or false
        -- We are only intrested in headphones and microphone
        if name == "Headphone Jack" then
            t.headphones = status
        elseif name == "Mic Jack" then
            t.microphone = status
        end
    end
    return t
end

-- ALSA volume
-- lain.widget.alsa

local function factory(args)
    args           = args or {}
    local alsa     = { widget = args.widget or wibox.widget.textbox() }
    local timeout  = args.timeout or 5
    local settings = args.settings or function() end

    alsa.cmd           = args.cmd or "amixer"
    alsa.channel       = args.channel or "Master"
    alsa.togglechannel = args.togglechannel

    local format_cmd = string.format("%s get %s", alsa.cmd, alsa.channel)

    if alsa.togglechannel then
        format_cmd = { shell, "-c", string.format("%s get %s; %s get %s",
        alsa.cmd, alsa.channel, alsa.cmd, alsa.togglechannel) }
    end

    alsa.last = {}
    last_connections = {}

    function alsa.update()
        helpers.async("amixer -c 1 contents", function(mixer)
            connections = get_connections(mixer)
            helpers.async(format_cmd, function(mixer)
                gears.debug.dump("\nFrom lain")
                gears.debug.dump("Headphones: " .. tostring(connections.headphones))
                gears.debug.dump("Microphone: " .. tostring(connections.microphone))
                local l,s = string.match(mixer, "([%d]+)%%.*%[([%l]*)")
                gears.debug.dump("Level: " .. l)
                gears.debug.dump("Status: " .. s)
                l = tonumber(l)
                if alsa.last.level ~= l or alsa.last.status ~= s
                    or last_connections.headphones ~= connections.headphones 
                    or last_connnections.microphone ~= connectins.microphone then
                    gears.debug.dump(tostring(alsa.last.level ~= l) .. 
                        " or " .. tostring(alsa.last.status ~= s) ..
                        " or " .. tostring(last_connections.headphones ~= connections.headphones) ..
                        " or " .. tostring(last_connections.microphone ~= connections.microphone))
                    volume_now = { level = l, status = s }
                    widget = alsa.widget
                    settings()
                    alsa.last = volume_now
                    last_connections = connections
                end
            end)
            end)
    end

    helpers.newtimer(string.format("alsa-%s-%s", alsa.cmd, alsa.channel), timeout, alsa.update)

    return alsa
end

return factory
