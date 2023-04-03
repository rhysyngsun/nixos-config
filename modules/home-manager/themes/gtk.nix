{ config, lib, pkgs, ... }:
with lib;
let
  colors = config.themes.colors;
  cfg = config.themes.gtk;
in
{
  imports = [
    ./colors.nix
  ];
  options.themes.gtk = {
    enable = mkEnableOption "theme-gtk";
  };

  config.gtk = mkIf cfg.enable {
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
  };
}