# WezTerm

A minimal Windows WezTerm configuration with a real, searchable **fzf command interface**.

The terminal stays quiet by default. Shells, tabs, panes, search, quick selection, color schemes, and the cheat sheet are available through fzf.

## Requirements

- [WezTerm](https://wezterm.org/)
- [fzf](https://github.com/junegunn/fzf), with `fzf.exe` available on `PATH`
- PowerShell 7, with `pwsh.exe` available on `PATH`
- WSL with a distribution named `Arch` for the Arch shell entry
- The configured directories `D:\config\wezterm` and `D:\projects`

PowerShell is the default shell. The Arch WSL entry is optional; the rest of the configuration does not require WSL.

## Project structure

```text
.
├── .wezterm.lua
├── README.md
├── lua
│   ├── config
│   │   ├── init.lua
│   │   └── mouse.lua
│   └── features
│       └── action_menu.lua
└── scripts
    └── fzf-menu.ps1
```

The home-directory `.wezterm.lua` entrypoint loads this repository from `D:/config/wezterm`. Keep that path in sync if the repository is moved.

Lua owns configuration and WezTerm actions. PowerShell reads the menu data, runs fzf, and returns the selected action through a WezTerm user variable.

## fzf command interface

Open the complete menu with **Ctrl+Shift+P**.

- **Shells:** PowerShell, CMD, and Arch WSL. The full menu offers new tab, new window, and split-pane launch modes.
- **Tabs:** create, switch, move, close, and open the native tab navigator.
- **Panes:** split, focus, rotate, select, zoom, and close.
- **Search:** fzf over the active pane's retained scrollback.
- **Quick Select:** extract URLs, Windows drive paths, Unix-style paths, hexadecimal strings, dotted numeric addresses, and numbers from scrollback.
- **Clipboard:** copy, paste, and clear selection.
- **Scrollback:** top, bottom, page navigation, and clear.
- **Appearance:** font size controls and built-in WezTerm color schemes.
- **Window:** fullscreen, maximize, restore, and debug overlay.
- **Workspaces:** switch between existing workspaces.
- **Cheat sheet:** searchable list of custom shortcuts with actionable entries.
- **Config:** reload configuration and open WezTerm documentation.

Search and Quick Select both use fzf. Selecting a search result copies the full line; selecting a Quick Select result copies the extracted match. Neither action moves the terminal viewport to the source line.

The fzf interface runs in a temporary tab. When a selection is made, the tab closes and Lua dispatches the selected action. If fzf cannot start, the script reports the error and sends a cancellation event so the temporary tab and menu data file can be cleaned up.

**Platform note:** WezTerm's always-on-top and always-on-bottom actions are currently implemented only on macOS, so they are intentionally not exposed by this Windows configuration.

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

The configuration uses WezTerm's strict config-builder mode. Invalid configuration fields should be reported instead of silently slipping through.

## Install

Keep the project at `D:\config\wezterm`. The home-directory `.wezterm.lua` entrypoint must point to that project path.

Install fzf, ensure `fzf.exe` and `pwsh.exe` are on `PATH`, then reload WezTerm. The configured working directory is `D:\projects`.

Use `wezterm show-keys` to inspect the effective key and mouse assignments. Use **Ctrl+Shift+L** to open WezTerm's debug overlay when investigating runtime errors.
