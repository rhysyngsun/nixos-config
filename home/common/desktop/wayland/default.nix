{
  imports = [
    ./waybar
    ./anyrun.nix
    ./flameshot.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./mako.nix
    # ./mpvpaper.nix
    ./swayidle.nix
    ./swaylock.nix
    ./swayr.nix
    ./swww.nix
    ./wlogout.nix
  ];

  services.hypridle.enable = true;
  # services.swayidle.enable = true;

  # home.packages = with pkgs; [ eww-wayland ];

  # xdg.configFile."eww" = {
  #   source = ../../../../config/eww;
  #   recursive = true;
  # };
}
