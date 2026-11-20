local wezterm = require("wezterm")
local config = wezterm.config_builder()

config:set_strict_mode(true)

local project_dir = "D:/config/wezterm"
local projects = "D:/projects"

config.default_prog = {
	"C:/Program Files/Git/bin/bash.exe",
	"--rcfile",
	"/d/config/bash/.bashrc",
	"-i",
}
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

config.animation_fps = 60
config.max_fps = 75

-- Block by default; applications such as Vim can change the shape with DECSCUSR.
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 650
config.cursor_blink_ease_in = "EaseInOut"
config.cursor_blink_ease_out = "EaseInOut"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 75,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
	target = "CursorColor",
}
config.mouse_bindings = require("config.mouse")

require("features.action_menu").setup(config, {
	projects = projects,
	project_dir = project_dir,
})

return config
