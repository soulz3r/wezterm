# WezTerm

A minimal WezTerm configuration for Windows, with an on-demand Lua action menu.

The terminal stays clean by default. Press **Ctrl+Shift+P** for the full action menu or **Alt+Shift+L** for the shell picker.

## Requirements

- [WezTerm](https://wezterm.org/)
- PowerShell 7 (pwsh.exe), Command Prompt (cmd.exe), and WSL (wsl.exe) for their respective shell entries
- An Arch WSL distribution named Arch for the Arch Linux entry

There is no external menu script and no fzf dependency. The menu uses WezTerm's built-in InputSelector with fuzzy filtering, so selection and actions stay inside the Lua config and the WezTerm process.

## Menu

- **Shells:** PowerShell, Command Prompt, and Arch Linux (WSL), launched in a tab, new window, or split pane
- **Tabs:** previous, next, and close current tab
- **Panes:** split, navigate, zoom, and close
- **Search:** native scrollback search and Quick Select
- **Appearance:** increase, decrease, or reset font size
- **Window:** toggle fullscreen
- **Configuration:** reload the config

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+P | Lua action menu |
| Alt+Shift+L | Lua shell picker |
| Ctrl+Shift+F | Native scrollback search |
| Ctrl+Shift+Space | Native Quick Select |
| Alt+Shift+D | Split pane vertically |
| Alt+Shift+R | Split pane horizontally |
| Ctrl+Shift+Arrow | Navigate panes |
| Ctrl+Shift+Z | Toggle pane zoom |

## Install

Place .wezterm.lua in your WezTerm configuration directory, then reload the configuration.
