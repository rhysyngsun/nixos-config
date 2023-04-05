{ config, pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{

  xdg.configFile = {
    "alacritty/catppuccin".source = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "alacritty";
      rev = "3c808cbb4f9c87be43ba5241bc57373c793d2f17";
      hash = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
    };
  };

  programs.alacritty.settings = with colors; {
    import = [
      "${config.xdg.configHome}/alacritty/catppuccin/catppuccin-${flavor.lower}.yml"
    ];
    window = {
      opacity = 0.8;
    };
  };
}
