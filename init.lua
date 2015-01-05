-- Author: Opi Matin

local awful     = require("awful")
local naughty   = require("naughty")
local math      = require("math")
local string	= require("string")
local timer		= timer
local gears 	= require("gears")

local setmetatable = setmetatable
local ipairs = ipairs
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo

--module("awmodoro")



local awmodoro = { mt = {} }
local data = setmetatable({}, { __mode = "k" })

local properties = { "width", "height", "paused_bg_color", "active_bg_color", "fg_color", "seconds", "do_notify"}

local function update(_awmodoro)
	data[_awmodoro].bar:set_value(data[_awmodoro].elapsed)
	_awmodoro:emit_signal("widget::updated")
end

function awmodoro.draw(_awmodoro, wibox, cr, width, height)
	data[_awmodoro].bar:draw(wibox, cr, width, height)
end

function awmodoro.fit(_awmodoro, width, height)
	return data[_awmodoro].width, data[_awmodoro].height
end

function awmodoro:begin()
	if not data[self].timer.started then 
		if data[self].begin_callback then data[self].begin_callback() end
		data[self].elapsed = 0
		data[self].bar:set_background_color(data[self].active_bg_color)
		update(self)
		data[self].timer:start()
		if data[self].do_notify then naughty.notify({text = "Pomodoro Begin"}) end
	end
end

function awmodoro:pause()
	data[self].timer:stop()
	data[self].bar:set_background_color(data[self].paused_bg_color)
	update(self)
    if data[self].do_notify then naughty.notify({text = "Pomodoro Paused"}) end
end

function awmodoro:resume()
	data[self].bar:set_background_color(data[self].active_bg_color)
	update(self)
	data[self].timer:start()
    if data[self].do_notify then naughty.notify({text = "Pomodoro Resumed"}) end
end

function awmodoro:finish()
	data[self].timer:stop()
	data[self].elapsed = data[self].seconds
	update(self)
    if data[self].do_notify then naughty.notify({text = "Pomodoro Finished"}) end
	if data[self].finish_callback then data[self].finish_callback() end
end

function awmodoro:reset()
	data[self].elapsed = 0
	update(self)
    if data[self].do_notify then naughty.notify({text = "Pomodoro Reset"}) end
end

function awmodoro:toggle()
	if data[self].timer.started then
		self:pause()
	elseif data[self].elapsed == 0 or data[self].elapsed == data[self].seconds then
		self:begin()
	else
		self:resume()
	end
end

for _, prop in ipairs(properties) do
	if not awmodoro["set_" .. prop] then
		awmodoro["set_" .. prop] = function(_awmodoro, value)
			data[_awmodoro][prop] = value
			_awmodoro:emit_signal("widget::updated")
			return _awmodoro
		end
	end
end

function awmodoro.new(args)
	local args = args or {}

	local width = args.width or 20
	local height = args.height or 100
	local paused_bg_color = args.paused_bg_color or '#FF732F'
	local active_bg_color = args.active_bg_color or '#494B4F'
	local seconds = (args.minutes and args.minutes * 60) or 25*60
	
	local fg_color = args.fg_color or {type = "linear", from = {0,0}, to = {width, 0}, stops = {{0, "#AECF96"},{0.5, "#88A175"},{1, "#FF5656"}}}
	local do_notify = args.do_notify or false

	local _awmodoro = base.make_widget()

	local bar = awful.widget.progressbar.new({width = width, height = height})

	data[_awmodoro] = { width = width, height = height, seconds = seconds, elapsed = 0, timer = timer({ timeout = 1 }), bar = bar, active_bg_color = active_bg_color, paused_bg_color = paused_bg_color, do_notify = do_notify}

	if args.finish_callback then data[_awmodoro].finish_callback = args.finish_callback end
	if args.begin_callback then data[_awmodoro].begin_callback = args.begin_callback end

	_awmodoro.draw = awmodoro.draw
	_awmodoro.fit = awmodoro.fit
	_awmodoro.toggle = awmodoro.toggle
	_awmodoro.begin = awmodoro.begin
	_awmodoro.pause = awmodoro.pause
	_awmodoro.resume = awmodoro.resume
	_awmodoro.finish = awmodoro.finish
	_awmodoro.reset = awmodoro.reset

	data[_awmodoro].timer:connect_signal("timeout", function(c)
		data[_awmodoro].elapsed = data[_awmodoro].elapsed + 1
		update(_awmodoro)
		if data[_awmodoro].elapsed >= data[_awmodoro].seconds then
			_awmodoro:finish()
		end
	end)

	bar:set_width(width)
	bar:set_height(height)
	bar:set_vertical(false)
	bar:set_max_value(seconds)
	bar:set_background_color(active_bg_color)
	bar:set_color(fg_color)
	
	_awmodoro:buttons(awful.util.table.join(
		awful.button({ }, 1, function() _awmodoro:toggle() end),
		awful.button({ }, 2, function() _awmodoro:finish() end),
		awful.button({ }, 3, function() _awmodoro:reset() end)
		))

	local pomodoro_tooltip = awful.tooltip({
		objects = { _awmodoro },
		timer_function = function()
			local elapsed = data[_awmodoro].elapsed
			local left = data[_awmodoro].seconds - data[_awmodoro].elapsed

			local tip = string.format("%-7s\t%02d:%02d\n%-7s\t%02d:%02d", "Elapsed", math.floor(elapsed / 60), elapsed % 60, "Left", math.floor(left/60), left%60)
			if not data[_awmodoro].timer.started then
				tip = tip .. "\nNot running"
			end
			return tip
		end})

	return _awmodoro
end

function awmodoro.mt:__call(...)
	return awmodoro.new(...)
end

return setmetatable(awmodoro, awmodoro.mt)
