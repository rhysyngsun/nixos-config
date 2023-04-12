{ pkgs, ... }:
{
  imports = [
    ./waybar
    ./rofi.nix
    ./swaylock.nix
    ./swayr.nix
  ];

  home.packages = with pkgs; [ eww-wayland ];

  xdg.configFile."eww" = {
    source = ../../../../config/eww;
    recursive = true;
  };
}
