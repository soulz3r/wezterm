local wezterm = require("wezterm")

local M = {}

local function item(items, label, id, category)
	table.insert(items, {
		label = string.format("%s / %s", category, label),
		id = id,
	})
end

function M.build(window, mode)
	local items = {}

	local shells = {
		{ name = "Git Bash", args = { "C:/Program Files/Git/bin/bash.exe", "--rcfile", "D:/config/bash/.bashrc", "-i" } },
		{ name = "PowerShell", args = { "pwsh.exe", "-NoLogo" } },
		{ name = "Command Prompt", args = { "cmd.exe" } },
		{ name = "Arch Linux (WSL)", args = { "wsl.exe", "-d", "Arch" } },
	}

	for _, shell in ipairs(shells) do
		item(items, shell.name .. " / New tab", "shell:tab:" .. shell.name, "Shells")
		if mode == "all" then
			item(items, shell.name .. " / New window", "shell:window:" .. shell.name, "Shells")
			item(items, shell.name .. " / Split right", "shell:split:" .. shell.name, "Shells")
		end
	end

	if mode == "shells" then
		return items
	end

	item(items, "Open project", "project:picker", "Projects")

	local tab_items = {
		{ "New tab", "tab:new" },
		{ "Previous tab", "tab:previous" },
		{ "Next tab", "tab:next" },
		{ "Move tab left", "tab:move-left" },
		{ "Move tab right", "tab:move-right" },
		{ "Close current tab", "tab:close" },
		{ "Tab navigator", "tab:navigator" },
		{ "Rename current tab", "tab:rename" },
	}
	for _, entry in ipairs(tab_items) do
		item(items, entry[1], entry[2], "Tabs")
	end

	for index, tab in ipairs(window:mux_window():tabs()) do
		local panes = tab:panes()
		local title = panes[1] and panes[1]:get_title() or ("Tab " .. index)
		item(items, string.format("Switch to %02d / %s", index, title), "tab:activate:" .. index, "Tabs")
	end

	local pane_items = {
		{ "Split right", "pane:split:right" },
		{ "Split down", "pane:split:down" },
		{ "Select pane", "pane:select" },
		{ "Zoom / unzoom pane", "pane:zoom" },
		{ "Close current pane", "pane:close" },
		{ "Rotate panes clockwise", "pane:rotate-clockwise" },
		{ "Rotate panes counter-clockwise", "pane:rotate-counter-clockwise" },
		{ "Resize pane left", "pane:resize:left" },
		{ "Resize pane right", "pane:resize:right" },
		{ "Resize pane up", "pane:resize:up" },
		{ "Resize pane down", "pane:resize:down" },
	}
	for _, entry in ipairs(pane_items) do
		item(items, entry[1], entry[2], "Panes")
	end

	local search_items = {
		{ "Search scrollback with fzf", "search:fzf" },
		{ "Quick Select from scrollback", "search:quick" },
		{ "Native search", "search:native" },
		{ "Enter copy mode", "copy-mode" },
	}
	for _, entry in ipairs(search_items) do
		item(items, entry[1], entry[2], "Search")
	end

	local utility_items = {
		{ "Copy selection", "clipboard:copy" },
		{ "Paste clipboard", "clipboard:paste" },
		{ "Clear selection", "clipboard:clear" },
		{ "Scroll to top", "scroll:top" },
		{ "Scroll to bottom", "scroll:bottom" },
		{ "Page up", "scroll:page-up" },
		{ "Page down", "scroll:page-down" },
		{ "Clear scrollback", "scroll:clear" },
	}
	for _, entry in ipairs(utility_items) do
		local category = entry[2]:match("^clipboard") and "Clipboard" or "Scrollback"
		item(items, entry[1], entry[2], category)
	end

	local appearance_items = {
		{ "Increase font size", "font:increase" },
		{ "Decrease font size", "font:decrease" },
		{ "Reset font size", "font:reset" },
		{ "Choose color scheme", "scheme:picker" },
		{ "Restore default color scheme", "scheme:default" },
		{ "Choose font", "font:picker" },
		{ "Toggle background opacity", "appearance:opacity" },
		{ "Toggle tab bar", "appearance:tab-bar" },
		{ "Toggle scrollbar", "appearance:scrollbar" },
		{ "Toggle cursor blink", "appearance:cursor" },
	}
	for _, entry in ipairs(appearance_items) do
		item(items, entry[1], entry[2], "Appearance")
	end

	local window_items = {
		{ "Toggle fullscreen", "window:fullscreen" },
		{ "Show debug overlay", "debug" },
		{ "Reload configuration", "config:reload" },
		{ "Open WezTerm documentation", "docs" },
	}
	for _, entry in ipairs(window_items) do
		item(items, entry[1], entry[2], "Window / Config")
	end

	for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
		item(items, "Switch to " .. workspace, "workspace:switch:" .. workspace, "Workspaces")
	end
	item(items, "Create workspace", "workspace:create", "Workspaces")
	item(items, "Rename current workspace", "workspace:rename", "Workspaces")

	local optional_actions = {
		["pane:rotate-clockwise"] = "RotatePanes",
		["pane:rotate-counter-clockwise"] = "RotatePanes",
		["pane:resize:left"] = "AdjustPaneSize",
		["pane:resize:right"] = "AdjustPaneSize",
		["pane:resize:up"] = "AdjustPaneSize",
		["pane:resize:down"] = "AdjustPaneSize",
	}
	for index = #items, 1, -1 do
		local required = optional_actions[items[index].id]
		if required and not wezterm.has_action(required) then
			table.remove(items, index)
		end
	end

	return items
end

function M.cheatsheet()
	local rows = {
		{ "Ctrl+Shift+P", "Open complete command menu", "menu" },
		{ "Alt+Shift+P", "Open project picker", "project:picker" },
		{ "Alt+Shift+L", "Open shell picker", "shell-picker" },
		{ "Ctrl+Shift+F", "Search scrollback with fzf", "search:fzf" },
		{ "Ctrl+Shift+Space", "Quick Select from scrollback", "search:quick" },
		{ "Alt+Shift+S", "Open searchable keymap guide", "cheatsheet" },
		{ "Alt+Shift+O", "Choose color scheme", "scheme:picker" },
		{ "Alt+Shift+D", "Split pane right", "pane:split:right" },
		{ "Alt+Shift+R", "Split pane down", "pane:split:down" },
		{ "Alt+Shift+T", "New tab", "tab:new" },
		{ "Alt+Shift+W", "Close current tab", "tab:close" },
		{ "Alt+Shift+C", "Enter copy mode", "copy-mode" },
		{ "Ctrl+Shift+C", "Copy selection", "clipboard:copy" },
		{ "Ctrl+Shift+V", "Paste clipboard", "clipboard:paste" },
		{ "Ctrl+Shift+Arrow", "Navigate panes", "pane:select" },
		{ "Ctrl+Shift+Z", "Zoom / unzoom pane", "pane:zoom" },
		{ "Alt+Shift+Enter", "Toggle fullscreen", "window:fullscreen" },
		{ "Ctrl+Shift+R", "Reload configuration", "config:reload" },
	}
	local items = {}
	for _, row in ipairs(rows) do
		item(items, string.format("%-22s / %s", row[1], row[2]), row[3], "Keymaps")
	end
	return items
end

return M
