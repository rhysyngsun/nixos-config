{ lib, pkgs }:

with pkgs.nix-rice;
with lib;

let 
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
    accents = [ "${accent.lower}" ];
    size = "compact";
    tweaks = [ "rimless" "black" ];
    variant = "${flavor.lower}";
  };
  catppuccin-alacritty = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "alacritty";
    rev = "3c808cbb4f9c87be43ba5241bc57373c793d2f17";
    hash = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
  };
in
{
  colors = { inherit flavor accent; };
  colorPalette = rec {
    normal = palette.defaultPalette // {
      black = theme.color0;
      red = theme.color1;
      green = theme.color2;
      yellow = theme.color3;
      blue = theme.color4;
      magenta = theme.color5;
      cyan = theme.color6;
      white = theme.color7;
    };
    bright = palette.brighten 10 normal // {
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
  } // theme;
  font = {
    normal = {
      name = "Cantarell";
      package = pkgs.cantarell-fonts;
      size = 10;
    };
    monospace = {
      name = "FiraCode Nerd Font Mono";
      package = pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "Iosevka"
        ];
      };
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
    package = pkgs.papirus-icon-theme.override { color = "white"; };
  };

  alacritty = {
    package = catppuccin-alacritty;
    config = catppuccin-alacritty + "/alacritty/catppuccin/catppuccin-${flavor.lower}.yml";
  };

  btop = {
    package = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "btop";
      rev = "7109eac2884e9ca1dae431c0d7b8bc2a7ce54e54";
      hash = "sha256-QoPPx4AzxJMYo/prqmWD/CM7e5vn/ueyx+XQ5+YfHF8=";
    }) + "/themes";
  };

  rofi = {
    package = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "rofi";
      rev = "5350da41a11814f950c3354f090b90d4674a95ce";
      hash = "sha256-DNorfyl3C4RBclF2KDgwvQQwixpTwSRu7fIvihPN8JY=";
    }) + "/basic/.local/share/rofi/themes";
  };

  opacity = 0.8;
}