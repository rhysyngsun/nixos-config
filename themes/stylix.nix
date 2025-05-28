{
  pkgs,
  lib,
  ...
}: let
  flavor = rec {
    name = "Mocha";
    lower = lib.toLower name;
  };
  accent = rec {
    name = "Lavender";
    lower = lib.toLower name;
  };
in {
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

    fonts = let
      serif = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font Mono";
      };
    in {
      inherit serif;
      sansSerif = serif;
      monospace = serif;
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
