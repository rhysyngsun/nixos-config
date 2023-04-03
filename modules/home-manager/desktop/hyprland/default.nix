{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.desktop.hyprland;
in {
  options.desktop.hyprland = {
    enable = mkEnableOption "hyprland";
  };

  config.desktop.wayland = mkIf cfg.enable {
    waybar.enable = true;
  };

  config.wayland.windowManager.hyprland = mkIf cfg.enable {
    enable = true;
    systemdIntegration = true;
    extraConfig = ''
    
    # See https://wiki.hyprland.org/Configuring/Monitors/
    monitor=,preferred,auto,auto
    
    input {
      kb_layout = us
    
      follow_mouse = 1
      touchpad = {
        # natural_scroll = false
      }
    }
    
    exec-once = firefox & alacritty

    bind=SUPER,RETURN,exec,${config.programs.alacritty.package}/bin/alacritty
    bind=SUPER,F,exec,${config.programs.firefox.package}/bin/firefox
    bind=SUPER,D,exec,${pkgs.wofi}/bin/wofi --show drun -I
    '';
    xwayland = {
      enable = true;
    };
  };
}