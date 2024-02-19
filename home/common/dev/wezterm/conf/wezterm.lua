local wezterm = require 'wezterm'

return {
  color_scheme = 'Catppuccin Mocha',
  xcursor_theme = 'Catppuccin-Mocha-Lavender-Cursors',
  -- font name as it appears in `fc-list`
  font = wezterm.font 'Iosevka Nerd Font',
  font_size = 11,
  line_height = 0.9,

  enable_scroll_bar = true,
  tab_bar_at_bottom = true,

  leader = { key = 'a', mods = 'CTRL'},

  keys = {
      {
        key = '-',
        mods = 'LEADER',
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
      },
      {
        key = '|',
        mods = 'LEADER',
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
      },
      {
        key = 'z',
        mods = 'LEADER',
        action = wezterm.action.TogglePaneZoomState,
      },
      -- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
      {
        key = 'a',
        mods = 'LEADER|CTRL',
        action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
      },

    {
      key = 'h',
      mods = 'CTRL',
      action = wezterm.action.ActivatePaneDirection 'Left'
    },
    {
      key = 'l',
      mods = 'CTRL',
      action = wezterm.action.ActivatePaneDirection 'Right'
    },
    {
      key = 'k',
      mods = 'CTRL',
      action = wezterm.action.ActivatePaneDirection 'Up'
    },
    {
      key = 'j',
      mods = 'CTRL',
      action = wezterm.action.ActivatePaneDirection 'Down'
    },
  }
}
