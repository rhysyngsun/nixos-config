{ pkgs, lib, ... }:

{
  imports = [ ./compose-overrides.nix ];

  systemd.user.services = {
    traefik-local = {
      Unit = {
        After = [ "docker.socket" ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.traefic}/bin/traefik \
            --api.insecure=true \
            --providers.docker=true
        '';
      };

      Install = {
        WantedBy = [ "multi-user.target" ];
      };
    };
  };

  programs.ol-local = {
    enable = true;
    projects = {
      micromasters = {
        services = { };
      };
    };
  };
}
