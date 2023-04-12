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
      (python310.withPackages python-packages)
      python310Packages.pip
      python310Packages.virtualenv
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
in
{
  home = {
    packages =  [
      tutor-python
      tutor-env
      tutor
    ];

    sessionVariables = {
      # tutor should use `docker compose` instead of deprecated `docker-compose`
      
    };
  };
}