{ pkgs, ... }:
let
  swww = "${pkgs.swww}/bin/swww";
  background = "${../../../../backgrounds/the_valley.png}";
in
{
  home.packages = [ pkgs.swww ];

  systemd.user.services."swww" =  {
    Unit = {
      After = "graphical-session.target";
      PartOf = "graphical-session.target";
      Requires = "graphical-session.target";
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.swww}/bin/swww init";
      ExecStartPost = "${pkgs.swww}/bin/swww img '${background}'";
      Restart = "on-failure";
      ExecSearchPath = "${pkgs.swww}/bin";
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}