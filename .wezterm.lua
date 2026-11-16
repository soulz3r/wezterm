local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local projects = "D:\\projects\\"

-- =========================================================
-- Action menu
-- =========================================================

local shells = {
	{
		label = "PowerShell",
		args = { "pwsh.exe", "-NoLogo" },
	},
	{
		label = "Command Prompt",
		args = { "cmd.exe" },
	},
	{
		label = "Arch Linux (WSL)",
		args = { "wsl.exe", "-d", "Arch" },
	},
}

local function shell_choices(mode)
	local choices = {}

	for _, shell in ipairs(shells) do
		table.insert(choices, {
			label = "Shells  /  " .. shell.label,
			id = "shell:" .. shell.label,
		})
	end

	return choices
end

local run_menu_action

local function open_menu(window, pane, mode)
	local choices = {}

	local function add(label, id)
		table.insert(choices, { label = label, id = id })
	end

	if mode == "shells" then
		choices = shell_choices(mode)
	else
		add("Shells       /  PowerShell", "shell:PowerShell")
		add("Shells       /  Command Prompt", "shell:Command Prompt")
		add("Shells       /  Arch Linux (WSL)", "shell:Arch Linux (WSL)")
		add("Shells       /  PowerShell in new window", "window:PowerShell")
		add("Shells       /  Arch Linux in new window", "window:Arch Linux (WSL)")
		add("Shells       /  PowerShell split", "split:PowerShell")
		add("Shells       /  Command Prompt split", "split:Command Prompt")
		add("Shells       /  Arch Linux split", "split:Arch Linux (WSL)")

		add("Tabs         /  Previous tab", "tab:previous")
		add("Tabs         /  Next tab", "tab:next")
		add("Tabs         /  Close current tab", "tab:close")

		add("Panes        /  Split right", "pane:split-right")
		add("Panes        /  Split down", "pane:split-down")
		add("Panes        /  Focus left", "pane:left")
		add("Panes        /  Focus right", "pane:right")
		add("Panes        /  Focus up", "pane:up")
		add("Panes        /  Focus down", "pane:down")
		add("Panes        /  Toggle zoom", "pane:zoom")
		add("Panes        /  Close current pane", "pane:close")

		add("Search       /  Search scrollback", "search")
		add("Search       /  Quick Select", "quick-select")

		add("Appearance   /  Increase font size", "font:increase")
		add("Appearance   /  Decrease font size", "font:decrease")
		add("Appearance   /  Reset font size", "font:reset")
		add("Window       /  Toggle fullscreen", "window:fullscreen")
		add("Configuration/  Reload config", "config:reload")
	end

	window:perform_action(
		act.InputSelector({
			title = mode == "shells" and "Shell picker" or "WezTerm",
			choices = choices,
			fuzzy = true,
			action = wezterm.action_callback(function(inner_window, inner_pane, id)
				run_menu_action(inner_window, inner_pane, id)
			end),
			description = "Type to filter  /  Enter to select  /  Esc to cancel",
		}),
		pane
	)
end

run_menu_action = function(window, pane, id)
	if not id then
		return
	end

	if id:match("^shell:") or id:match("^window:") or id:match("^split:") then
		local kind, name = id:match("^(%w+):(.+)$")
		local shell

		for _, candidate in ipairs(shells) do
			if candidate.label == name then
				shell = candidate
				break
			end
		end

		if not shell then
			return
		end

		local command = {
			args = shell.args,
			cwd = projects,
		}

		if kind == "shell" then
			window:perform_action(act.SpawnCommandInNewTab(command), pane)
		elseif kind == "window" then
			window:perform_action(act.SpawnCommandInNewWindow(command), pane)
		elseif kind == "split" then
			window:perform_action(
				act.SplitPane({
					direction = "Right",
					size = { Percent = 50 },
					command = command,
				}),
				pane
			)
		end
		return
	end

	local actions = {
		["tab:previous"] = act.ActivateTabRelative(-1),
		["tab:next"] = act.ActivateTabRelative(1),
		["tab:close"] = act.CloseCurrentTab({ confirm = true }),

		["pane:split-right"] = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		["pane:split-down"] = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		["pane:left"] = act.ActivatePaneDirection("Left"),
		["pane:right"] = act.ActivatePaneDirection("Right"),
		["pane:up"] = act.ActivatePaneDirection("Up"),
		["pane:down"] = act.ActivatePaneDirection("Down"),
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

	local selected_action = actions[id]
	if selected_action then
		window:perform_action(selected_action, pane)
	end
end

local function menu_action(mode)
	return wezterm.action_callback(function(window, pane)
		open_menu(window, pane, mode)
	end)
end

-- InputSelector is WezTerm's native fuzzy selector. It runs inside the GUI,
-- so actions stay in Lua and no helper shell or temporary menu tab is needed.
wezterm.on("wezterm-action-menu", function(window, pane, id)
	run_menu_action(window, pane, id)
end)

-- =========================================================
-- Shell
-- =========================================================

config.default_prog = { "pwsh.exe", "-NoLogo" }
config.default_cwd = projects

-- =========================================================
-- Appearance
-- =========================================================

config.color_scheme = "Everforest Dark (Gogh)"
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85

-- Optional Windows 11 acrylic backdrop
-- config.win32_system_backdrop = "Acrylic"

config.initial_cols = 100
config.initial_rows = 45

config.window_padding = {
	left = 12,
	right = 12,
	top = 12,
	bottom = 0,
}

config.enable_tab_bar = false
config.enable_scroll_bar = false
config.hide_mouse_cursor_when_typing = true

-- =========================================================
-- Font
-- =========================================================

config.font = wezterm.font("ComicShannsMono Nerd Font")
config.font_size = 10

-- =========================================================
-- Terminal behavior
-- =========================================================

config.scrollback_lines = 10000
config.scroll_to_bottom_on_input = true
config.audible_bell = "Disabled"
config.warn_about_missing_glyphs = true

config.automatically_reload_config = true
config.window_close_confirmation = "AlwaysPrompt"
config.adjust_window_size_when_changing_font_size = false

-- =========================================================
-- Cursor
-- =========================================================

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- =========================================================
-- Mouse
-- =========================================================

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Up = { streak = 2, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("Clipboard"),
	},
	{
		event = { Up = { streak = 3, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("Clipboard"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = act.CompleteSelection("Clipboard"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "ALT",
		action = act.CompleteSelection("Clipboard"),
	},
}

-- =========================================================
-- Keyboard shortcuts
-- =========================================================

config.keys = {
	{
		key = "X",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = act.InputSelector({
			title = "WezTerm",
			choices = {
				{ label = "Open action menu", id = "all" },
				{ label = "Open shell picker", id = "shells" },
			},
			fuzzy = true,
			action = wezterm.action_callback(function(window, pane, id)
				if id then
					open_menu(window, pane, id)
				end
			end),
		}),
	},
	{
		key = "L",
		mods = "ALT|SHIFT",
		action = menu_action("shells"),
	},
	{
		key = "F",
		mods = "CTRL|SHIFT",
		action = act.Search({ CaseSensitiveString = "" }),
	},
	{
		key = "Space",
		mods = "CTRL|SHIFT",
		action = act.QuickSelect,
	},
	{
		key = "D",
		mods = "ALT|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "R",
		mods = "ALT|SHIFT",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "CTRL|SHIFT",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "Z",
		mods = "CTRL|SHIFT",
		action = act.TogglePaneZoomState,
	},
}

config.keys[2].action = menu_action("all")

return config
