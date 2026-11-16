local wezterm = require("wezterm")
local act = wezterm.action

local M = {}
local pending = {}

local shells = {
	{ name = "PowerShell", args = { "pwsh.exe", "-NoLogo" } },
	{ name = "Command Prompt", args = { "cmd.exe" } },
	{ name = "Arch Linux (WSL)", args = { "wsl.exe", "-d", "Arch" } },
}

local function add(items, label, id)
	table.insert(items, { label = label, id = id })
end

local function build_choices(window, mode)
	local items = {}

	for _, shell in ipairs(shells) do
		add(items, "Shells     /  " .. shell.name .. " in new tab", "shell:tab:" .. shell.name)
		if mode == "all" then
			add(items, "Shells     /  " .. shell.name .. " in new window", "shell:window:" .. shell.name)
			add(items, "Shells     /  " .. shell.name .. " in split pane", "shell:split:" .. shell.name)
		end
	end

	if mode == "shells" then
		return items
	end

	add(items, "Tabs       /  New tab", "tab:new")
	add(items, "Tabs       /  Previous tab", "tab:previous")
	add(items, "Tabs       /  Next tab", "tab:next")
	add(items, "Tabs       /  Close current tab", "tab:close")

	for index, tab in ipairs(window:mux_window():tabs()) do
		local panes = tab:panes()
		local title = panes[1] and panes[1]:get_title() or ("Tab " .. index)
		add(items, string.format("Tabs       /  Switch to %02d  %s", index, title), "tab:activate:" .. index)
	end

	add(items, "Panes      /  Split right", "pane:split:right")
	add(items, "Panes      /  Split down", "pane:split:down")
	add(items, "Panes      /  Focus left", "pane:focus:left")
	add(items, "Panes      /  Focus right", "pane:focus:right")
	add(items, "Panes      /  Focus up", "pane:focus:up")
	add(items, "Panes      /  Focus down", "pane:focus:down")
	add(items, "Panes      /  Toggle zoom", "pane:zoom")
	add(items, "Panes      /  Close current pane", "pane:close")

	add(items, "Search     /  Search scrollback", "search")
	add(items, "Search     /  Quick Select", "quick-select")
	add(items, "Appearance /  Increase font size", "font:increase")
	add(items, "Appearance /  Decrease font size", "font:decrease")
	add(items, "Appearance /  Reset font size", "font:reset")
	add(items, "Window     /  Toggle fullscreen", "window:fullscreen")
	add(items, "Config     /  Reload configuration", "config:reload")

	for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
		add(items, "Workspaces /  Switch to " .. workspace, "workspace:" .. workspace)
	end

	return items
end

local function find_shell(name)
	for _, shell in ipairs(shells) do
		if shell.name == name then
			return shell
		end
	end
end

local function resolve_action(window, pane, id, options)
	if not id or id == "cancel" then
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
			window:perform_action(act.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
				command = command,
			}), pane)
		end
		return
	end

	if kind == "workspace" then
		window:perform_action(act.SwitchToWorkspace({ name = rest }), pane)
		return
	end

	if kind == "tab" then
		if rest == "new" then
			window:perform_action(act.SpawnTab("CurrentPaneDomain"), pane)
		elseif rest == "previous" then
			window:perform_action(act.ActivateTabRelative(-1), pane)
		elseif rest == "next" then
			window:perform_action(act.ActivateTabRelative(1), pane)
		elseif rest == "close" then
			window:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
		else
			local index = tonumber(rest:match("^activate:(%d+)$"))
			if index then
				window:perform_action(act.ActivateTab(index - 1), pane)
			end
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
		["pane:zoom"] = act.TogglePaneZoomState,
		["pane:close"] = act.CloseCurrentPane({ confirm = true }),
		["search"] = act.Search({ CaseSensitiveString = "" }),
		["quick-select"] = act.QuickSelect,
		["font:increase"] = act.IncreaseFontSize,
		["font:decrease"] = act.DecreaseFontSize,
		["font:reset"] = act.ResetFontSize,
		["window:fullscreen"] = act.ToggleFullScreen,
		["config:reload"] = act.ReloadConfiguration,
	}

	local action = actions[id]
	if action then
		window:perform_action(action, pane)
	end
end

local function open(window, pane, mode, options)
	local items = build_choices(window, mode)
	local script = options.project_dir .. "/scripts/fzf-menu.ps1"
	local _, menu_pane = window:mux_window():spawn_tab({
		cwd = options.projects,
		args = { "pwsh.exe", "-NoLogo", "-NoProfile", "-File", script },
		set_environment_variables = {
			WEZTERM_MENU_ITEMS = wezterm.json_encode(items),
			WEZTERM_MENU_TARGET = tostring(pane:pane_id()),
		},
	})
	pending[menu_pane:pane_id()] = pane:pane_id()
end

function M.setup(config, options)
	options = options or {}

	wezterm.on("user-var-changed", function(window, menu_pane, name, value)
		if name ~= "WEZTERM_MENU_ACTION" then return end

		local menu_id = menu_pane:pane_id()
		local target_id = pending[menu_id]
		if not target_id then return end
		pending[menu_id] = nil

		local target_pane = wezterm.mux.get_pane(target_id)
		window:perform_action(act.CloseCurrentTab({ confirm = false }), menu_pane)
		if target_pane and value ~= "cancel" then
			resolve_action(window, target_pane, value, options)
		end
	end)

	config.keys = {
		{ key = "X", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
		{
			key = "P",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				open(window, pane, "all", options)
			end),
		},
		{
			key = "L",
			mods = "ALT|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				open(window, pane, "shells", options)
			end),
		},
		{ key = "F", mods = "CTRL|SHIFT", action = act.Search({ CaseSensitiveString = "" }) },
		{ key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect },
		{ key = "D", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "R", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
		{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
		{ key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
		{ key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
		{ key = "Z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
	}
end

return M
