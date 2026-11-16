local wezterm = require("wezterm")
local act = wezterm.action

local M = {}
local pending = {}

local shells = {
	{ name = "PowerShell", args = { "pwsh.exe", "-NoLogo" } },
	{ name = "Command Prompt", args = { "cmd.exe" } },
	{ name = "Arch Linux (WSL)", args = { "wsl.exe", "-d", "Arch" } },
}

local default_scheme = "Everforest Dark (Gogh)"

local function add(items, label, id)
	table.insert(items, { label = label, id = id })
end

local function write_items(items)
	local path = os.tmpname()
	local file = assert(io.open(path, "w"))
	file:write(wezterm.json_encode(items))
	file:close()
	return path
end

local function add_shells(items, mode)
	for _, shell in ipairs(shells) do
		add(items, "Shells / " .. shell.name .. " / New tab", "shell:tab:" .. shell.name)
		if mode == "all" then
			add(items, "Shells / " .. shell.name .. " / New window", "shell:window:" .. shell.name)
			add(items, "Shells / " .. shell.name .. " / Split pane", "shell:split:" .. shell.name)
		end
	end
end

local function add_tabs(items, window)
	add(items, "Tabs / New tab                         [Alt+Shift+T]", "tab:new")
	add(items, "Tabs / Previous tab                    [Ctrl+PageUp]", "tab:previous")
	add(items, "Tabs / Next tab                        [Ctrl+PageDown]", "tab:next")
	add(items, "Tabs / Move tab left                   [Ctrl+Shift+PageUp]", "tab:move-left")
	add(items, "Tabs / Move tab right                  [Ctrl+Shift+PageDown]", "tab:move-right")
	add(items, "Tabs / Close current tab                [Alt+Shift+W]", "tab:close")
	add(items, "Tabs / Show tab navigator", "tab:navigator")

	for index, tab in ipairs(window:mux_window():tabs()) do
		local panes = tab:panes()
		local title = panes[1] and panes[1]:get_title() or ("Tab " .. index)
		add(items, string.format("Tabs / Switch to %02d / %s", index, title), "tab:activate:" .. index)
	end
end

local function add_panes(items)
	add(items, "Panes / Split right                    [Alt+Shift+D]", "pane:split:right")
	add(items, "Panes / Split down                     [Alt+Shift+R]", "pane:split:down")
	add(items, "Panes / Focus left                    [Ctrl+Shift+Left]", "pane:focus:left")
	add(items, "Panes / Focus right                   [Ctrl+Shift+Right]", "pane:focus:right")
	add(items, "Panes / Focus up                      [Ctrl+Shift+Up]", "pane:focus:up")
	add(items, "Panes / Focus down                    [Ctrl+Shift+Down]", "pane:focus:down")
	add(items, "Panes / Next pane", "pane:focus:next")
	add(items, "Panes / Previous pane", "pane:focus:previous")
	add(items, "Panes / Toggle zoom                   [Ctrl+Shift+Z]", "pane:zoom")
	add(items, "Panes / Close current pane", "pane:close")
	add(items, "Panes / Rotate panes clockwise", "pane:rotate")
	add(items, "Panes / Select pane", "pane:select")
end

