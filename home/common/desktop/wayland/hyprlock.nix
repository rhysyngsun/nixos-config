{ config, pkgs, ... }:
let
  palette = pkgs.catppuccin-palette.mocha;
in {
  programs.hyprlock = {
    enable = true;
    backgrounds = let
      wallpaperPath = "${config.stylix.image}";
    in [
      {
        monitor = "eDP-1";
        path = wallpaperPath;
      }
    ];
    general = {
      grace = 5;
      disable_loading_bar = false;
      hide_cursor = false;
      no_fade_in = false;
    };
    input-fields = [
      {
        monitor = "eDP-1";
        size = {
          width = 300;
          height = 50;
        };
        outline_thickness = 2;

        outer_color = "rgb(${palette.crust.hex})";
        inner_color = "rgb(${palette.mantle.hex})";
        font_color = "rgb(${palette.lavender.hex})";
        placeholder_text = ''
          <span foreground="##${palette.surface0.hex}">Password...</span>
        '';
        fade_on_empty = false;
        dots_spacing = 0.3;
        dots_center = true;
      }
    ];
    labels = [
      {
        monitor = "eDP-1";
        text = "Greetings, mortal.";
        color = "rgb(${palette.lavender.hex})";
        valign = "center";
        halign = "center";
      }
      {
        monitor = "eDP-1";
        text = "$TIME";
        color = "rgb(${palette.lavender.hex})";
        position = {
          x = 0;
          y = 120;
        };
        valign = "center";
        halign = "center";
      }
    ];
  };
}
