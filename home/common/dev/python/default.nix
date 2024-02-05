{ config, pkgs, lib, ... }:
with lib;
let
  python-packages = ps: with ps; [
    tutor
    tutor-discovery
    tutor-license
    tutor-mfe
  ];
  tutor-python = pkgs.buildFHSUserEnv {
    name = "tutor-python";
    targetPkgs = pkgs: (with pkgs; [
      (python3.withPackages python-packages)
      python3Packages.pip
      python3Packages.virtualenv
    ]);
    profile = ''
    export TUTOR_USE_COMPOSE_SUBCOMMAND=1
    '';
    runScript = "bash";
  };
  venv-dir = "${config.xdg.dataHome}venv/tutor/";

  tutor-env = pkgs.writeShellScriptBin "tutor-env" ''
  
  if [[ ! -d ${venv-dir} ]] ; then
    python -m venv ${venv-dir}
  fi

  source ${venv-dir}/bin/activate

  $@

  deactivate
  '';

  tutor = pkgs.writeShellScriptBin "tutor" "tutor-python tutor-env tutor $@";

  jq = lib.getExe pkgs.jq;
  tail = "${pkgs.coreutils}/bin/tail";
  docker = "${pkgs.docker}/bin/docker";

  tutor-ip = pkgs.writeShellScriptBin "tutor-ip" ''
    CADDY_HOSTNAME=$(${tutor}/bin/tutor local dc ps caddy --format=json | ${tail} -n1 | ${jq} -r '.[].Name')
    CADDY_IP=$(${docker} inspect $CADDY_HOSTNAME | jq -r '.[].NetworkSettings.Networks.tutor_local_default.IPAddress')
    echo $CADDY_IP
  '';
  tutor-ip-watch = pkgs.writeShellScriptBin "tutor-ip-watch" ''
    function update-tutor-hosts() {
      TUTOR_IP=$(${tutor-ip}/bin/tutor-ip)
      printf "%s\n" "x-tutor-hosts: &tutor-hosts" "  - \"local.overhang.io=$TUTOR_IP\"" > ${config.home.homeDirectory}/open-learning/docker-compose.tutor-hosts.yml
    }
    update-tutor-hosts
    ${docker} events --filter 'event=start' --filter 'type=container' --filter 'image=caddy' | while read event
    do
      update-tutor-hosts
    done
  '';
in
{
  home = {
    packages =  [
      tutor-python
      tutor-env
      tutor
      # utils
      tutor-ip
      tutor-ip-watch

      pkgs.python3Packages.pkginfo
      pkgs.python3Packages.wheel-inspect
    ];
  };

  systemd.user = {
    services.tutor-ip = {
      Service = {
        ExecStart = "${tutor-ip-watch}/bin/tutor-ip-watch";
        Type = "simple";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
