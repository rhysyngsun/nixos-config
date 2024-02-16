{ pkgs, config, ... }:
let 
  rice = pkgs.rice;
in
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings =  rice.alacritty.config // {
      colors = {
        primary.background = "#1E1E2E";
      };
      env = {
        TERM = "xterm-256color";
      };

      window = {
        inherit (rice) opacity;
        padding = {
          x = 8;
          y = 8;
        };
      };
      # shell.program = config.home.sessionVariables.SHELL;
      font = {
        builtin_box_drawing = false;
      };
    };
  };
}
