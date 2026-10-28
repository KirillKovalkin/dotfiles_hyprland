------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Values come from machine.lua (edit there for another host).

local machine = require("machine")

for _, mon in ipairs(machine.monitors) do
	hl.monitor(mon)
end

for _, rule in ipairs(machine.workspace_rules) do
	hl.workspace_rule(rule)
end
