{ pkgs, ... }:
let
  rice = pkgs.rice;
in
{
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    
    inherit (rice.cursors) name package size;
  };
}
