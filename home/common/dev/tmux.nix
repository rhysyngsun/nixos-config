{ pkgs, lib, ... }:
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
        (let 
          flavor = "mocha";
        in {
          plugin = tmuxPlugins.catppuccin.overrideAttrs (oldAttrs: {
            postInstall = let
              palette = pkgs.catppuccin-palette.${flavor};
              colorOverrides = {
                thm_bg = "#${palette.mantle.hex}";
              };
              replaceColors = builtins.concatStringsSep "\n" 
                  (lib.attrsets.mapAttrsToList
                    (name: value: ''
                      sed -i -e 's/${name}=.*/${name}="${value}"/g' $target/catppuccin-${flavor}.tmuxtheme
                    '')
                    colorOverrides
                  );
            in oldAttrs.postInstall + replaceColors;
          });
          extraConfig = ''
            set -g @catppuccin_flavour '${flavor}'
            set -g @catppuccin_window_tabs_enabled on
            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"

            set -g @catppuccin_status_modules_right "directory session application"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"
            
            set -g @catppuccin_directory_text "#{pane_current_path}"
          '';
        })
        tmuxPlugins.sensible
        tmuxPlugins.logging
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.vim-tmux-navigator
      ];
    };
  };

  # xdg.configFile."tmux/tmux.conf".text = ''
  #   set -g status-bg default
  #   set -g status-style bg=default
  # '';
}
