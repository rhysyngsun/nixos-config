{ config, pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{
  xdg.dataFile."rofi/themes".source = (pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "rofi";
    rev = "5350da41a11814f950c3354f090b90d4674a95ce";
    hash = "sha256-DNorfyl3C4RBclF2KDgwvQQwixpTwSRu7fIvihPN8JY=";
  }) + "/basic/.local/share/rofi/themes";

  programs.rofi = with colors; {
    theme = "catppuccin-${flavor.lower}";
  };
}
