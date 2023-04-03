{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dev.nodejs;
  npmDirs = [
    cfg.npmBin
    cfg.npmModules
  ];
in
{
  options.dev.nodejs = {
    enable = mkEnableOption "nodejs";
    npmBin = mkOption {
      type = types.str;
      default = ".npm-packages/bin";
    };
    npmModules = mkOption {
      type = types.str;
      default = ".npm-packages/lib/node_modules/";
    };
  };

  config.home = mkIf cfg.enable {
    file = {
      ".npmrc".source = ./npmrc;
    } // lib.genAttrs
      (map (path: path + "/.keep") npmDirs)
      (_: { text = ""; });

    sessionPath = [
      "$HOME/${cfg.npmBin}"
    ];
    sessionVariables = {
      NODE_PATH = "$HOME/${cfg.npmModules}";
    };

    packages = with pkgs; [ nodejs ];
  };
}
