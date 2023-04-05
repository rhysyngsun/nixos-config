{ pkgs }:
{
  mainBar = {
    layer = "top";
    position = "top";
    modules-left = [
      "wlr/workspaces"
      "wlr/taskbar"
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
      "network"
      "pulseaudio"
      "custom/notification"
      "tray"
    ];

    "wlr/workspaces" = {
      format = "{icon}";
      on-click = "activate";
      sort-by-number = true;
      format-icons = {
        "1" = ""; # terminal
        "2" = "󰻞"; # chat
        "3" = ""; # code
        "4" = "󰖟"; # web
      };
    };

    "wlr/taskbar" = {
      on-click = "activate";
      ignore-list = [
        "Alacritty"
      ];
    };

    "cpu" = {
      interval = 10;
      format = "<span font='20' rise='-4000'>󰍛</span> {usage}%";
      tooltip = false;
    };
    "memory" = {
      interval = 10;
      format = "<span font='20' rise='-4000'>󰍛</span> {}%";
    };
    "disk" = {
      interval = 600;
      format = "<span font='20' rise='-4500'>󰋊</span> {percentage_used}%";
      path = "/";
    };
    "clock" = {
      interval = 1;
      format = "{:<span font='18' rise='-4000'></span> %a %b %d, %H:%M:%S}";
      tooltip-format = "<tt><small>{calendar}</small></tt>";
      calendar = {
        "mode"       =   "year";
        "mode-mon-col"  =3;
        "weeks-pos"     = "right";
        "on-scroll"     = 1;
        "on-click-right"= "mode";
        "format"= {
          "months"=     "<span color='#ffead3'><b>{}</b></span>";
          "days"=       "<span color='#ecc6d9'><b>{}</b></span>";
          "weeks"=      "<span color='#99ffdd'><b>W{}</b></span>";
          "weekdays"=   "<span color='#ffcc66'><b>{}</b></span>";
          "today"=      "<span color='#ff6699'><b><u>{}</u></b></span>";
        };
      };
    };
    "temperature" = {
      interval = 5;
      critical-threshold = 60;
      format = "<span font='12'></span> {temperatureC}°C";
    };
    "network" = {
      format-wifi = "<span font='20' rise='-4000'></span> {signalStrength}%";
      format-ethernet = "<span font='18' rise='-4000'></span>";
      tooltip-format = "{ifname} via {gwaddr}";
      format-linked = "{ifname} (No IP)";
      format-disconnected = "<span font='16' rise='-2000'></span>";
    };
    "pulseaudio" = {
      format = "<span font='18' rise='-3000'>{icon}</span> {volume}%   {format_source}";
      format-muted = "<span font='18' rise='-3000'></span>   {format_source}";
      format-source = "<span font='16' rise='-2000'></span>";
      format-source-muted = "<span font='16' rise='-2000'></span>";
      format-icons = { "default" = [ "" "" "" ]; };
      scroll-step = 1;
      tooltip-format = "{desc}; {volume}%";
      on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      on-click-middle = "pavucontrol";
    };
    "battery" = {
      interval = 15;
      states = {
        warning = 20;
        critical = 10;
      };
      format = "<span font='11'>{icon}</span> {capacity}%";
      format-charging = "<span font='11'></span> {capacity}%";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        "󰁹"
      ];
      format-alt = "{icon} {time}";
    };
    "tray" = {
      spacing = 10;
      icon-theme = "Catppuccin-Mocha-Lavender-Icons";
    };

    "custom/notification" =  {
      "tooltip" = false;
      "format" = "<span font='16' rise='-2000'>{icon}</span> {}";
      "format-icons" = {
        "notification" = "<span foreground='red'><sup></sup></span>";
        "none" = "";
        "dnd-notification" = "<span foreground='red'><sup></sup></span>";
        "dnd-none" = "";
        "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
        "inhibited-none" = "";
        "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
        "dnd-inhibited-none" = "";
      };
      "return-type" = "json";
      "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
      "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
      "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
      "escape" = true;
    };
  };
}