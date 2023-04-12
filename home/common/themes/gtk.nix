{ pkgs, ... }:
let 
  rice = pkgs.rice;
in
{
  gtk = {
    enable = true;
    theme = {
      inherit (rice.gtk.theme) name package;
    };
    iconTheme = rice.icons;
  };
}
