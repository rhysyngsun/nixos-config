{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dev;
in {
  imports = [
    ./git
    ./nodejs
    ./zsh
  ];

  options.dev = {
    enable = mkEnableOption "dev";
  };

  config.dev = mkIf cfg.enable {
    git.enable = true;
    nodejs.enable = true;
    zsh.enable = true;
  };
    
  config.home = mkIf cfg.enable {
    packages = [
      hostctl
      http-prompt
      httpie
      jq
      just
      usql

      # virtualizaiont
      lazydocker
      vagrant
    ];
  };
}