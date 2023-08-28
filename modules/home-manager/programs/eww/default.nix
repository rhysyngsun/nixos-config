{ config, pkgs, lib, ... }:
with lib;
let 
  dependencies = [
  ];
  cfg = config.programs.eww;
in
{

  options.programs.eww-wayland = {
    enable = mkEnableOption "Eww Wayland";

    package = mkPackageOption pkgs "eww-wayland" {};
  };

  config = mkIf cfg.enable {
    systemd.user.services.eww = {
      Unit = {
        Description = "Eww Service";
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
        ExecStart = "${cfg.package}/bin/eww daemon --no-daemonize";
        Restart = "on-failure";
      };
      Install.WantedBy = [
        "graphical-session.target"
      ];
    };
  };
}