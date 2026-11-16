# WezTerm

A minimal WezTerm configuration for Windows, with an on-demand **fzf action menu**.

The terminal stays clean by default. Press Ctrl+Shift+P to open the full action menu, or Alt+Shift+L for the shell picker.

## Requirements

- [WezTerm](https://wezterm.org/)
- [PowerShell 7](https://github.com/PowerShell/PowerShell)
- [fzf](https://github.com/junegunn/fzf)
- pwsh.exe, cmd.exe, and wsl.exe available on PATH for their respective launch options
- An Arch WSL distribution named Arch for the Arch Linux entries

## Menu

The fzf menu provides:

- **Shells:** PowerShell, Command Prompt, and Arch Linux (WSL), launched in tabs, panes, or new windows
- **Tabs:** switch between tabs in the current window, rename the current tab, and close the current tab
- **Windows:** create PowerShell or Arch Linux windows and rename the current window
- **Panes:** split, navigate, resize, zoom, and close
- **Workspaces:** rename the current workspace or create a new PowerShell/Arch workspace
- **Scrollback:** fuzzy-select lines from the current pane's scrollback and copy them to the Windows clipboard

The menu uses the WezTerm CLI for actions it exposes. Operations without a CLI equivalent remain native WezTerm shortcuts, including terminal search and Quick Select.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+P | Full fzf action menu |
| Alt+Shift+L | Shell-only fzf picker |
| Ctrl+Shift+F | Native scrollback search |
| Ctrl+Shift+Space | Native Quick Select |
| Alt+Shift+D | Split pane vertically |
| Alt+Shift+R | Split pane horizontally |
| Ctrl+Shift+Arrow | Navigate panes |
| Ctrl+Shift+Z | Toggle pane zoom |

## Install

Place .wezterm.lua in your WezTerm configuration directory and keep scripts/action-menu.ps1 at the matching relative path.

Make sure fzf.exe is on PATH, then reload WezTerm configuration.
