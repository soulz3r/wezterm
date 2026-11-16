local wezterm = require("wezterm")
local act = wezterm.action
local registry = require("features.action_registry")

local M = {}
local pending = {}

local PROJECTS = "D:/projects"
local DEFAULT_SCHEME = "Everforest Dark (Gogh)"
local DEFAULT_OPACITY = 0.85

local SHELLS = {
	{ name = "PowerShell", args = { "pwsh.exe", "-NoLogo" } },
	{ name = "Command Prompt", args = { "cmd.exe" } },
	{ name = "Arch Linux (WSL)", args = { "wsl.exe", "-d", "Arch" } },
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
		file:write(wezterm.json_encode(items))
		file:close()
	end)
	if not ok then
		pcall(function() file:close() end)
		os.remove(path)
		error("Cannot write fzf menu data: " .. tostring(write_err))
	end
	return path
end

local function find_shell(name)
	for _, shell in ipairs(SHELLS) do
		if shell.name == name then
			return shell
		end
	end
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
			set_environment_variables = { WEZTERM_MENU_FILE = path },
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

local function open_schemes(window, pane, options)
	local schemes = wezterm.get_builtin_color_schemes()
	local names = {}
	for name in pairs(schemes) do table.insert(names, name) end
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

local function dispatch(window, pane, id, options)
	if not id or id == "cancel" then return end

	local result_index = tonumber(id:match("^result:(%d+)$"))
	if result_index then return end

	if id == "menu" then
		open(window, pane, registry.build(window, "all"), options)
		return
	elseif id == "shell-picker" then
		open(window, pane, registry.build(window, "shells"), options)
		return
	elseif id == "cheatsheet" then
		open(window, pane, registry.cheatsheet(), options)
		return
	elseif id == "scheme:picker" then
		open_schemes(window, pane, options)
		return
	elseif id == "font:picker" then
		open_fonts(window, pane, options)
		return
	elseif id == "search:fzf" or id == "search:quick" then
		open_scrollback(window, pane, options, id == "search:quick")
		return
	end

	local placement, shell_name = id:match("^shell:([^:]+):(.+)$")
	if placement then
		local shell = find_shell(shell_name)
		if not shell then return end
		local command = { args = shell.args, cwd = options.projects }
		if placement == "tab" then
			window:perform_action(act.SpawnCommandInNewTab(command), pane)
		elseif placement == "window" then
			window:perform_action(act.SpawnCommandInNewWindow(command), pane)
		elseif placement == "split" then
			window:perform_action(act.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
				command = command,
			}), pane)
		end
		return
	end

	if id:match("^scheme:apply:") then
		set_override(window, "color_scheme", id:sub(14))
		return
	elseif id == "scheme:default" then
		set_override(window, "color_scheme", DEFAULT_SCHEME)
		return
	elseif id:match("^font:apply:") then
		set_override(window, "font", wezterm.font(id:sub(12)))
		return
	elseif id == "appearance:opacity" then
		local current = (window:get_config_overrides() or {}).window_background_opacity
		set_override(window, "window_background_opacity", current == 1.0 and DEFAULT_OPACITY or 1.0)
		return
	elseif id == "appearance:tab-bar" then
		local current = (window:get_config_overrides() or {}).enable_tab_bar
		set_override(window, "enable_tab_bar", current ~= true)
		return
	elseif id == "appearance:scrollbar" then
		local current = (window:get_config_overrides() or {}).enable_scroll_bar
		set_override(window, "enable_scroll_bar", not (current == nil and false or current))
		return
	elseif id == "appearance:cursor" then
		local current = (window:get_config_overrides() or {}).default_cursor_style or "BlinkingBar"
		set_override(window, "default_cursor_style", current == "BlinkingBar" and "SteadyBar" or "BlinkingBar")
		return
	end

	if id == "workspace:create" then
		prompt(window, pane, "Create workspace", function(name)
			window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
		end)
		return
	elseif id == "workspace:rename" then
		prompt(window, pane, "Rename current workspace", function(name)
			wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), name)
		end)
		return
	elseif id:match("^workspace:switch:") then
		window:perform_action(act.SwitchToWorkspace({ name = id:sub(18) }), pane)
		return
	elseif id == "tab:rename" then
		prompt(window, pane, "Rename current tab", function(name)
			pane:tab():set_title(name)
		end)
		return
	end

	local direct = {
		["tab:new"] = act.SpawnTab("CurrentPaneDomain"),
		["tab:previous"] = act.ActivateTabRelative(-1),
		["tab:next"] = act.ActivateTabRelative(1),
		["tab:move-left"] = act.MoveTabRelative(-1),
		["tab:move-right"] = act.MoveTabRelative(1),
		["tab:close"] = act.CloseCurrentTab({ confirm = true }),
		["tab:navigator"] = act.ShowTabNavigator,
		["pane:split:right"] = act.SplitPane({ direction = "Right", size = { Percent = 50 } }),
		["pane:split:down"] = act.SplitPane({ direction = "Bottom", size = { Percent = 50 } }),
		["pane:select"] = act.PaneSelect,
		["pane:zoom"] = act.TogglePaneZoomState,
		["pane:close"] = act.CloseCurrentPane({ confirm = true }),
		["search:native"] = act.Search({ CaseSensitiveString = "" }),
		["copy-mode"] = act.ActivateCopyMode,
		["clipboard:copy"] = act.CopyTo("Clipboard"),
		["clipboard:paste"] = act.PasteFrom("Clipboard"),
		["clipboard:clear"] = act.ClearSelection,
		["scroll:top"] = act.ScrollToTop,
		["scroll:bottom"] = act.ScrollToBottom,
		["scroll:page-up"] = act.ScrollByPage(-1),
		["scroll:page-down"] = act.ScrollByPage(1),
		["scroll:clear"] = act.ClearScrollback("ScrollbackOnly"),
		["font:increase"] = act.IncreaseFontSize,
		["font:decrease"] = act.DecreaseFontSize,
		["font:reset"] = act.ResetFontSize,
		["window:fullscreen"] = act.ToggleFullScreen,
		["debug"] = act.ShowDebugOverlay,
		["config:reload"] = act.ReloadConfiguration,
	}
	local action = direct[id]
	if action then
		window:perform_action(action, pane)
	elseif id:match("^tab:activate:") then
		local index = tonumber(id:match("(%d+)$"))
		if index then window:perform_action(act.ActivateTab(index - 1), pane) end
	elseif id == "pane:rotate-clockwise" or id == "pane:rotate-counter-clockwise" then
		if wezterm.has_action("RotatePanes") then
			window:perform_action(act.RotatePanes(id == "pane:rotate-clockwise" and "Clockwise" or "CounterClockwise"), pane)
		end
	elseif id:match("^pane:resize:") then
		local direction = id:match("([^:]+)$")
		if wezterm.has_action("AdjustPaneSize") then
			window:perform_action(act.AdjustPaneSize({ direction, 5 }), pane)
		end
	elseif id == "docs" then
		wezterm.open_with("https://wezterm.org/")
	end
end

function M.setup(config, options)
	options = options or {}
	options.project_dir = assert(options.project_dir, "action_menu.setup requires project_dir")
	options.projects = options.projects or PROJECTS

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
				dispatch(window, target, value, options)
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
		{ key = "P", mods = "CTRL|SHIFT", action = callback(function(w, p) open(w, p, registry.build(w, "all"), options) end) },
		{ key = "L", mods = "ALT|SHIFT", action = callback(function(w, p) open(w, p, registry.build(w, "shells"), options) end) },
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
