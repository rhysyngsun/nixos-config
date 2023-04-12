{ pkgs, ... }:
with pkgs.rice;
{
  xdg.dataFile."rofi/themes".source = rofi.package;

  programs.rofi = {
    theme = "catppuccin-${colors.flavor.lower}";
  };
}
