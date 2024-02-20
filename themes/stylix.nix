{ pkgs, lib, ... }:
let
  flavor = rec {
    name = "Mocha";
    lower = lib.toLower name;
  };
  accent = rec {
    name = "Lavender";
    lower = lib.toLower name;
  };
in
{
  stylix = {
    autoEnable = false;
    image = ./backgrounds/the_valley.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    cursor = {
      name = "Catppuccin-${flavor.name}-${accent.name}-Cursors";
      package = pkgs.catppuccin-cursors."${flavor.lower}${accent.name}";
      size = 14;
    };

    fonts = rec {
      serif = {
        package = pkgs.nerdfonts.override {
          fonts = [
            "FiraCode"
            "FiraMono"
            "Iosevka"
          ];
        };
        name = "Iosevka Nerd Font Mono";
      };
      sansSerif = { inherit (serif) package name; };
      monospace = { inherit (serif) package name; };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    targets = {
      wezterm.enable = true;
    };
  };
}

