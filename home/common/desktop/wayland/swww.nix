{ config, pkgs, ... }:
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
      ExecStartPost = "${pkgs.swww}/bin/swww img '${config.stylix.image}'";
      Restart = "on-failure";
      ExecSearchPath = "${pkgs.swww}/bin";
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}
