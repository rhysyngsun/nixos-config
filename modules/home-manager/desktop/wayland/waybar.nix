{ config, lib, ... }: 
with lib;
let
  cfg = config.desktop.wayland.waybar;
in {
  options.desktop.wayland.waybar = {
    enable = mkEnableOption "waybar";
  };

  config.programs.waybar = mkIf cfg.enable {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "clock" "cpu" "memory" "disk" ];
        modules-center = [ "wlr/workspaces" ];
        modules-right = [
          "temperature"
          "network"
          "pulseaudio"
          "battery"
          "tray"
        ];

        "wlr/workspaces" = {
          format = "{icon}";
          all-outputs = true;
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
          };
        };

        "cpu" = {
          interval = 10;
          format = " {usage}%";
          tooltip = false;
        };
        "memory" = {
          interval = 10;
          format = " {}%";
        };
        "disk" = {
          interval = 600;
          format = " {percentage_used}%";
          path = "/";
        };
        "clock" = {
          interval = 60;
          format = "{: %a %b %e %H:%M}";
        };
        "temperature" = {
          interval = 5;
          critical-threshold = 60;
          format = " {temperatureC}°C";
        };
        "network" = {
          format-wifi = " {signalStrength}%";
          format-ethernet = "";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "";
        };
        "pulseaudio" = {
          format = "{icon} {volume}% {format_source}";
          format-muted = " {format_source}";
          format-source = "";
          format-source-muted = "";
          format-icons = { "default" = [ "" "" "" ]; };
          scroll-step = 1;
          tooltip-format = "{desc}; {volume}%";
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          on-click-middle = "pavucontrol";
        };
        "battery" = {
          interval = 60;
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-icons = [ "" "" "" "" ];
          format-alt = "{time} {icon}";
        };
        "tray" = { spacing = 10; };
      };
    };
  };
}