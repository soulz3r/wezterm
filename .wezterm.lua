local wezterm = require("wezterm")
local config = wezterm.config_builder()

local action_menu_path = wezterm.config_dir .. "/scripts/action-menu.ps1"
local wezterm_exe = wezterm.executable_dir .. "\\wezterm.exe"

local function open_action_menu(window, pane, mode)
	window:spawn_tab({
		args = {
			"pwsh.exe",
			"-NoLogo",
			"-NoProfile",
			"-File",
			action_menu_path,
			tostring(pane:pane_id()),
			mode or "all",
			wezterm_exe,
		},
		cwd = "D:\\projects\\",
	})
end

-- =========================================================
-- Shell
-- =========================================================

config.default_prog = { "pwsh.exe", "-NoLogo" }
config.default_cwd = "D:\\projects\\"

-- Shells are launched through the fzf action menu.

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
	-- Select text and copy to Windows clipboard.
	-- If no selection is active, hyperlinks can still open.
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
	},

	-- Preserve hyperlink opening with Ctrl + click.
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},

	-- Double-click: select and copy a word.
	{
		event = { Up = { streak = 2, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("Clipboard"),
	},

	-- Triple-click: select and copy a line.
	{
		event = { Up = { streak = 3, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("Clipboard"),
	},

	-- Complete Shift-extended selections.
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = wezterm.action.CompleteSelection("Clipboard"),
	},

	-- Complete rectangular selections.
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "ALT",
		action = wezterm.action.CompleteSelection("Clipboard"),
	},
}

-- =========================================================
-- Keyboard shortcuts
-- =========================================================

config.keys = {
	-- Disable accidental copy mode.
	{
		key = "X",
		mods = "CTRL|SHIFT",
		action = wezterm.action.DisableDefaultAssignment,
	},

	-- Main fzf action menu.
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			open_action_menu(window, pane, "all")
		end),
	},

	-- Shell-only fzf picker.
	{
		key = "L",
		mods = "ALT|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			open_action_menu(window, pane, "shells")
		end),
	},

	-- Native terminal search.
	{
		key = "F",
		mods = "CTRL|SHIFT",
		action = wezterm.action.Search({
			CaseSensitiveString = "",
		}),
	},

	-- Native Quick Select.
	{
		key = "Space",
		mods = "CTRL|SHIFT",
		action = wezterm.action.QuickSelect,
	},

	-- Split pane vertically.
	{
		key = "D",
		mods = "ALT|SHIFT",
		action = wezterm.action.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Split pane horizontally.
	{
		key = "R",
		mods = "ALT|SHIFT",
		action = wezterm.action.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Navigate between panes.
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},

	-- Zoom/unzoom current pane.
	{
		key = "Z",
		mods = "CTRL|SHIFT",
		action = wezterm.action.TogglePaneZoomState,
	},
}

return config
