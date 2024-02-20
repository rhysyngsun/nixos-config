{ pkgs, ... }:
{
  systemd.user.services = {
    myco = {
      Unit = {
        Description = "Run mycorrhiza server";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.mycorrhiza}/bin/mycorrhiza ~/myco-wiki";
      };
    };
  };
}
