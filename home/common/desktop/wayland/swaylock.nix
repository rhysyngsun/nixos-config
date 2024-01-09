{ config, pkgs, lib, ... }:
with lib;
let
  swaylock = "${lib.getExe pkgs.swaylock-effects} -f";
in
{
  xdg.configFile."swaylock/config".text = ''
    screenshots
    clock
    indicator
    indicator-radius=100
    indicator-thickness=7
    effect-blur=7x5
    effect-vignette=0.5:0.5
    grace=2
    fade-in=0.2
    # colors
    line-color=11111bff
    line-clear-color=11111bff
    line-caps-lock-color=11111bff
    line-ver-color=11111bff
    line-wrong-color=11111bff
    inside-color=b4befe55
    inside-ver-color=b4befe33
    ring-color=b4befecc
    ring-ver-color=b4befe99
    key-hl-color=b4befeff
    separator-color=11111bff
    # text stylings
    font-size=16
    text-color=cdd6f4FF
    text-clear-color=cdd6f4FF
    text-caps-lock-color=cdd6f4FF
    text-ver-color=cdd6f4FF
    text-wrong-color=cdd6f4FF
  '';

  services.swayidle = {
    enable = true;
    events = [
      {
        command = swaylock;
        event = "before-sleep";
      }
      {
        command = "lock";
        event = "lock";
      }
    ];
    timeouts = [
      {
        timeout = 60 * 60;
        command = swaylock;
      }
      {
        timeout = 60 * 65;
        command =
          "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
        resumeCommand =
          "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
      }
    ];
  };
  systemd.user.services.swayidle.Install.WantedBy =
    mkForce [ "hyprland-session.target" ];
}
