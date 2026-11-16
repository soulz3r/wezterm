-- WezTerm loads this file from the user's home directory, while the
-- actual configuration project lives in D:\\config\\wezterm.

local project_dir = "D:/config/wezterm"

package.path = table.concat({
	project_dir .. "/lua/?.lua",
	project_dir .. "/lua/?/init.lua",
	package.path,
}, ";")

return require("config")
