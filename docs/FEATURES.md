# Feature map

This document separates WezTerm's capabilities by how they should be controlled. The fzf palette is an action surface, not a replacement for the configuration system.

## Runtime actions exposed through fzf

- Shell launch: PowerShell, Command Prompt and optional Arch WSL
- Tabs: create, activate, move, close, rename and native navigator
- Panes: split, select, zoom, close, rotate and resize
- Search: native search, scrollback search and pattern-based Quick Select
- Clipboard and scrollback operations
- Font size, font presets, color schemes and background opacity
- Project discovery from the configured project root and persistent project workspaces\n- Workspace switching, creation and rename
- Fullscreen and debug overlay

The action catalog is kept in lua/features/action_registry.lua. Dispatch and fzf lifecycle management live in lua/features/action_menu.lua.

## Static configuration

These are configuration concerns rather than one-shot actions:

- Font family and fallback configuration
- Color scheme default
- Window geometry, padding and decorations
- Tab bar and scrollbar defaults
- Scrollback capacity
- Cursor style and blink behavior
- Rendering frame limits
- Bell behavior
- Mouse bindings
- Shell and working-directory defaults

Edit lua/config/init.lua for persistent defaults. Runtime overrides are intentionally temporary and window-local.

## Events and integrations

WezTerm also exposes events such as gui-startup, update-status, bell, format-tab-title, user-var-changed and mux lifecycle events. They should be added when there is a concrete behavior to implement, not merely to inflate the feature list.

Domains, SSH, serial, WSL and mux connections depend on the user's environment and configuration. The current shell picker provides local Windows shells and an optional Arch WSL entry; it does not invent SSH hosts or domain definitions.

## Platform and API boundaries

- Some window-management actions are platform-specific and are not exposed as generic Windows controls.
- A menu item should only be added when its action and arguments are supported by the installed WezTerm version.
- API presence can be checked with wezterm.has_action() before registering optional actions.
- Lua/PowerShell syntax checks do not prove that a menu action behaves correctly in a live GUI session.
- Scrollback Quick Select uses configured Lua patterns. It is not identical to WezTerm's native Quick Select engine.

## Future additions

Potential modules should be independent and opt-in where appropriate:

1. Domain and SSH profile picker, populated only from configured domains.
2. Project picker, populated from a user-configured project root.
3. More runtime appearance overrides.
4. Optional status and notification modules.
5. Dedicated tests for action dispatch and fzf selection lifecycle.
