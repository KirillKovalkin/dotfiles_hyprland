---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use

local DEFAULT_APPS = {}
local run = "uwsm app -- "

DEFAULT_APPS.browser = run .. "google-chrome-stable"
-- DEFAULT_APPS.fileManager = run .. "yazi" -- not using
DEFAULT_APPS.menu = run .. "fuzzel"
DEFAULT_APPS.terminal = run .. "alacritty"

return DEFAULT_APPS