local function add_actions(items, mode)
	add(items, "Search / Search scrollback with fzf    [Ctrl+Shift+F]", "search:fzf")
	add(items, "Search / Quick Select with fzf         [Ctrl+Shift+Space]", "search:quick")
	add(items, "Search / Native WezTerm search", "search:native")
	add(items, "Search / Copy mode                    [Alt+Shift+C]", "copy-mode")
	add(items, "Clipboard / Copy selection             [Ctrl+Shift+C]", "clipboard:copy")
	add(items, "Clipboard / Paste                     [Ctrl+Shift+V]", "clipboard:paste")
	add(items, "Clipboard / Clear selection", "clipboard:clear")
	add(items, "Scrollback / Scroll to top", "scroll:top")
	add(items, "Scrollback / Scroll to bottom", "scroll:bottom")
	add(items, "Scrollback / Page up                  [Alt+Shift+Up]", "scroll:page-up")
	add(items, "Scrollback / Page down                [Alt+Shift+Down]", "scroll:page-down")
	add(items, "Scrollback / Clear scrollback         [Ctrl+Shift+K]", "scroll:clear")
	add(items, "Appearance / Increase font size", "font:increase")
	add(items, "Appearance / Decrease font size", "font:decrease")
	add(items, "Appearance / Reset font size", "font:reset")
	add(items, "Appearance / Choose color scheme      [Alt+Shift+O]", "scheme:picker")
	add(items, "Appearance / Restore default scheme", "scheme:default")
	add(items, "Window / Toggle fullscreen             [Alt+Shift+Enter]", "window:fullscreen")
	add(items, "Window / Toggle always on top", "window:top")
	add(items, "Window / Toggle always on bottom", "window:bottom")
	add(items, "Window / Maximize", "window:maximize")
	add(items, "Window / Restore", "window:restore")
	add(items, "Window / Show debug overlay", "debug")
	add(items, "Config / Reload configuration          [Ctrl+Shift+R]", "config:reload")
	add(items, "Config / Cheat sheet                   [Alt+Shift+S]", "cheatsheet")
	add(items, "Config / Open WezTerm documentation", "docs")
end

local function build_choices(window, mode)
	local items = {}
	add_shells(items, mode)
	if mode == "shells" then return items end

	add_tabs(items, window)
	add_panes(items)
	add_actions(items, mode)

	for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
		add(items, "Workspaces / Switch to " .. workspace, "workspace:" .. workspace)
	end

	return items
end

local function build_cheatsheet()
	local items = {}
	local rows = {
		{ "Ctrl+Shift+P", "Open the complete fzf action menu", "menu" },
		{ "Ctrl+Shift+F", "Search scrollback with fzf", "search:fzf" },
		{ "Ctrl+Shift+Space", "Quick Select matches with fzf", "search:quick" },
		{ "Alt+Shift+S", "Open this cheat sheet", "cheatsheet" },
		{ "Alt+Shift+O", "Choose a color scheme", "scheme:picker" },
		{ "Alt+Shift+L", "Open shell picker", "shell-picker" },
		{ "Alt+Shift+D", "Split pane right", "pane:split:right" },
		{ "Alt+Shift+R", "Split pane down", "pane:split:down" },
		{ "Ctrl+Shift+Arrow", "Move focus between panes", "pane:focus:left" },
		{ "Ctrl+Shift+Z", "Toggle pane zoom", "pane:zoom" },
		{ "Alt+Shift+T", "Open a new tab", "tab:new" },
		{ "Alt+Shift+W", "Close current tab", "tab:close" },
		{ "Ctrl+Shift+C", "Copy selection", "clipboard:copy" },
		{ "Ctrl+Shift+V", "Paste clipboard", "clipboard:paste" },
		{ "Alt+Shift+C", "Enter keyboard copy mode", "copy-mode" },
		{ "Alt+Shift+Up", "Scroll one page up", "scroll:page-up" },
		{ "Alt+Shift+Down", "Scroll one page down", "scroll:page-down" },
		{ "Ctrl+Shift+K", "Clear scrollback", "scroll:clear" },
		{ "Alt+Shift+Enter", "Toggle fullscreen", "window:fullscreen" },
		{ "Ctrl+Shift+R", "Reload configuration", "config:reload" },
	}
	for _, row in ipairs(rows) do
		add(items, string.format("Keymaps / %-22s / %s", row[1], row[2]), row[3])
	end
	return items
end

