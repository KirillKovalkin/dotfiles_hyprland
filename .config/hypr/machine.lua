--------------------------
---- MACHINE DEFAULTS ----
--------------------------
-- Host-specific values for this desktop.
-- Keep in sync manually with:
--   hyprpaper.conf, quickshell/machine.conf, quickshell/wallpaper.path, uwsm/env
--
-- Hardware:
--   CPU : Intel Core i5-11500
--   GPU : AMD Radeon RX 9060 XT (drives DP-1 / HDMI-A-1)
--   VA-API: radeonsi (AMD dGPU; set in .config/uwsm/env)

local M = {}

M.libva_driver = "radeonsi"
M.gaming_output = "DP-1"
M.wallpaper_rel = "Pictures/Wallpaper/wallpaper.webp"

M.monitors = {
	{
		output = "DP-1",
		mode = "1920x1080@240",
		position = "0x0",
		scale = 1,
	},
	{
		output = "HDMI-A-1",
		mode = "1920x1080@60",
		position = "1920x0",
		scale = 1,
	},
}

M.workspace_rules = {
	{ workspace = "1", monitor = "DP-1", default = true },
	{ workspace = "2", monitor = "HDMI-A-1" },
	{ workspace = "3", monitor = "HDMI-A-1" },
	{ workspace = "4", monitor = "DP-1" },
	{ workspace = "5", monitor = "HDMI-A-1" },
}

return M
