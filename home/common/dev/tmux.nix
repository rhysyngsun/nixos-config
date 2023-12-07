{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;
      mouse = true;
      baseIndex = 1;
      keyMode = "vi";

      shell = "${pkgs.zsh}/bin/zsh";

      extraConfig = ''
	bind '"' split-window -c "#{pane_current_path}"
	bind % split-window -h -c "#{pane_current_path}"
	bind c new-window -c "#{pane_current_path}"
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
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour 'mocha'
            set -g @catppuccin_window_tabs_enabled on
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
