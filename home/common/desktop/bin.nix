{ pkgs, ... }:
{
  home.packages = with pkgs.nodePackages; [ zx ];

  xdg.dataFile."bin" = {
    source = ../../../bin;
    recursive = true;
  };
}