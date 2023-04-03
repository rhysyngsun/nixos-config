{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.desktop.browsers;
  addons = inputs.firefox-addons.packages.${pkgs.system};
in {
  options.desktop.browsers = {
    enable = mkEnableOption "browsers";
  };
  
  config.programs.firefox = mkIf cfg.enable {
    enable = true;

    profiles = {
      Default = {
        id = 1;
        isDefault = true;

        extensions = with addons; [
          lastpass-password-manager
        ];
      };
    };
  };
}