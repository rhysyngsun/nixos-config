local wezterm = require 'wezterm'
local act = wezterm.action

-- for validation
local config = wezterm.config_builder()

-- disable for now because it's broken
config.enable_wayland = true

config.enable_scroll_bar = true
config.scrollback_lines = 10000

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


config.check_for_updates = false

config.leader = { key = 'a', mods = 'CTRL' }

config.keys = {
  -- send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
  {
    key = 'Space',
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
  -- CTRL+SHIFT+Space, followed by 'r' will put us in resize-pane
  -- mode until we cancel that mode.
  {
    key = 'r',
    mods = 'LEADER',
    action = act.ActivateKeyTable {
      name = "resize_pane",
      one_shot = false,
    }
  },
  -- CTRL+SHIFT+Space, followed by 'a' will put us in activate-pane
  -- mode until we press some other key or until 1 second (1000ms)
  -- of time elapses
  {
    key = 'a',
    mods = 'LEADER',
    action = act.ActivateKeyTable {
      name = 'activate_pane',
      timeout_milliseconds = 1000,
    },
  },

  -- pane switching
  --
  { key = "1", mods = 'CTRL|ALT', action = act.ActivateTab(0) },
  { key = "2", mods = 'CTRL|ALT', action = act.ActivateTab(1) },
  { key = "3", mods = 'CTRL|ALT', action = act.ActivateTab(2) },
  { key = "4", mods = 'CTRL|ALT', action = act.ActivateTab(3) },
  { key = "5", mods = 'CTRL|ALT', action = act.ActivateTab(4) },
  { key = "6", mods = 'CTRL|ALT', action = act.ActivateTab(5) },
  { key = "7", mods = 'CTRL|ALT', action = act.ActivateTab(6) },
  { key = "8", mods = 'CTRL|ALT', action = act.ActivateTab(7) },
  { key = "9", mods = 'CTRL|ALT', action = act.ActivateTab(8) },
  { key = "0", mods = 'CTRL|ALT', action = act.ActivateTab(9) },
  { key = "[", mods = 'CTRL|ALT', action = act.ActivateTabRelative(-1) },
  { key = "]", mods = 'CTRL|ALT', action = act.ActivateTabRelative(1) },
}

config.key_tables = {
  -- Defines the keys that are active in our resize-pane mode.
  -- Since we're likely to want to make multiple adjustments,
  -- we made the activation one_shot=false. We therefore need
  -- to define a key assignment for getting out of this mode.
  -- 'resize_pane' here corresponds to the name="resize_pane" in
  -- the key assignments above.
  resize_pane = {
    { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 1 } },
    { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },

    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 1 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },

    { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 1 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },

    { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 1 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },

    -- Cancel the mode by pressing escape
    { key = 'Escape', action = 'PopKeyTable' },
  },

  -- Defines the keys that are active in our activate-pane mode.
  -- 'activate_pane' here corresponds to the name="activate_pane" in
  -- the key assignments above.
  activate_pane = {
    { key = 'LeftArrow', action = act.ActivatePaneDirection 'Left' },
    { key = 'h', action = act.ActivatePaneDirection 'Left' },

    { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
    { key = 'l', action = act.ActivatePaneDirection 'Right' },

    { key = 'UpArrow', action = act.ActivatePaneDirection 'Up' },
    { key = 'k', action = act.ActivatePaneDirection 'Up' },

    { key = 'DownArrow', action = act.ActivatePaneDirection 'Down' },
    { key = 'j', action = act.ActivatePaneDirection 'Down' },

    -- Cancel the mode by pressing escape
    { key = 'Escape', action = 'PopKeyTable' },
  },
}

return config
