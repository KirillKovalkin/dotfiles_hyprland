---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us, ru",
		kb_options = "grp:win_space_toggle",
		follow_mouse = 1,
		accel_profile = "flat",
		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
		force_no_accel = true,

		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
