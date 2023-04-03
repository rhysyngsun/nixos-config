{ config, lib, ... }: 
with lib;
let
  cfg = config.NAME;
in {
  options.NAME = {
    enable = mkEnableOption "NAME";
  };

  config.NAME = mkIf cfg.enable {
    hm = {
      packages = with pkgs; [
        
      ];

      programs = {

      };

      user = {
      };
    };
  };
}
