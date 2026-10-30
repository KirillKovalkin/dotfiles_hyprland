--------------------------
---- MACHINE DEFAULTS ----
--------------------------
-- Single source of truth for THIS host.
-- After edits run: ./scripts/sync-machine.sh
-- (rewrites hyprpaper.conf, quickshell/machine.conf, quickshell/wallpaper.path)
--
-- Hardware (reference):
--   CPU : Intel Core i5-11500 (Rocket Lake, UHD 750 iGPU present but unused for displays)
--   GPU : AMD Radeon RX 9060 XT (discrete — drives DP-1 / HDMI-A-1)
--   VA-API: radeonsi  → AMD dGPU decode (NOT the Intel iGPU; that would be iHD)

local M = {}

-- VA-API for the GPU that does video decode (AMD dGPU → radeonsi)
M.libva_driver = "radeonsi"

-- Primary / gaming output — bar auto-hides fullscreen here
M.gaming_output = "DP-1"

-- Wallpaper relative to $HOME (canonical; sync-machine expands for hyprpaper)
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
