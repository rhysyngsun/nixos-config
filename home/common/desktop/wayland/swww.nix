{ config, pkgs, ... }:
let
  swww = pkgs.swww;
  target = "graphical-session.target";
in
{
  home.packages = [ swww ];

  systemd.user.services."swww" = {
    Unit = {
      PartOf = [ target ];
      After = [ target ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = "${swww}/bin/swww-daemon --format xrgb";
      ExecStartPost = "${swww}/bin/swww img '${config.stylix.image}'";
      ExecStop = "${swww}/bin/swww kill";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
