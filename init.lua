-- Author: Opi Matin

local awful     = require("awful")
local naughty   = require("naughty")
local math      = require("math")
local string		= require("string")
local timer			= timer

module("awmodoro")

function new(args)
    local args = args or {}
    
    local width = args.width or 20
    local height = args.height or 100
    local paused_bg_color = args.paused_bg_color or '#FF732F'
    local active_bg_color = args.active_bg_color or '#494B4F'
    local gradient_colors = args.gradient_colors or { '#AECF96', '#88A175', '#FF5656' }
    local seconds = (args.minutes and args.minutes * 60) or 25*60
    local do_notify = args.do_notify or false

    local pomodoro = {seconds = seconds, elapsed = 0, timer = timer({ timeout = 1 })}

    if args.finish_callback then pomodoro.finish_callback = args.finish_callback end
    if args.begin_callback then pomodoro.begin_callback = args.begin_callback end

    pomodoro.begin = function ()
    	if not pomodoro.timer.started then 
	    	if pomodoro.begin_callback then pomodoro.begin_callback() end
			pomodoro.elapsed = 0
			pomodoro.refresh()
	    	pomodoro.progressbar:set_background_color(active_bg_color)
			pomodoro.timer:start()
			if do_notify then naughty.notify({text = "Begin"}) end
		end
	end

	pomodoro.pause = function ()
		pomodoro.timer:stop()
		pomodoro.progressbar:set_background_color(paused_bg_color)
		if do_notify then naughty.notify({text = "Paused"}) end
	end

	pomodoro.resume = function ()
		pomodoro.progressbar:set_background_color(active_bg_color)
		pomodoro.timer:start()
		if do_notify then naughty.notify({text = "Resume"}) end
	end

	pomodoro.finish = function ()
		pomodoro.timer:stop()
		pomodoro.elapsed = pomodoro.seconds
		pomodoro.refresh()
		if do_notify then naughty.notify({text = "Finished"}) end
		if pomodoro.finish_callback then pomodoro.finish_callback() end
	end

	pomodoro.reset = function ()
		pomodoro.elapsed = 0
		pomodoro.refresh()
		if do_notify then naughty.notify({text = "Reset"}) end
	end

	pomodoro.toggle = function ()
		if pomodoro.timer.started then
			pomodoro.pause()
		elseif pomodoro.elapsed == 0 or pomodoro.elapsed == pomodoro.seconds then
			pomodoro.begin()
		else
			pomodoro.resume()
		end
	end

	pomodoro.refresh = function ()
		pomodoro.progressbar:set_value(pomodoro.elapsed)
	end

	pomodoro.timer:add_signal("timeout", function(c)
		pomodoro.elapsed = pomodoro.elapsed + 1
		pomodoro.refresh()
		if pomodoro.elapsed >= pomodoro.seconds then
			pomodoro.finish()
		end
	end)

	pomodoro.progressbar = awful.widget.progressbar.new()

	pomodoro.progressbar:set_width(width)
	pomodoro.progressbar:set_height(height)
	pomodoro.progressbar:set_vertical(false)
	pomodoro.progressbar:set_max_value(seconds)
	pomodoro.progressbar:set_background_color(active_bg_color)
	if args.gradient_colors then 
		pomodoro.progressbar:set_gradient_colors(args.gradient_colors)
	elseif args.color then
		pomodoro.progressbar:set_color(args.color)
	else 
		pomodoro.progressbar:set_gradient_colors(gradient_colors)
	end
	
	pomodoro.widget = pomodoro.progressbar.widget

	pomodoro.widget:buttons(awful.util.table.join(
		awful.button({ }, 1, pomodoro.toggle),
		awful.button({ }, 2, pomodoro.finish),
		awful.button({ }, 3, pomodoro.reset)
	))

	local pomodoro_tooltip = awful.tooltip({
		objects = { pomodoro.widget },
		timer_function = function()
			local elapsed = pomodoro.elapsed
			local left = pomodoro.seconds - pomodoro.elapsed

			local tip = string.format("%-7s\t%02d:%02d\n%-7s\t%02d:%02d", "Elapsed", math.floor(elapsed / 60), elapsed % 60, "Left", math.floor(left/60), left%60)
			if not pomodoro.timer.started then
				tip = tip .. "\nNot running"
			end
			return tip
		end,
	})

    return pomodoro
end
