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

    # monkey patch zoom so that it runs in the systemd slice sandbox
    # it otherwise uses 65% of all available CPUs
#     Zoom = {
#       name = "Zoom";
#       comment = "Zoom Video Conference";
#       exec = ''
#         ${pkgs.systemd}/bin/systemd-run --slice --user --slice=sandbox-zoom -- ${pkgs.zoom-us}/bin/zoom %U
#       '';
#       icon = "Zoom";
#       terminal = false;
#       type = "Application";
#       categories = [ "Network" "Application" ];
#       mimeType = [
#         "x-scheme-handler/zoommtg"
#         "x-scheme-handler/zoomus"
#         "x-scheme-handler/tel"
#         "x-scheme-handler/callto"
#         "x-scheme-handler/zoomphonecall"
#         "application/x-zoom"
#       ];
#       settings = {
#         Encoding = "UTF-8";
#         StartupWMClass = "zoom";
#         "X-KDE-Protocols" = "zoommtg;zoomus;tel;callto;zoomphonecall;";
#       };
#     };
  };

  systemd.user.slices = {
    # make zoom behave and not consume an ungodly amount of cpu and memory
    sandbox-zoom = {
      Slice = {
        AllowedCPUs = "0-4";
        CPUQouta = "20%";
        MemoryHigh = "4G";
      };
    };
  };
}
