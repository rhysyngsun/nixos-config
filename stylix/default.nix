{ pkgs, ... }:
{
  stylix = {
    autoEnable = false;
    image = ./backgrounds/the_valley.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

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
  };
}

