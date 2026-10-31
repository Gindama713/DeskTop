-- WezTerm: desktop console
-- tab 1 = htop | tab 2 = console (HUD + claude + ubuntu) | tab 3 = claude
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

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
config.default_cwd = 'E:\\ClaudeConsole'
config.initial_cols = 120
config.initial_rows = 36
config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true

-- Alt+arrows flip tabs, Alt+T new, Alt+W close
config.keys = {
  { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },
  { key = 't', mods = 'ALT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
}

local claude_cmd = "& 'C:\\Users\\31772\\AppData\\Roaming\\npm\\claude.cmd'"

wezterm.on('gui-startup', function(cmd)
  local py = 'C:\\Users\\31772\\.dsh\\dsh-runtimes\\dsh-primary-runtime\\dependencies\\python\\python.exe'
  local t1, p1, win = wezterm.mux.spawn_window {
    args = { py, '-u', 'E:\\Apps\\DesktopTerminal\\donut.py' },
  }
  p1:split {
    direction = 'Right',
    size = 0.44,
    args = {
      'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass',
      '-File', 'E:\\Apps\\DesktopTerminal\\leetcode.ps1',
    },
  }

  local t2, p2 = win:spawn_tab {
    cwd = 'E:\\ClaudeConsole',
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-Command', claude_cmd },
  }
  p2:split {
    direction = 'Left',
    size = 0.40,
    args = {
      'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass',
      '-File', 'E:\\Apps\\DesktopTerminal\\hud.ps1',
    },
  }
  p2:split {
    direction = 'Bottom',
    size = 0.34,
    cwd = 'D:\\Desktop',
    args = { 'wsl.exe', '-d', 'Ubuntu-24.04', '--cd', '/mnt/d/Desktop' },
  }

  local t3, p3 = win:spawn_tab {
    cwd = 'E:\\Apps\\DesktopTerminal',
    args = { 'powershell.exe', '-NoLogo', '-NoExit', '-Command', 'tb' },
  }
  p3:split {
    direction = 'Right',
    size = 0.40,
    args = {
      'powershell.exe', '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass',
      '-File', 'E:\\Apps\\DesktopTerminal\\pomodoro.ps1',
    },
  }

  t2:activate()
end)

return config
