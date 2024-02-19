{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;
      mouse = true;
      baseIndex = 1;
      keyMode = "vi";
      prefix = "C-a";

      # shell = "${pkgs.zsh}/bin/zsh";

      extraConfig = ''
        bind '-' split-window -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        set -g status-style bg=default
      '';

      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '60' # minutes
          '';
        }
        {
          plugin = tmuxPlugins.mkTmuxPlugin rec {
            pluginName = "tmux-powerline";
            version = "3.0.0";
            src = fetchFromGitHub {
              owner = "erikw";
              repo = "tmux-powerline";
              rev = "v${version}";
              sha256 = "sha256-25uG7OI8OHkdZ3GrTxG1ETNeDtW1K+sHu2DfJtVHVbk=";
            };
          };
          extraConfig = ''
            set -g @tmux_power_theme '#${pkgs.catppuccin-palette.mocha.lavender.hex}'
          '';
        }
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"

            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"

            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"

            set -g @catppuccin_status_modules_right "directory user host session"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"

            set -g @catppuccin_directory_text "#{pane_current_path}"
          '';
        }
        tmuxPlugins.sensible
        tmuxPlugins.logging
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.vim-tmux-navigator
      ];
    };
  };
}
