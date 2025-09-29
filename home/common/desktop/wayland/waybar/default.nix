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
        ExecCondition = "/lib/systemd/systemd-xdg-autostart-condition \"Hyprland\" \"\"";
        ExecStart = lib.mkForce "${pkgs.waybar}/bin/waybar --log-level debug";
        Restart = "on-failure";
        Slice = "app-graphical.slice";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
