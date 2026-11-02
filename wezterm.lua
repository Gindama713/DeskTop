-- DeskTop: WezTerm config.
-- Layout lives in config.json; tools/gen-lua.ps1 turns it into generated/*.lua,
-- so this file stays presentation-only and every pane is an independent script.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- install.ps1 rewrites this to your clone directory
local LOCAL = 'C:/Users/31772/Documents/desktop-terminal'

local function load(rel, fallback)
  local ok, value = pcall(dofile, LOCAL .. '/' .. rel)
  if ok and type(value) == 'table' then return value end
  return fallback or {}
end

local settings = load('generated/settings.lua', {})
local panes = load('generated/panes.lua', {})
local W = settings.window or {}
local T = settings.theme or {}
local PY = settings.python or 'python'

config.font = wezterm.font_with_fallback({
  { family = 'JetBrainsMono Nerd Font' },
  { family = 'Microsoft YaHei' },
})
config.font_size = W.font_size or 8.5
config.line_height = 1.05

config.colors = {
  background = T.bg or '#0c1a16',
  foreground = T.fg or '#d3c6aa',
  cursor_bg = T.cursor or '#a7c080',
  cursor_fg = T.bg or '#0c1a16',
  cursor_border = T.cursor or '#a7c080',
  selection_bg = T.cursor or '#a7c080',
  selection_fg = T.bg or '#0c1a16',
  ansi = {
    '#232a2e', T.red or '#e67e80', T.green or '#a7c080', T.yellow or '#dbbc7f',
    T.aqua or '#7fbbb3', '#d699b6', T.aqua or '#83c092', T.fg or '#d3c6aa',
  },
  brights = {
    '#475258', T.red or '#e67e80', T.green or '#a7c080', T.yellow or '#dbbc7f',
    T.aqua or '#7fbbb3', '#d699b6', T.aqua or '#83c092', '#ece6d5',
  },
}

config.window_background_opacity = W.opacity or 0.94
config.window_decorations = 'NONE'
config.window_padding = { left = 16, right = 16, top = 12, bottom = 12 }
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = W.cols or 168
config.initial_rows = W.rows or 36
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

-- ${VAR} substitution keeps pane definitions free of absolute paths
local function subst(list)
  local map = {
    LOCAL = LOCAL,
    PY = PY,
    PS = 'powershell.exe',
    WSL = 'wsl.exe',
    CLAUDE = "& 'claude.cmd'",
  }
  local out = {}
  for _, v in ipairs(list) do
    out[#out + 1] = (v:gsub('%${(%u+)}', function(k) return map[k] or ('${' .. k .. '}') end))
  end
  return out
end

wezterm.on('gui-startup', function()
  local tabs = panes.tabs or {}
  local win
  local created = {}

  for i, tab in ipairs(tabs) do
    local tabPanes = tab.panes or {}
    if #tabPanes > 0 then
      local base
      if i == 1 then
        local t, p, w = wezterm.mux.spawn_window { args = subst(tabPanes[1].args) }
        win, base = w, p
        created[#created + 1] = t
      else
        local t, p = win:spawn_tab { args = subst(tabPanes[1].args) }
        base = p
        created[#created + 1] = t
      end

      for j = 2, #tabPanes do
        local spec = tabPanes[j]
        base:split {
          direction = spec.split or 'Right',
          size = spec.size or 0.5,
          args = subst(spec.args),
        }
      end
    end
  end

  local wanted = created[2] or created[1]
  if wanted then pcall(function() wanted:activate() end) end
end)

return config
