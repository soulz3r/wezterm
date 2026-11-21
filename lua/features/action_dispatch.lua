local wezterm = require("wezterm")
local act = wezterm.action
local registry = require("features.action_registry")
local shells = require("config.shells")

local M = {}

local DEFAULT_SCHEME = "Minmax Phosphor"
local DEFAULT_OPACITY = 0.85

local function find_shell(name)
	for _, shell in ipairs(shells.items) do
		if shell.name == name then return shell end
	end
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
	["pane:split:down"] = act.SplitPane({ direction = "Down", size = { Percent = 50 } }),
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

function M.run(window, pane, id, options, handlers)
	if not id or id == "cancel" or id:match("^result:%d+$") then return end

	local function open(items)
		handlers.open(window, pane, items, options)
	end

	if id == "menu" then
		open(registry.build(window, "all", shells.items))
	elseif id == "project:picker" then
		handlers.open_projects(window, pane, options)
	elseif id:match("^project:open:") then
		local path = id:sub(14)
		local name = path:gsub("[/\\\\]+$", ""):match("([^/\\\\]+)$")
		if not name then
			handlers.notify(window, "Project picker", "Invalid project path.")
			return
		end
		window:perform_action(act.SwitchToWorkspace({
			name = "project-" .. name,
			spawn = { cwd = path, args = shells.git_bash },
		}), pane)
	elseif id == "shell-picker" then
		open(registry.build(window, "shells", shells.items))
	elseif id == "cheatsheet" then
		open(registry.cheatsheet())
	elseif id == "scheme:picker" then
		handlers.open_schemes(window, pane, options)
	elseif id == "font:picker" then
		handlers.open_fonts(window, pane, options)
	elseif id == "search:fzf" or id == "search:quick" then
		handlers.open_scrollback(window, pane, options, id == "search:quick")
		return
	else
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
			handlers.set_override(window, "color_scheme", id:sub(14))
		elseif id == "scheme:default" then
			handlers.set_override(window, "color_scheme", DEFAULT_SCHEME)
		elseif id:match("^font:apply:") then
			handlers.set_override(window, "font", wezterm.font(id:sub(12)))
		elseif id == "appearance:opacity" then
			local current = (window:get_config_overrides() or {}).window_background_opacity
			handlers.set_override(window, "window_background_opacity", current == 1.0 and DEFAULT_OPACITY or 1.0)
		elseif id == "appearance:tab-bar" then
			local current = (window:get_config_overrides() or {}).enable_tab_bar
			handlers.set_override(window, "enable_tab_bar", current ~= true)
		elseif id == "appearance:scrollbar" then
			local current = (window:get_config_overrides() or {}).enable_scroll_bar
			handlers.set_override(window, "enable_scroll_bar", not (current == nil and false or current))
		elseif id == "appearance:cursor" then
			local current = (window:get_config_overrides() or {}).default_cursor_style or "BlinkingBar"
			handlers.set_override(window, "default_cursor_style", current == "BlinkingBar" and "SteadyBar" or "BlinkingBar")
		elseif id == "workspace:create" then
			handlers.prompt(window, pane, "Create workspace", function(name)
				window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
			end)
		elseif id == "workspace:rename" then
			handlers.prompt(window, pane, "Rename current workspace", function(name)
				wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), name)
			end)
		elseif id:match("^workspace:switch:") then
			window:perform_action(act.SwitchToWorkspace({ name = id:sub(18) }), pane)
		elseif id == "tab:rename" then
			handlers.prompt(window, pane, "Rename current tab", function(name)
				pane:tab():set_title(name)
			end)
		else
			local action = direct[id]
			if action then
				window:perform_action(action, pane)
			elseif id:match("^tab:activate:") then
				local index = tonumber(id:match("(%d+)$"))
				if index then window:perform_action(act.ActivateTab(index - 1), pane) end
			elseif id == "pane:rotate-clockwise" or id == "pane:rotate-counter-clockwise" then
				if wezterm.has_action("RotatePanes") then
					local direction = id == "pane:rotate-clockwise" and "Clockwise" or "CounterClockwise"
					window:perform_action(act.RotatePanes(direction), pane)
				end
			elseif id:match("^pane:resize:") then
				if wezterm.has_action("AdjustPaneSize") then
					window:perform_action(act.AdjustPaneSize({ id:match("([^:]+)$"), 5 }), pane)
				end
			elseif id == "docs" then
				wezterm.open_with("https://wezterm.org/")
			end
		end
	end
end

return M
