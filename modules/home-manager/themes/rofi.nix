{ config, lib, ... }: 
with lib;
let
  enable = (
    config.themes.enable &&
    config.programs.rofi.enable
  );
  colors = config.themes.colors;
in {
  imports = [
    ./colors.nix
  ];

  config.xdg.dataFile = mkIf enable {
    "rofi/themes".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "rofi";
      rev = "5350da41a11814f950c3354f090b90d4674a95ce";
      hash = "sha256-DNorfyl3C4RBclF2KDgwvQQwixpTwSRu7fIvihPN8JY=";
    }) + "/.local/share/rofi/themes";
  };
  config.programs.rofi = with colors; mkIf enable {
    theme = "catppuccin-${flavor.lower}";
  };
}