{
  pkgs,
  config,
  ...
}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore-dbus-inhibit = false;
        lock_cmd = "${config.programs.hyprlock.package}/bin/hyprlock";
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
      };

      listeners = [
        {
          timeout = 60 * 30;
          onTimeout = "${config.programs.hyprlock.package}/bin/hyprlock";
        }
        {
          timeout = 60 * 31;
          on-timeout = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
          on-resume = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
      ];
    };

  };
} 
