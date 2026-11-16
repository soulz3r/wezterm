-- WezTerm configuration entry point.

local wezterm = require("wezterm")
local config_dir = wezterm.config_dir

-- WezTerm searches the config root by default. This project keeps modules
-- under lua/, so add both supported Lua module layouts explicitly.
package.path = table.concat({
	config_dir .. "/lua/?.lua",
	config_dir .. "/lua/?/init.lua",
	package.path,
}, ";")

return require("config")
