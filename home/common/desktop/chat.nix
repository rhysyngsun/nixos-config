{ pkgs, ... }:
{
  home.packages = [
    pkgs.discord
    pkgs.slack
    pkgs.element-desktop
  ];
}
