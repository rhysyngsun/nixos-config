{
  imports = [
    ./waybar
    ./anyrun.nix
    ./flameshot.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./mako.nix
    ./swayr.nix
    ./swww.nix
    ./walker.nix
    ./wlogout.nix
  ];

  services.hypridle.enable = true;
}
