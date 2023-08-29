{ pkgs, config, ... }:
let 
  cfg = config.programs.alacritty;
  rice = pkgs.rice;
  tomlFormat = pkgs.formats.toml {};
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

      font.normal.family = pkgs.rice.font.monospace.name;
      window = {
        inherit (rice) opacity;
        padding = {
          x = 8;
          y = 8;
        };
      };
      shell.program = config.home.sessionVariables.SHELL;
    };
  };
  
  xdg.configFile."alacritty/alacritty.yml".enable = false;
  xdg.configFile."alacritty/alacritty.toml".source = tomlFormat.generate "alacritty.toml" cfg.settings;
}