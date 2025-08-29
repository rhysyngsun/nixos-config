{
  lib,
  pkgs,
}:
with pkgs.nix-rice;
with lib; let
  flavor = rec {
    name = "Mocha";
    lower = toLower name;
  };
  accent = rec {
    name = "Lavender";
    lower = toLower name;
  };
  theme = kitty-themes.getThemeByName "Catppuccin-${flavor.name}";
  gtk-theme = pkgs.catppuccin-gtk.override {
    accents = ["${accent.lower}"];
    size = "compact";
    tweaks = [
      "rimless"
      "black"
    ];
    variant = "${flavor.lower}";
  };
in {
  colors = {
    inherit flavor accent;
  };
  colorPalette =
    rec {
      normal =
        palette.defaultPalette
        // {
          black = theme.color0;
          red = theme.color1;
          green = theme.color2;
          yellow = theme.color3;
          blue = theme.color4;
          magenta = theme.color5;
          cyan = theme.color6;
          white = theme.color7;
        };
      bright =
        palette.brighten 10 normal
        // {
          black = theme.color8;
          red = theme.color9;
          green = theme.color10;
          yellow = theme.color11;
          blue = theme.color12;
          magenta = theme.color13;
          cyan = theme.color14;
          white = theme.color15;
        };
      dark = palette.darken 10 normal;
      primary = {
        inherit (theme) background foreground;
        bright_foreground = color.brighten 10 theme.foreground;
        dim_foreground = color.darken 10 theme.foreground;
      };
    }
    // theme;
  font = {
    normal = {
      name = "Cantarell";
      package = pkgs.cantarell-fonts;
      size = 10;
    };
    monospace = {
      name = "Iosevka Nerd Font Mono";
      family = "Iosevka, mono";
      package = pkgs.iosevka;
      size = 10;
    };
  };

  gtk = {
    theme = {
      name = "Catppuccin-${flavor.name}-Compact-${accent.name}-Dark";
      package = gtk-theme;
      css = "${gtk-theme}/share/themes/Catppuccin-${accent.name}-Dark-Compact/gtk-3.0/gtk-dark.css";
    };
  };

  cursors = {
    name = "Catppuccin-${flavor.name}-${accent.name}-Cursors";
    package = pkgs.catppuccin-cursors."${flavor.lower}${accent.name}";
    size = 14;
  };

  icons = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme.override {color = "white";};
  };

  btop = {
    package = pkgs.catppuccin-themes.btop + "/themes";
  };

  rofi = {
    package = pkgs.catppuccin-themes.rofi + "/basic/.local/share/rofi/themes";
  };

  opacity = 1.0;
}