local function build_scrollback_results(pane, quick)
	local text = pane:get_logical_lines_as_text(pane:get_dimensions().scrollback_rows)
	local results = {}
	local seen = {}
	local patterns = {
		"https?://[%w%._~:/%?#%[%]@!$&'()*+,;=%%%-]+",
		"[%w_%.%-]+/[%w_%.%-%/]+",
		"%x%x%x%x%x%x%x%x+",
		"%d+%.%d+%.%d+%.%d+",
		"%d+",
	}
	local function push(value, line_number)
		value = value:gsub("^%s+", ""):gsub("%s+$", "")
		if value == "" then return end
		local key = value .. ":" .. line_number
		if seen[key] then return end
		seen[key] = true
		add(results, string.format("%05d / %s", line_number, value), "result:" .. #results + 1)
		results[#results].value = value
	end

	for line_number, line in ipairs(wezterm.split_by_newlines(text)) do
		if quick then
			for _, pattern in ipairs(patterns) do
				for match in line:gmatch(pattern) do push(match, line_number) end
			end
		else
			push(line, line_number)
		end
	end
	return results
end

local function find_shell(name)
	for _, shell in ipairs(shells) do
		if shell.name == name then return shell end
	end
end

local function open(window, pane, items, options, metadata)
	local path = write_items(items)
	local script = options.project_dir .. "/scripts/fzf-menu.ps1"
	local _, menu_pane = window:mux_window():spawn_tab({
		cwd = options.projects,
		args = { "pwsh.exe", "-NoLogo", "-NoProfile", "-File", script },
		set_environment_variables = {
			WEZTERM_MENU_FILE = path,
		},
	})
	pending[menu_pane:pane_id()] = {
		target = pane:pane_id(),
		items = items,
		temp_file = path,
		metadata = metadata,
	}
end

local function open_scrollback(window, pane, options, quick)
	local items = build_scrollback_results(pane, quick)
	if #items == 0 then
		window:toast_notification("WezTerm fzf", "No matching text found in scrollback.", nil, 2500)
		return
	end
	open(window, pane, items, options, { result_mode = true, quick = quick })
end

local function open_schemes(window, pane, options)
	local items = {}
	local schemes = wezterm.get_builtin_color_schemes()
	local names = {}
	for name in pairs(schemes) do table.insert(names, name) end
	table.sort(names)
	for _, name in ipairs(names) do
		add(items, "Color schemes / " .. name, "scheme:apply:" .. name)
	end
	open(window, pane, items, options)
end

local function resolve_action(window, pane, id, options)
	if not id or id == "cancel" then return end

	if id:match("^result:") then
		return
	end

	if id == "menu" then
		open(window, pane, build_choices(window, "all"), options)
		return
	elseif id == "shell-picker" then
		open(window, pane, build_choices(window, "shells"), options)
		return
	elseif id == "cheatsheet" then
		open(window, pane, build_cheatsheet(), options)
		return
	elseif id == "scheme:picker" then
		open_schemes(window, pane, options)
		return
	end

	local kind, rest = id:match("^([^:]+):(.+)$")

	if kind == "shell" then
		local placement, name = rest:match("^([^:]+):(.+)$")
		local shell = find_shell(name)
		if not shell then return end
		local command = { args = shell.args, cwd = options.projects }
		if placement == "tab" then
			window:perform_action(act.SpawnCommandInNewTab(command), pane)
		elseif placement == "window" then
			window:perform_action(act.SpawnCommandInNewWindow(command), pane)
		elseif placement == "split" then
			window:perform_action(act.SplitPane({ direction = "Right", size = { Percent = 50 }, command = command }), pane)
		end
		return
	end

	if kind == "workspace" then
		window:perform_action(act.SwitchToWorkspace({ name = rest }), pane)
		return
	elseif kind == "scheme" then
		if rest == "default" then
			window:set_config_overrides({ color_scheme = default_scheme })
		elseif rest:match("^apply:") then
			window:set_config_overrides({ color_scheme = rest:sub(7) })
		end
		return
	elseif kind == "tab" then
		if rest == "new" then
			window:perform_action(act.SpawnTab("CurrentPaneDomain"), pane)
		elseif rest == "previous" then
			window:perform_action(act.ActivateTabRelative(-1), pane)
		elseif rest == "next" then
			window:perform_action(act.ActivateTabRelative(1), pane)
		elseif rest == "close" then
			window:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
		elseif rest == "navigator" then
			window:perform_action(act.ShowTabNavigator, pane)
		elseif rest == "move-left" then
			window:perform_action(act.MoveTabRelative(-1), pane)
		elseif rest == "move-right" then
			window:perform_action(act.MoveTabRelative(1), pane)
		else
			local index = tonumber(rest:match("^activate:(%d+)$"))
			if index then window:perform_action(act.ActivateTab(index - 1), pane) end
		end
		return
	end

	local actions = {
		["pane:split:right"] = act.SplitPane({ direction = "Right", size = { Percent = 50 } }),
		["pane:split:down"] = act.SplitPane({ direction = "Bottom", size = { Percent = 50 } }),
		["pane:focus:left"] = act.ActivatePaneDirection("Left"),
		["pane:focus:right"] = act.ActivatePaneDirection("Right"),
		["pane:focus:up"] = act.ActivatePaneDirection("Up"),
		["pane:focus:down"] = act.ActivatePaneDirection("Down"),
		["pane:focus:next"] = act.ActivatePaneDirection("Next"),
		["pane:focus:previous"] = act.ActivatePaneDirection("Prev"),
		["pane:zoom"] = act.TogglePaneZoomState,
		["pane:close"] = act.CloseCurrentPane({ confirm = true }),
		["pane:rotate"] = act.RotatePanes("Clockwise"),
		["pane:select"] = act.PaneSelect,
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
		["window:top"] = act.ToggleAlwaysOnTop,
		["window:bottom"] = act.ToggleAlwaysOnBottom,
		["window:maximize"] = act.EmitEvent("wezterm-maximize"),
		["window:restore"] = act.EmitEvent("wezterm-restore"),
		["debug"] = act.ShowDebugOverlay,
		["config:reload"] = act.ReloadConfiguration,
	}

	if id == "docs" then
		wezterm.open_with("https://wezterm.org")
		return
	end

	local action = actions[id]
	if action then window:perform_action(action, pane) end
end

function M.setup(config, options)
	options = options or {}

	wezterm.on("wezterm-maximize", function(window) window:maximize() end)
	wezterm.on("wezterm-restore", function(window) window:restore() end)

	wezterm.on("user-var-changed", function(window, menu_pane, name, value)
		if name ~= "WEZTERM_MENU_ACTION" then return end
		local menu_id = menu_pane:pane_id()
		local state = pending[menu_id]
		if not state then return end
		pending[menu_id] = nil

		local target_pane = wezterm.mux.get_pane(state.target)
		window:perform_action(act.CloseCurrentTab({ confirm = false }), menu_pane)

		if state.temp_file then os.remove(state.temp_file) end
		if not target_pane or value == "cancel" then return end

		local index = tonumber(value:match("^result:(%d+)$"))
		if index and state.items[index] and state.items[index].value then
			window:copy_to_clipboard(state.items[index].value, "Clipboard")
			window:toast_notification("WezTerm fzf", "Copied: " .. state.items[index].value, nil, 1800)
			return
		end

		if value == "search:fzf" or value == "search:quick" then
			open_scrollback(window, target_pane, options, value == "search:quick")
		else
			resolve_action(window, target_pane, value, options)
		end
	end)

	config.keys = {
		{ key = "X", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
		{ key = "P", mods = "CTRL|SHIFT", action = wezterm.action_callback(function(w, p) open(w, p, build_choices(w, "all"), options) end) },
		{ key = "L", mods = "ALT|SHIFT", action = wezterm.action_callback(function(w, p) open(w, p, build_choices(w, "shells"), options) end) },
		{ key = "F", mods = "CTRL|SHIFT", action = wezterm.action_callback(function(w, p) open_scrollback(w, p, options, false) end) },
		{ key = "Space", mods = "CTRL|SHIFT", action = wezterm.action_callback(function(w, p) open_scrollback(w, p, options, true) end) },
		{ key = "S", mods = "ALT|SHIFT", action = wezterm.action_callback(function(w, p) open(w, p, build_cheatsheet(), options) end) },
		{ key = "O", mods = "ALT|SHIFT", action = wezterm.action_callback(function(w, p) open_schemes(w, p, options) end) },
		{ key = "D", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "R", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
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
end

return M
