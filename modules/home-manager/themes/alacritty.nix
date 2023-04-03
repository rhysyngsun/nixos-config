{ config, lib, pkgs, ... }: 
with lib;
let
  colors = config.themes.colors;
  cfg = config.themes.alacritty;
in {
  imports = [
    ./colors.nix
  ];
  options.themes.alacritty = {
    enable = mkEnableOption "theme-alacritty";
  };

  config.xdg.configFile = mkIf cfg.enable {
    "alacritty/catppuccin".source = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "alacritty";
      rev = "3c808cbb4f9c87be43ba5241bc57373c793d2f17";
      hash = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
    };
  };
  
  config.programs.alacritty.settings = with colors; mkIf cfg.enable {
    import = [
      "$XDG_CONFIG_DIR/alacritty/catppuccin/catppuccin-${flavor.lower}.yml"
    ];
  };
}