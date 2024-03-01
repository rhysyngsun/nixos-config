{ pkgs-stable, ... }:
let
  pkgs = pkgs-stable;
in
{
  home.packages = [
    pkgs.discord
    pkgs.slack
    pkgs.element-desktop
    pkgs.zoom-us
  ];

  xdg.desktopEntries = {
    Slack = {
      name = "Slack";
      comment = "Slack Desktop";
      genericName = "Slack Client for Linux";
      exec = "GDK_SCALE=1 ${pkgs.slack}/bin/slack -s %U";
      icon = "slack";
      type = "Application";
      startupNotify = true;
      categories = [ "GNOME" "GTK" "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/slack" ];
      settings = {
        StartupWMClass = "Slack";
      };
    };
    Discord = {
      name = "Discord";
      genericName = "All-in-one cross-platform voice and text chat for gamers";
      exec = "GDK_SCALE=1 ${pkgs.discord}/bin/Discord";
      icon = "discord";
      type = "Application";
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/discord" ];
    };
  };
}
