# WezTerm

A minimal Windows WezTerm setup with a searchable **fzf command palette**. The default terminal starts Git Bash; interactive terminal controls live behind menus.

## Design

- Keep the default window visually minimal.
- Put discoverable actions in fzf instead of filling the screen with buttons or tab bars.
- Keep WezTerm's native actions native. Use Lua callbacks only where a native action cannot express the behavior.
- Keep the fzf launcher isolated in PowerShell; Lua owns the menu catalog and action dispatch.
- Prefer graceful feature checks over failing the entire configuration because one action is unavailable in a particular WezTerm build.

## Requirements

- WezTerm (current stable recommended)
- fzf.exe on PATH
- Git for Windows installed at `C:/Program Files/Git`
- PowerShell 7 (pwsh.exe) on PATH for the fzf command palette
- Optional WSL distribution named Arch
- Project checkout at D:\config\wezterm
- Working directory D:\projects

The home-directory .wezterm.lua file loads this checkout. Update its project_dir if the repository moves. Git Bash is the default shell and uses `D:/config/bash/.bashrc`; the shell picker can still launch PowerShell, CMD or Arch WSL.

## Layout

    .
    ├── .github/workflows/validate.yml
    ├── .wezterm.lua
    ├── README.md
    ├── docs/
    │   └── FEATURES.md
    ├── lua/
    │   ├── config/
    │   │   ├── init.lua
    │   │   └── mouse.lua
    │   └── features/
    │       ├── action_registry.lua
    │       └── action_menu.lua
    └── scripts/
        └── fzf-menu.ps1

## Command palette

**Ctrl+Shift+P** opens the full fzf palette. **Alt+Shift+P** opens the project picker. **Alt+Shift+L** opens the shell picker.

| Area | Available controls |
| --- | --- |
| Projects | Search folders under D:\projects and open each in a persistent project workspace |
| Shells | Git Bash, PowerShell, CMD and optional Arch WSL in a tab, window or split |
| Tabs | Create, navigate, move, close, rename, switch by title, native tab navigator |
| Panes | Split, select, zoom, close, rotate and resize |
| Search | fzf scrollback search, fzf Quick Select, native search, copy mode |
| Clipboard | Copy, paste and clear selection |
| Scrollback | Top, bottom, page up/down and clear |
| Appearance | Built-in color schemes, font presets, font size, opacity, tab bar, scrollbar and cursor blink toggles |
| Workspaces | Switch, create and rename |
| Window | Fullscreen and debug overlay |
| Configuration | Reload and open the official documentation |
| Help | Searchable keymap guide |

The fzf menu is opened in a temporary tab. The PowerShell helper reads a temporary JSON catalog and returns the selected ID through the WEZTERM_MENU_ACTION user variable. Lua closes the temporary tab and dispatches the selection to the original pane.

Scrollback search copies the selected line. Quick Select copies the extracted match. These actions do not move the viewport to the source line.

## Keymaps

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+P | Full fzf palette |
| Alt+Shift+P | Project picker |
| Alt+Shift+L | Shell picker |
| Ctrl+Shift+F | fzf scrollback search |
| Ctrl+Shift+Space | fzf Quick Select |
| Alt+Shift+S | Searchable keymap guide |
| Alt+Shift+O | Color scheme picker |
| Alt+Shift+D | Split right |
| Alt+Shift+R | Split down |
| Alt+Shift+T | New tab |
| Alt+Shift+W | Close tab |
| Alt+Shift+C | Copy mode |
| Ctrl+Shift+C / V | Copy / paste |
| Ctrl+Shift+Arrow | Move focus between panes |
| Ctrl+Shift+Z | Zoom pane |
| Alt+Shift+Up / Down | Scroll a page |
| Ctrl+Shift+K | Clear scrollback |
| Alt+Shift+Enter | Fullscreen |
| Ctrl+Shift+R | Reload configuration |

The default Ctrl+Shift+X assignment is disabled.

## Validation

GitHub Actions parses every Lua file with Lua 5.4 and parses the PowerShell launcher on Windows. These checks catch syntax errors, not every runtime API mismatch. After pulling changes, reload WezTerm and test the palette, shell launch, tab/pane controls, theme picker and workspace actions in a live session.

Useful diagnostics:

- wezterm show-keys
- wezterm --config-file D:\config\wezterm\.wezterm.lua show-config
- WezTerm debug overlay: Ctrl+Shift+L (native default may vary)

## Scope

WezTerm is both a terminal emulator and a programmable multiplexer. Its complete API includes configuration fields, actions, events, domains, CLI commands and platform-specific integrations. Not every API is a meaningful interactive command. This repository exposes the practical GUI/session controls in fzf and keeps static configuration in Lua. See docs/FEATURES.md for the feature map and known boundaries.
