{ ... }:
{
  flake.modules.homeManager.theme-cursors =
    { pkgs, ... }:
    let
      rice = pkgs.rice;
    in
    {
      home.pointerCursor = {
        gtk.enable = true;

        inherit (rice.cursors) name package size;
      };
    };
}
