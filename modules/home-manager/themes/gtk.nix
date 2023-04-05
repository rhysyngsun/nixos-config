{ pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{
  gtk = {
    enable = true;
    theme = with colors; {
      name = "Catppuccin-${flavor.name}-Compact-${accent.name}-Dark";
      package = pkgs.unstable.catppuccin-gtk.override {
        accents = [ accent.lower ];
        size = "compact";
        tweaks = [ "rimless" "black" ];
        variant = flavor.lower;
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
}
