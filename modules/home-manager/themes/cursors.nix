{ pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{
  home.pointerCursor = with colors; {
    enable = true;
    gtk.enable = true;
    # x11.enable = true;
    size = 14;

    name = "Catppuccin-${flavor.name}-${accent.name}-Cursors";
    package = pkgs.catppuccin-cursors."${flavor.lower}${accent.name}";
  };
}
