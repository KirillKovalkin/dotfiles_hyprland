--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize activate activatefocus",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Application-specific window rules
hl.window_rule({
	name = "Visual Studio Code",
	match = { class = "code" },
	workspace = 1,
})

hl.window_rule({
	name = "YouTube Music",
	match = { class = "chrome-music.youtube.com__-Default" },
	workspace = 5,
})

hl.window_rule({
	name = "Steam",
	match = { class = "steam", title = "^(Steam|Friends List)$" },
	workspace = 4,
	tile = true,
})

hl.window_rule({
	name = "Telegram",
	match = { class = "org.telegram.desktop" },
	workspace = 3,
})

hl.window_rule({
	name = "Discord",
	match = { class = "chrome-discord.com__app-Default" },
	workspace = 3,
})

hl.window_rule({
	name = "CS2 - low latency",
	match = { class = "cs2" },
	content = "game",
	idle_inhibit = "fullscreen",
	sync_fullscreen = true,
})
