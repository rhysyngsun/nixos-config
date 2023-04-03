{ config, lib, pkgs, ... }: 
with lib;
let
  cfg = config.desktop.wayland.wofi;
in {
  options.desktop.wayland.wofi = {
    enable = mkEnableOption "wofi";
  };

  config.home = mkIf cfg.enable {
    packages = with pkgs; [
      wofi
    ];
  };

  config.xdg.configFile = mkIf cfg.enable {
    "wofi" = {
      source = ../../../config/wofi;
      recursive = true;
    };
  };
}
