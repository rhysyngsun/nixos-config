{ config, lib, ... }:

with lib;
let 
  cfg = config.dev.git;
in {
  options.dev.git = {
    enable = mkEnableOption "git";
  };

  config.home = mkIf cfg.enable {
    shellAliases = ./aliases.nix;

    packages = with pkgs; [ pre-commit ];
  };

  config.programs.git = mkIf cfg.enable{
    enable = true;

    delta = {
      enable = true;
    };

    includes = [
      { path = "${config.xdg.configHome}/git/default.gitconfig"; }
      {
        path = "${config.xdg.configHome}/git/ol.gitconfig";
        condition = "hasconfig:remote.*.url:https://github.com/mitodl/**";
      }
    ];
  };
}