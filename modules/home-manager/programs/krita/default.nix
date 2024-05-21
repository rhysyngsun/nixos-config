{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.krita;
in
{
  options = {
    programs.krita = {
      enable = mkEnableOption "krita";

      package = mkOption {
        type = types.package;
        default = pkgs.krita;
        defaultText = literalExpression "pkgs.krita";
        description = ''
          Krita package to install.
        '';
      };

      plugins = mkOption {
        default = [ ];
        example = literalExpression "[ pkgs.krita-plugins.buli-brush-switch ]";
        description = "Optional Krita plugins.";
        type = types.listOf types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.dataFile = mkIf (cfg.plugins != [ ]) (
      let
        plugins = (
          pkgs.symlinkJoin {
            name = "krita-plugins";
            paths = cfg.plugins;
          }
        );
      in
      {
        "krita/" = {
          source = plugins + "/share/krita/";
          recursive = true;
        };
      }
    );
  };
}
