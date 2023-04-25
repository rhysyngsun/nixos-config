{ pkgs, lib, ... }:
{
  home = {
    sessionVariables = {
      # tutor should use `docker compose` instead of deprecated `docker-compose`
      TUTOR_USE_COMPOSE_SUBCOMMAND = "1";
    };
  };
}
