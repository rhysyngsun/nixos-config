local wezterm = require 'wezterm'
local act = wezterm.action

-- for validation
local config = wezterm.config_builder()

-- disable for now because it's broken
config.enable_wayland = false

-- theme
config.color_scheme = 'Catppuccin Mocha'
config.xcursor_theme = 'Catppuccin-Mocha-Lavender'

-- font name as it appears in `fc-list`
config.font = wezterm.font 'Iosevka Nerd Font'
config.font_size = 11
config.line_height = 0.9

-- this never redisplays the cursor under hyprland/wayland
config.hide_mouse_cursor_when_typing = false
config.use_fancy_tab_bar = false

config.leader = { key = 'a', mods = 'CTRL'}

config.keys = {
  -- send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
  {
    key = 'a',
    mods = 'LEADER|CTRL',
    action = act.SendKey { key = 'a', mods = 'CTRL' },
  },
  -- pane spliting
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- zoom pane
  {
    key = 'z',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },
  -- close pane
  {
    key = 'x',
    mods = 'LEADER',
    action = act.CloseCurrentPane { confirm = true },
  },
  -- map pane nav same as nvim
  {
    key = 'h',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Left'
  },
  {
    key = 'j',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Down'
  },
  {
    key = 'k',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Up'
  },
  {
    key = 'l',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Right'
  },
  -- tmux-like pane resizing
  {
    key = 'H',
    mods = 'LEADER',
    action = act.AdjustPaneSize { 'Left', 5 }
  },
  {
    key = 'J',
    mods = 'LEADER',
    action = act.AdjustPaneSize { 'Down', 5 }
  },
  {
    key = 'K',
    mods = 'LEADER',
    action = act.AdjustPaneSize { 'Up', 5 }
  },
  {
    key = 'L',
    mods = 'LEADER',
    action = act.AdjustPaneSize { 'Right', 5 }
  },
}

for i = 1, 8 do
  -- CTRL+ALT + number to activate that tab
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CTRL|ALT',
    action = act.ActivateTab(i - 1),
  })
end

return config
