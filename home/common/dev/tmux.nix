{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;
      mouse = true;
      prefix = "C-a";

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
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour 'mocha'
            set -g @catppuccin_window_tabs_enabled on
          '';
        }
        tmuxPlugins.sensible
        tmuxPlugins.logging
        tmuxPlugins.better-mouse-mode
      ];
    };
  };
}