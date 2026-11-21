local wezterm = require("wezterm")
local act = wezterm.action
local registry = require("features.action_registry")
local dispatch = require("features.action_dispatch")
local shells = require("config.shells")

local M = {}
local pending = {}

local CUSTOM_SCHEMES = {
	"Minmax Phosphor",
	"Minmax Mono",
	"Minmax Amber",
	"Minmax Oxide",
}

local function notify(window, title, message, duration)
	window:toast_notification(title, message, nil, duration or 2500)
end

local function write_items(items)
	local path = os.tmpname()
	local file, err = io.open(path, "wb")
	if not file then
		error("Cannot create fzf menu data: " .. tostring(err))
	end

	local ok, write_err = pcall(function()
		local written, err = file:write(wezterm.json_encode(items))
		if not written then error(err) end
		local closed, close_err = file:close()
		if not closed then error(close_err) end
	end)
	if not ok then
		pcall(function() file:close() end)
		os.remove(path)
		error("Cannot write fzf menu data: " .. tostring(write_err))
	end
	return path
end

local function active_minmax_variant(window, options)
	local overrides = window:get_config_overrides() or {}
	local scheme = overrides.color_scheme or options.default_scheme or "Minmax Phosphor"
	local variant = type(scheme) == "string" and scheme:lower():match("^minmax%s+(%w+)$")
	if variant == "mono" or variant == "amber" or variant == "oxide" then
		return variant
	end
	return "phosphor"
end

local function open(window, pane, items, options)
	if #items == 0 then
		notify(window, "WezTerm", "There are no available entries.")
		return
	end

	local ok, path = pcall(write_items, items)
	if not ok then
		notify(window, "WezTerm fzf", "Could not prepare menu data.")
		wezterm.log_error(tostring(path))
		return
	end

	local script = options.project_dir .. "/scripts/fzf-menu.ps1"
	local spawned, tab, menu_pane = pcall(function()
		return window:mux_window():spawn_tab({
			cwd = options.projects,
			args = { "pwsh.exe", "-NoLogo", "-NoProfile", "-File", script },
			set_environment_variables = {
				WEZTERM_MENU_FILE = path,
				WEZTERM_MINMAX_VARIANT = active_minmax_variant(window, options),
			},
		})
	end)

	if not spawned or not menu_pane then
		os.remove(path)
		notify(window, "WezTerm fzf", "Could not start fzf. Check PowerShell, fzf and the script path.")
		wezterm.log_error("fzf tab launch failed: " .. tostring(tab))
		return
	end

	pending[menu_pane:pane_id()] = {
		target_pane_id = pane:pane_id(),
		items = items,
		temp_file = path,
	}
end

local function scrollback_items(pane, quick)
	local dimensions = pane:get_dimensions()
	local text = pane:get_logical_lines_as_text(dimensions.scrollback_rows)
	local items, seen = {}, {}

	local patterns = {
		"https?://[%w%._~:/%?#%[%]@!$&'()*+,;=%%%-]+",
		"%a:[/\\][%w_%.%-/\\]+",
		"/[%w_%.%-/]+",
		"[%w_%.%-]+/[%w_%.%-%/]+",
		"%x%x%x%x%x%x%x%x+",
		"%d+%.%d+%.%d+%.%d+",
	}

	local function push(value, line_number)
		value = value:gsub("[,;%)%]%}]+$", "")
		if value == "" then return end
		local key = value .. ":" .. line_number
		if seen[key] then return end
		seen[key] = true
		table.insert(items, {
			label = string.format("%05d / %s", line_number, value),
			id = "result:" .. #items + 1,
			value = value,
		})
	end

	for line_number, line in ipairs(wezterm.split_by_newlines(text)) do
		if quick then
			for _, pattern in ipairs(patterns) do
				for match in line:gmatch(pattern) do
					push(match, line_number)
				end
			end
		else
			push(line, line_number)
		end
	end
	return items
end

local function open_scrollback(window, pane, options, quick)
	local ok, items = pcall(scrollback_items, pane, quick)
	if not ok then
		notify(window, "WezTerm fzf", "Could not read scrollback. See the debug overlay.")
		wezterm.log_error("Scrollback extraction failed: " .. tostring(items))
		return
	end
	if #items == 0 then
		notify(window, "WezTerm fzf", "No matching scrollback entries.")
		return
	end
	open(window, pane, items, options)
end

local function set_override(window, key, value)
	local overrides = window:get_config_overrides() or {}
	overrides[key] = value
	window:set_config_overrides(overrides)
end

local function project_items(options)
	local ok, paths = pcall(wezterm.read_dir, options.projects)
	if not ok then
		error("Cannot read project directory " .. options.projects .. ": " .. tostring(paths))
	end

	local items = {}
	for _, path in ipairs(paths) do
		path = path:gsub("[/\\\\]+$", "")
		local name = path:match("([^/\\\\]+)$")
		if name and name:sub(1, 1) ~= "." then
			local is_directory = pcall(wezterm.read_dir, path)
			if is_directory then
				table.insert(items, {
					label = "Projects / " .. name,
					id = "project:open:" .. path,
				})
			end
		end
	end

	table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
	return items
