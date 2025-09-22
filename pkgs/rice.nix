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

  opacity = 1.0;
}
