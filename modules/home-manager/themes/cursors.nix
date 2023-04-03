{ config, lib, pkgs, ... }:
with lib;
let
  colors = config.themes.colors;
  cfg = config.themes.cursors;
in
{
  imports = [
    ./colors.nix
  ];
  options.themes.cursors = {
    enable = mkEnableOption "theme-cursors";
  };

  config.home.pointerCursor = mkIf cfg.enable {
    enable = true;
    gtk.enable = true;

    name = "Catppuccin-${flavor.name}-${accent.name}-Cursors";
    package = pkgs.catppuccin-cursors."${flavor.lower}${accent.name}";
  };
}