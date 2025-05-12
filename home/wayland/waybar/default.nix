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

    # systemd.enable = true;
  };

  # systemd.user.services = {
  #   waybar = {
  #     Service = {
  #       ExecStart = lib.mkForce "${config.programs.waybar.package}/bin/waybar --log-level debug";
  #       PartOf = ["niri.service"];
  #       WantedBy = [
  #         "niri.service"
  #       ];
  #     };
  #   };
  # };
}
