{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.programs.ol-local;
  yamlFormat = pkgs.formats.yaml { };
  makeComposeOverrideFile = project:
    let
      filename = project.composeFilename;
      config = {
        services = map
          (subdomain:
            let
              host = concatStringsSep "." hostParts;
            in
            {
              labels = [
                "traefik.http.routers.whoami.rule=Host(`${host}`)"
              ];
            })
          project.services;
      };
      configSource = yamlFormat.generate filename config;
    in
    pkg.writeText filename;

  projectOptions = {
    name = mkOption {
      type = str;
    };

    path = mkOption {
      type = path;
    };

    composeFilename = mkOption
      {
        type = str;
      }

      services = mkOption {
    type = listOf str;
  };

  direnv.enable = mkEnableOption "direnv support";
  };

  makeConfig = project: {
    file.${project.composeFilename}.source = makeComposeOverrideFile project;
  }

    projectsWithFilenames = map (project: {
  composeFilename = "docker-compose.${project.name}.yml";
  } // project) cfg.projects;

  finalConfig = map makeConfig projectsWithFilenames;
in
{
  options.programs.ol-local = with types; {
    enable = mkEnableOption "ol-local";

    rootHost = mkOption {
      type = str;
      default = "ol.localhost";
    };

    projects = attrsOf projectOptions;
  };

  config = mkIf cfg.enable mkMerge finalConfig;
}