end

local function open_projects(window, pane, options)
	local ok, items = pcall(project_items, options)
	if not ok then
		notify(window, "Project picker", tostring(items), 4000)
		wezterm.log_error("Project discovery failed: " .. tostring(items))
		return
	end
	if #items == 0 then
		notify(window, "Project picker", "No project directories found in " .. options.projects)
		return
	end
	open(window, pane, items, options)
end

local function open_schemes(window, pane, options)
	local schemes = wezterm.get_builtin_color_schemes()
	local names = {}
	for name in pairs(schemes) do table.insert(names, name) end
	for _, name in ipairs(CUSTOM_SCHEMES) do table.insert(names, name) end
	table.sort(names)

	local items = {}
	for _, name in ipairs(names) do
		table.insert(items, { label = "Color schemes / " .. name, id = "scheme:apply:" .. name })
	end
	open(window, pane, items, options)
end

local function open_fonts(window, pane, options)
	local fonts = {
		"ComicShannsMono Nerd Font",
		"JetBrainsMono Nerd Font",
		"CaskaydiaCove Nerd Font",
		"FiraCode Nerd Font",
		"Maple Mono NF",
		"Iosevka Nerd Font",
	}
	local items = {}
	for _, name in ipairs(fonts) do
		table.insert(items, { label = "Fonts / " .. name, id = "font:apply:" .. name })
	end
	open(window, pane, items, options)
end

local function prompt(window, pane, title, callback)
	window:perform_action(act.PromptInputLine({
		description = title,
		action = wezterm.action_callback(function(_, _, line)
			if line and line ~= "" then callback(line) end
		end),
	}), pane)
end

function M.setup(config, options)
	options = options or {}
	options.project_dir = assert(options.project_dir, "action_menu.setup requires project_dir")
	options.projects = assert(options.projects, "action_menu.setup requires projects")
	options.default_scheme = config.color_scheme or "Minmax Phosphor"

	wezterm.on("user-var-changed", function(window, menu_pane, name, value)
		if name ~= "WEZTERM_MENU_ACTION" then return end
		local menu_id = menu_pane:pane_id()
		local state = pending[menu_id]
		if not state then return end
		pending[menu_id] = nil

		local target = wezterm.mux.get_pane(state.target_pane_id)
		window:perform_action(act.CloseCurrentTab({ confirm = false }), menu_pane)
		if state.temp_file then os.remove(state.temp_file) end
		if not target or value == "cancel" then return end

		local ok, err = pcall(function()
			local index = tonumber(value:match("^result:(%d+)$"))
			if index and state.items[index] and state.items[index].value then
				local selected = state.items[index].value
				window:copy_to_clipboard(selected, "Clipboard")
				notify(window, "WezTerm fzf", "Copied: " .. selected, 1800)
			else
				dispatch.run(window, target, value, options, {
					open = open,
					open_projects = open_projects,
					open_schemes = open_schemes,
					open_fonts = open_fonts,
					open_scrollback = open_scrollback,
					set_override = set_override,
					prompt = prompt,
					notify = notify,
				})
			end
		end)
		if not ok then
			notify(window, "WezTerm fzf", "Action failed. See the debug overlay.", 4000)
			wezterm.log_error("fzf action failed: " .. tostring(err))
		end
	end)

	local function callback(builder)
		return wezterm.action_callback(builder)
	end

	local keys = {
		{ key = "X", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
		{ key = "P", mods = "CTRL|SHIFT", action = callback(function(w, p) open(w, p, registry.build(w, "all", shells.items), options) end) },
		{ key = "P", mods = "ALT|SHIFT", action = callback(function(w, p) open_projects(w, p, options) end) },
		{ key = "L", mods = "ALT|SHIFT", action = callback(function(w, p) open(w, p, registry.build(w, "shells", shells.items), options) end) },
		{ key = "F", mods = "CTRL|SHIFT", action = callback(function(w, p) open_scrollback(w, p, options, false) end) },
		{ key = "Space", mods = "CTRL|SHIFT", action = callback(function(w, p) open_scrollback(w, p, options, true) end) },
		{ key = "S", mods = "ALT|SHIFT", action = callback(function(w, p) open(w, p, registry.cheatsheet(), options) end) },
		{ key = "O", mods = "ALT|SHIFT", action = callback(function(w, p) open_schemes(w, p, options) end) },
		{ key = "D", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "R", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "T", mods = "ALT|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "W", mods = "ALT|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "C", mods = "ALT|SHIFT", action = act.ActivateCopyMode },
		{ key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
		{ key = "Enter", mods = "ALT|SHIFT", action = act.ToggleFullScreen },
		{ key = "UpArrow", mods = "ALT|SHIFT", action = act.ScrollByPage(-1) },
		{ key = "DownArrow", mods = "ALT|SHIFT", action = act.ScrollByPage(1) },
		{ key = "K", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackOnly") },
		{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
		{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
		{ key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
		{ key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
		{ key = "Z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
		{ key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	}
	config.keys = config.keys or {}
	for _, key in ipairs(keys) do table.insert(config.keys, key) end
end

return M
