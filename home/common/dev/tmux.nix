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
        tmuxPlugins.sensible
        tmuxPlugins.logging
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.vim-tmux-navigator
      ];
    };
  };
}
