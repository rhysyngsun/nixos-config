{ options, config, lib, ... }:
with lib;
let 
  cfg = config.work.open-learning;
in {
  options.work.open-learning = {
    enable = mkEnableOption "Open Learning";
  };

    # networking.extraHosts = concatLines [
    #   builtins.readFile ./hosts/open-learning.hosts
    #   builtins.readFile ./hosts/reddit.hosts
    # ];

  config.home = mkIf cfg.enable {
    sessionVariables = {
      # tutor should use `docker compose` instead of deprecated `docker-compose`
      TUTOR_USE_COMPOSE_SUBCOMMAND = "1";
    };
  };
}