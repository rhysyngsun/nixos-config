{
  pkgs,
  config,
  ...
}: {
  services.hypridle = {
    ignoreDbusInhibit = false;
    lockCmd = "${config.programs.hyprlock.package}/bin/hyprlock";
    beforeSleepCmd = "${pkgs.systemd}/bin/loginctl lock-session";
    listeners = [
      {
        timeout = 60 * 30;
        onTimeout = "${config.programs.hyprlock.package}/bin/hyprlock";
      }
      {
        timeout = 60 * 31;
        onTimeout = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
        onResume = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
      }
    ];
  };
} 
