{ pkgs, lib, ... }:
with lib;
{
  home.packages = with pkgs; [ socat ];

  systemd.user.services = {
    connect-monitors = {
      Unit = {
        Description = "Handle monitor connections";
        After = [ "hyprland-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${getExe pkgs.bash} ${./scripts/handle_monitor_connect.sh}
        '';
      };
    };
  };
}