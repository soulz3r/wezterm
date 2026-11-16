# WezTerm

A minimal Windows WezTerm configuration with a real, searchable **fzf command interface**.

The terminal stays quiet by default. Shells, tabs, panes, search, quick selection, color schemes, and the cheat sheet are available through fzf.

## Requirements

- [WezTerm](https://wezterm.org/)
- [fzf](https://github.com/junegunn/fzf) available as fzf.exe on PATH
- PowerShell 7 (pwsh.exe)
- WSL with an Arch distribution named Arch for the Arch shell entry

## Project structure

```text
.
├── .wezterm.lua
├── lua
│   ├── config
│   │   ├── init.lua
│   │   └── mouse.lua
│   └── features
│       └── action_menu.lua
└── scripts
    └── fzf-menu.ps1
```

Lua owns the configuration and WezTerm actions. PowerShell only launches fzf and returns the selected item through a WezTerm user variable.

## fzf command interface

- **Shells:** PowerShell, CMD, and Arch WSL in a new tab, window, or split
- **Tabs:** create, switch, move, close, and navigate
- **Panes:** split, focus, rotate, select, zoom, and close
- **Search:** fzf over the active pane's full scrollback
- **Quick Select:** extract URLs, paths, hashes, IP addresses, and numbers from scrollback, then filter them with fzf
- **Clipboard:** copy, paste, and clear selection
- **Scrollback:** top, bottom, page navigation, and clear
- **Appearance:** font size controls and all built-in WezTerm color schemes
- **Window:** fullscreen, always-on-top, always-on-bottom, maximize, restore, and debug overlay
- **Workspaces:** switch between existing workspaces
- **Cheat sheet:** searchable list of custom shortcuts with actionable entries
- **Config:** reload configuration and open documentation

Search and Quick Select now use fzf. Selecting a search result or Quick Select match copies that text to the clipboard.

## Keymaps

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+P | Full fzf action menu |
| Alt+Shift+L | fzf shell picker |
| Ctrl+Shift+F | fzf scrollback search |
| Ctrl+Shift+Space | fzf Quick Select |
| Alt+Shift+S | fzf cheat sheet |
| Alt+Shift+O | fzf color scheme picker |
| Alt+Shift+D | Split pane right |
| Alt+Shift+R | Split pane down |
| Alt+Shift+T | New tab |
| Alt+Shift+W | Close current tab |
| Alt+Shift+C | Enter copy mode |
| Ctrl+Shift+C | Copy selection |
| Ctrl+Shift+V | Paste clipboard |
| Ctrl+Shift+Arrow | Navigate panes |
| Ctrl+Shift+Z | Toggle pane zoom |
| Alt+Shift+Up | Scroll one page up |
| Alt+Shift+Down | Scroll one page down |
| Ctrl+Shift+K | Clear scrollback |
| Alt+Shift+Enter | Toggle fullscreen |
| Ctrl+Shift+R | Reload configuration |

## Install

Keep the project at `D:\config\wezterm`. The home-directory `.wezterm.lua` entrypoint must point to that project path. Install fzf and ensure `fzf.exe` is on PATH, then reload WezTerm.

The fzf menu runs in a temporary tab, then closes after the selected action is dispatched.
