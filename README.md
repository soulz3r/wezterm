# WezTerm

A minimal Windows WezTerm configuration with an on-demand **fzf action menu**.

The terminal stays clean by default. The richer interface appears only when requested.

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

Lua owns configuration and WezTerm actions. The small PowerShell helper only runs fzf and returns the selected action through a WezTerm user variable. It does not call the WezTerm CLI or manage panes itself.

## Menu

- **Shells:** PowerShell, CMD, and Arch WSL in a new tab, window, or split
- **Tabs:** create, switch, previous, next, and close
- **Panes:** split, focus, zoom, and close
- **Search:** native scrollback search and Quick Select
- **Appearance:** increase, decrease, and reset font size
- **Window:** toggle fullscreen
- **Workspaces:** switch between existing workspaces
- **Config:** reload configuration

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+P | Full fzf action menu |
| Alt+Shift+L | fzf shell picker |
| Ctrl+Shift+F | Native scrollback search |
| Ctrl+Shift+Space | Native Quick Select |
| Alt+Shift+D | Split pane vertically |
| Alt+Shift+R | Split pane horizontally |
| Ctrl+Shift+Arrow | Navigate panes |
| Ctrl+Shift+Z | Toggle pane zoom |

## Install

Keep the project files in the WezTerm config directory. Install fzf and ensure fzf.exe is on PATH, then reload WezTerm.

If the menu cannot find fzf, its temporary tab displays the error instead of silently failing.
