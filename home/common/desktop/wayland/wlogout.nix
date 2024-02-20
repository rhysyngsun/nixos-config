{ pkgs, ... }:
let
  inherit (pkgs) wlogout;
in
{
  home.packages = [ wlogout ];

  xdg.configFile = {
    "wlogout/layout".text = ''
      {
        "label" : "lock",
        "action" : "${pkgs.swaylock-effects}/bin/swaylock",
        "text" : "Lock",
        "keybind" : "l"
      }
      {
        "label" : "hibernate",
        "action" : "systemctl hibernate",
        "text" : "Hibernate",
        "keybind" : "h"
      }
      {
        "label" : "logout",
        "action" : "loginctl terminate-user $USER",
        "text" : "Logout",
        "keybind" : "e"
      }
      {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "Shutdown",
        "keybind" : "s"
      }
      {
        "label" : "suspend",
        "action" : "systemctl suspend",
        "text" : "Suspend",
        "keybind" : "u"
      }
      {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "Reboot",
        "keybind" : "r"
      }
    '';
    "wlogout/style.css".text = ''
      * {
        background-image: none;
        outline: none;
        border: none;
      }
      
      window {
        background-color: rgba(12, 12, 12, 0.3);
      }

      button {
        color: #45475a;
        background-color: #181825;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        margin: 5px;
      }

      button:focus, button:active, button:hover, button:selected {
        background-color: #313244;
        color: #cdd6f4;
      }

      #lock {
          background-image: image(url("${wlogout}/share/wlogout/icons/lock.png"));
      }

      #logout {
          background-image: image(url("${wlogout}/share/wlogout/icons/logout.png"));
      }

      #suspend {
          background-image: image(url("${wlogout}/share/wlogout/icons/suspend.png"));
      }

      #hibernate {
          background-image: image(url("${wlogout}/share/wlogout/icons/hibernate.png"));
      }

      #shutdown {
          background-image: image(url("${wlogout}/share/wlogout/icons/shutdown.png"));
      }

      #reboot {
          background-image: image(url("${wlogout}/share/wlogout/icons/reboot.png"));
      }
    '';
  };
}
