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
require("awmodoro")

pomowibox = awful.wibox({ position = "top", screen = 1, height=4})
pomowibox.visible = false

pomodoro = awmodoro.new({
	minutes 			= 25, 
	do_notify 			= false,
	active_bg_color 	= '#313131',
	paused_bg_color 	= '#7746D7',
	gradient_colors		= { '#9CEF6C', '#FFE473', '#FF7D73' },
--	color 				= '#AECF96', -- gradient_colors has precedence
	width 				= pomowibox.width,
	height 				= pomowibox.height,

	begin_callback = function()
		for s = 1, screen.count() do
			-- change below if necessary
			mywibox[s].visible = false
		end
		pomowibox.visible = true
	end,

	finish_callback = function()
		for s = 1, screen.count() do
			-- change below if necessary
			mywibox[s].visible = true
		end
		pomowibox.visible = false
	end})

pomowibox.widgets = {
	pomodoro.widget,
}
```

In globalkeys:
```lua
awful.key({ modkey			  }, "p", pomodoro.toggle),
awful.key({ modkey,	"Shift"	  }, "p", pomodoro.finish),
```

This creates a separate minimal and initially hidden wibox containing only the awmodoro widget.
We set callbacks to hide other wiboxes at start and to show them again when finished.
We add a keyboard shortcut to start a session and yes one to also end one ;-)


Default mouse bindings are
* Button 1		Toggle pause/resume
* Button 2 (mid)	End session
* Button 3 		Reset timer

These can be overriden by adding and changing
```lua
pomodoro.widget:buttons(awful.util.table.join(
		awful.button({ }, 1, pomodoro.toggle),
		awful.button({ }, 2, pomodoro.finish),
		awful.button({ }, 3, pomodoro.reset)
	))
```
##Widget parameters
	minutes			Minutes defining duration of a session
	active_bg_color	Background color of progress bar when timer is running
	paused_bg_color	Background color of progress bar when timer is paused
	gradient_colors	Foreground colors of progress bar, for instance { '#9CEF6C', '#FFE473', '#FF7D73' }
	color 			Foreground color of progressbar, ignored if gradient_colors is specified
	do_notify		Boolean value specifying wether notifications (using naughty) should be shown. Notifications shown are; begin, 					pause, resume, finish and reset
	width			Width of widget
	height			Height of widget

###Note
If you prefer indivisible sessions (no ability to pause) then instead of pomodoro.toggle use pomodoro.begin and override mouse button 1 to something else but toggle/pause.
