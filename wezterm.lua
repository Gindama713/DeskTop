-- DeskTop: three tabs, no tab bar, pinned to the bottom by pin-terminal.ps1
-- LOCAL points at the folder that holds donut.py / hud.ps1 / leetcode.ps1 / todo-fzf.ps1
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local LOCAL = 'C:/Users/you/Desktop/DeskTop'
local PY = 'python'

config.font = wezterm.font_with_fallback({
  { family = 'JetBrainsMono Nerd Font' },
  { family = 'Microsoft YaHei' },
})
config.font_size = 8.5
config.line_height = 1.05

config.colors = {
  background = '#0c1a16',
  foreground = '#d3c6aa',
  cursor_bg = '#a7c080',
  cursor_fg = '#0c1a16',
  cursor_border = '#a7c080',
  selection_bg = '#a7c080',
  selection_fg = '#0c1a16',
  ansi = {
    '#232a2e', '#e67e80', '#a7c080', '#dbbc7f',
    '#7fbbb3', '#d699b6', '#83c092', '#d3c6aa',
  },
  brights = {
    '#475258', '#e67e80', '#a7c080', '#dbbc7f',
    '#7fbbb3', '#d699b6', '#83c092', '#ece6d5',
  },
}

config.window_background_opacity = 0.94
config.window_decorations = 'NONE'
config.window_padding = { left = 16, right = 16, top = 12, bottom = 12 }
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 168
config.initial_rows = 36
config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true

config.keys = {
  { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },
  { key = 't', mods = 'ALT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
}

local claude_cmd = "& 'claude.cmd'"

wezterm.on('gui-startup', function(cmd)
  -- tab 1: donut + leetcode
  local t1, p1, win = wezterm.mux.spawn_window {
    args = { PY, '-u', LOCAL .. '/donut.py' },
  }
  p1:split {
    direction = 'Right',
    size = 0.44,
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', LOCAL .. '/leetcode.ps1' },
  }

  -- tab 2: HUD | claude / wsl
  local t2, p2 = win:spawn_tab {
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-Command', claude_cmd },
  }
  p2:split {
    direction = 'Left',
    size = 0.40,
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', LOCAL .. '/hud.ps1' },
  }
  p2:split {
    direction = 'Bottom',
    size = 0.34,
    args = { 'wsl.exe' },
  }

  -- tab 3: todo + pomodoro
  local t3, p3 = win:spawn_tab {
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', LOCAL .. '/todo-fzf.ps1' },
  }
  p3:split {
    direction = 'Right',
    size = 0.26,
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', LOCAL .. '/pomodoro.ps1' },
  }

  t2:activate()
end)

return config
