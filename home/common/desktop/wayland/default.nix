{ pkgs, ... }:
{
  imports = [
    ./waybar
    ./anyrun.nix
    ./flameshot.nix
    ./mako.nix
    ./swaylock.nix
    ./swayr.nix
    ./wlogout.nix
  ];

  # home.packages = with pkgs; [ eww-wayland ];

  # xdg.configFile."eww" = {
  #   source = ../../../../config/eww;
  #   recursive = true;
  # };
}
