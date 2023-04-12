{ config, lib, pkgs, ... }:
with lib;

{
  services.greetd = {
    enable = true;
    vt = 2;
    settings = {
      default_session = {
        command = let
          background = ../../../backgrounds/the_valley.png;
          style = pkgs.writeText "greetd-gtkgreet.css" ''
            @import url("${pkgs.rice.gtk.css-path}");
            window {
              background-image: url("${background}");
              background-position: center;
              background-repeat: no-repeat;
              background-size: cover;
              background-color: black;
            }
          '';
        in ''
          ${pkgs.dbus}/bin/dbus-run-session \
            ${pkgs.cage}/bin/cage -s \
            -- ${pkgs.greetd.gtkgreet}/bin/gtkgreet -s ${style}
          '';
        user = "greeter";
      };
    };
  };


  environment = {
    systemPackages = with pkgs; [
      rice.gtk.theme
      rice.cursors
      rice.icons
      cage
      greetd.gtkgreet
    ];

    etc = {

      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-cursor-theme-name=Catppuccin-Mocha-Dark-Cursors
        gtk-cursor-theme-size=24
        gtk-font-name=Roboto
        gtk-icon-theme-name=Papirus-Dark
        gtk-theme-name=Catppuccin-Lavender-Dark-Compact
      '';
      "greetd/environments".text = ''
        Hyprland
        zsh
      '';
    };
  };
}