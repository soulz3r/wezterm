local wezterm = require("wezterm")
local config = wezterm.config_builder()

local project_dir = "D:/config/wezterm"
local projects = "D:/projects"

config.default_prog = { "pwsh.exe", "-NoLogo" }
config.default_cwd = projects

config.color_scheme = "Everforest Dark (Gogh)"
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85
config.initial_cols = 100
config.initial_rows = 45
config.window_padding = { left = 12, right = 12, top = 12, bottom = 0 }
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.hide_mouse_cursor_when_typing = true

config.font = wezterm.font("ComicShannsMono Nerd Font")
config.font_size = 10

config.scrollback_lines = 10000
config.scroll_to_bottom_on_input = true
config.audible_bell = "Disabled"
config.warn_about_missing_glyphs = true
config.automatically_reload_config = true
config.window_close_confirmation = "AlwaysPrompt"
config.adjust_window_size_when_changing_font_size = false

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.mouse_bindings = require("config.mouse")

require("features.action_menu").setup(config, {
	projects = projects,
	project_dir = project_dir,
})

return config
