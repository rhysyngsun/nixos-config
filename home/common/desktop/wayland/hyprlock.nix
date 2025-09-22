{ config, lib, ... }:
let
  inherit (config.catppuccin) sources flavor;
  palette = (lib.importJSON "${sources.palette}/palette.json").${flavor}.colors;
  shadow = {
    shadow_passes = 1; # 0 disables shadow
    shadow_color = "rgb(${palette.mantle.hex})";
  };

  mkRGBA = rgb: opacity: "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, ${lib.strings.floatToString opacity})";
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 5;
        disable_loading_bar = false;
        hide_cursor = false;
        no_fade_in = false;
      };

      background = [
        {
          monitor = "";
          path = "${config.stylix.image}";
          blur_passes = 2; # 0 disables blurring
          blur_size = 7;
        }
      ];

      input-field = [
        (
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 2;

            outer_color = mkRGBA palette.crust.rgb 1.0;
            inner_color = mkRGBA palette.mantle.rgb 1.0;
            font_color = mkRGBA palette.lavender.rgb 1.0;
            # placeholder_text = ''
            #   <span foreground="##${palette.surface0.hex}">Password...</span>
            # '';
            fade_on_empty = false;
            dots_spacing = 0.3;
            dots_center = true;
          }
          // shadow
        )
      ];
      label = [
        (
          {
            monitor = "";
            text = "Greetings, mortal.";
            position = "0, 60";
            color = "rgb(${palette.mantle.hex})";
            valign = "center";
            halign = "center";
          }
          // shadow
        )
        (
          {
            monitor = "";
            text = "$TIME";
            color = "rgb(${palette.mantle.hex})";
            position = "0, 120";
            valign = "center";
            halign = "center";
            shadow_passes = 2; # 0 disables shadow
            shadow_color = "rgb(${palette.mantle.hex})";
          }
          // shadow
        )
      ];
    };
  };
}
