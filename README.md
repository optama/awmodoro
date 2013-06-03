#Awmodoro
###Clutter-free Pomodoro sessions in Awesome WM
The basic idea is to at start (with for instance a keybinding)
* hide clutter (widgets/wibox)
* show a very out-of-our-way and subtle indication of elapsed and left time

and at stop
* bring back user to the real world

Awmodoro is in itself a very simple timer (with a progress bar ui) specifically made with regards to the "Pomodoro Technique".
It can be used as a regular widget, however - awmodoro provides the user with hooks allowing lua-code to be executed at start and end of each session. This allows for setup and teardown of distraction free environments.


##Usage
	cd ~/.config/awesome
	git clone git://github.com/optama/awmodoro.git

Example configuration, in rc.lua:
```lua
local awmodoro = require("awmodoro")

--pomodoro wibox
pomowibox = awful.wibox({ position = "top", screen = 1, height=4})
pomowibox.visible = false
local pomodoro = awmodoro.new({
	minutes 			= 25,
	do_notify 			= true,
	active_bg_color 	= '#313131',
	paused_bg_color 	= '#7746D7',
	fg_color			= {type = "linear", from = {0,0}, to = {pomowibox.width, 0}, stops = {{0, "#AECF96"},{0.5, "#88A175"},{1, "#FF5656"}}},
	width 				= pomowibox.width,
	height 				= pomowibox.height, 

	begin_callback = function()
		for s = 1, screen.count() do
			mywibox[s].visible = false
		end
		pomowibox.visible = true
	end,

	finish_callback = function()
		for s = 1, screen.count() do
			mywibox[s].visible = true
		end
		pomowibox.visible = false
	end})
pomowibox:set_widget(pomodoro)
```

In globalkeys:
```lua
awful.key({	modkey			}, "p", function () pomodoro:toggle() end),
awful.key({	modkey, "Shift"	}, "p", function () pomodoro:finish() end),
```

This creates a separate minimal and initially hidden wibox containing only the awmodoro widget.
We set callbacks to hide other wiboxes at start and to show them again when finished.
We add a keyboard shortcut to start a session and yes one to also end one ;-)


Default mouse bindings are
* Button 1			Toggle pause/resume
* Button 2 (mid)	End session
* Button 3 			Reset timer

These can be overriden by adding and changing
```lua
pomodoro:buttons(awful.util.table.join(
	awful.button({ }, 1, function() pomodoro:toggle() end),
	awful.button({ }, 2, function() pomodoro:finish() end),
	awful.button({ }, 3, function() pomodoro:reset() end)
))
```
##Widget parameters
	minutes			Minutes defining duration of a session
	active_bg_color	Background color of progress bar when timer is running
	paused_bg_color	Background color of progress bar when timer is paused
	fg_color		Foreground color(s) of progress bar
	do_notify		Boolean value specifying wether notifications (using naughty) should be shown. Notifications shown are; begin, pause, resume, finish and reset
	width			Width of widget
	height			Height of widget

Colors are provided according to format specified by http://awesome.naquadah.org/doc/api/modules/gears.color.html

###Note
If you prefer indivisible sessions (no ability to pause) then instead of pomodoro:toggle() use pomodoro:begin() and override mouse button 1 to something else but toggle/pause.
