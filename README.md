# DeskTop

A terminal-first Windows desktop: a frameless WezTerm window pinned to the bottom of the
normal z-order, above the animated wallpaper and below every other window.

## Layout

| Tab | Content |
|-----|---------|
| 1 | Spinning ASCII donut (Python) + LeetCode stats |
| 2 | HUD (GINDAMA wordmark, system card) + Claude Code + Ubuntu (WSL) |
| 3 | taskbook kanban + pomodoro |

Tabs: `Alt+Left` / `Alt+Right`, direct `Alt+1..3`.

## Files

- `wezterm.lua` — WezTerm config (layout, colors, tabs)
- `hud.ps1` — left HUD pane (system card, ASCII bars)
- `donut.py` — spinning donut, classic donut.c math
- `leetcode.ps1` — LeetCode.cn GraphQL stats
- `gh-status.ps1` — GitHub stats (needs `gh auth login`)
- `todo.ps1` — scrollable todo.txt viewer
- `pomodoro.ps1` — pomodoro timer with presets
- `pin-terminal.ps1` — keeps the window pinned to HWND_BOTTOM
- `start-terminal.cmd` — launcher (terminal + pin watchdog)
- `wallpaper/` — HTML wallpaper (ASCII ocean, Lively Wallpaper)

## Requirements

- Windows 11, WezTerm, PowerShell 5.1+, Python 3, WSL (Ubuntu), `gh` (optional)
- Install paths in `wezterm.lua` assume `E:\Apps\DesktopTerminal`

## Notes

The window is pinned with `SetWindowPos(HWND_BOTTOM, SWP_NOACTIVATE)` in a loop, so it stays
visible over the wallpaper while never covering normal windows.