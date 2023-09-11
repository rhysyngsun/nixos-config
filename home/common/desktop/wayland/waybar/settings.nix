{ config, pkgs, lib, ... }:
with lib;
{
  mainBar = {
    layer = "top";
    position = "top";
    modules-left = [
      "hyprland/workspaces"
    ];
    modules-center = [
      "cpu"
      "memory"
      "disk"
      "temperature"
      "battery"
    ];
    modules-right = [
      "clock"
      "pulseaudio"
      "tray"
      "custom/powermenu"
    ];

    "hyprland/workspaces" = {
      format = "{icon}";
      on-click = "activate";
      sort-by-number = true;
      format-icons = {
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
        "10" = "10";
      };
    };

    "cpu" = {
      interval = 10;
      format = "<span font='11'>󰍛</span>  {usage}%";
      tooltip = false;
    };
    "memory" = {
      interval = 10;
      format = "<span font='11'>󰍛</span>  {}%";
    };
    "disk" = {
      interval = 60;
      format = "<span font='11'>󰋊</span>  {percentage_used}%";
      path = "/";
    };
    "clock" = {
      interval = 1;
      format = "{:<span font='11'></span>   %a %b %d, %H:%M:%S}";
    };
    "temperature" = {
      interval = 1;
      critical-threshold = 60;
      thermal_zone = 1;
      format = "<span font='11'></span> {temperatureC}°C";
    };
    "network" = {
      format-wifi = "<span font='11'></span>   {signalStrength}%";
      format-ethernet = "<span font='11'></span> ";
      tooltip-format = "{ifname} via {gwaddr}";
      format-linked = "{ifname} (No IP)";
      format-disconnected = "<span font='11'></span> ";
    };
    "pulseaudio" = {
      format = "<span font='11'>{icon}</span>  {volume}%   {format_source}";
      format-muted = "<span font='11'></span>   {format_source}";
      format-source = "<span font='11'></span>";
      format-source-muted = "<span font='11'></span>";
      format-icons = {
        default = [ "" ]; 
        headset = "󰋎";
        headphone = "󰋋";
      };
      tooltip-format = "{desc}; {volume}%";
      on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      on-click-middle = "pavucontrol";
      on-scroll-up = "pamixer -d 1 --allow-boost --set-limit 200";
      on-scroll-down = "pamixer -d 1 --allow-boost --set-limit 200";
    };
    "battery" = {
      interval = 15;
      states = {
        warning = 20;
        critical = 10;
      };
      format = "<span font='11'>{icon}</span> {capacity}%";
      format-charging = "<span font='11'>󰂄</span> {capacity}%";
      format-icons = [
        "󰂃"
        "󰁺"
        "󰁻"
        "󰁼"
        "󰁽"
        "󰁾"
        "󰁿"
        "󰂀"
        "󰂁"
        "󰂂"
        "󰁹"
      ];
      format-alt = "{icon} {time}";
    };
    "tray" = {
      spacing = 10;
      icon-theme = "Catppuccin-Mocha-Lavender-Icons";
    };

    "custom/powermenu" = {
      tooltip = false;
      format = "<span font='11'>⏻</span>";
      on-click = "${pkgs.wlogout}/bin/wlogout -p layer-shell";
    };

    # "custom/notification" = {
    #   "tooltip" = false;
    #   "format" = "<span font='16' rise='-2000'>{icon}</span> {}";
    #   "format-icons" = {
    #     "notification" = "<span foreground='red'><sup></sup></span>";
    #     "none" = "";
    #     "dnd-notification" = "<span foreground='red'><sup></sup></span>";
    #     "dnd-none" = "";
    #     "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
    #     "inhibited-none" = "";
    #     "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
    #     "dnd-inhibited-none" = "";
    #   };
    #   "return-type" = "json";
    #   "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
    #   "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    #   "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
    #   "escape" = true;
    # };
  };
}
