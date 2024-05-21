args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.waybar = {
    enable = true;

    # need to reassign this because we've overlayed it for hyprland
    package = lib.mkForce pkgs.waybar;

    style = import ./style.nix args;
    settings = import ./settings.nix args;

    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  systemd.user.services = {
    waybar = {
      Service = {
        ExecStart = lib.mkForce "${pkgs.waybar}/bin/waybar --log-level debug";
      };
    };
  };
}
