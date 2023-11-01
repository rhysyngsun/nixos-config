{ pkgs, ... }:
{
  imports = [
    ./waybar
    ./anyrun.nix
    ./flameshot.nix
    ./mako.nix
    # ./mpvpaper.nix
    ./swaylock.nix
    ./swayr.nix
    ./swww.nix
    ./wlogout.nix
  ];

  # home.packages = with pkgs; [ eww-wayland ];

  # xdg.configFile."eww" = {
  #   source = ../../../../config/eww;
  #   recursive = true;
  # };
}
