{ pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{
  programs.vscode = with colors; {
    extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
    ];

    userSettings = {
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = "Catppuccin ${flavor.name}";
      "catppuccin.accentColor" = accent.lower;
      # use your accent on the statusBar as well
      "catppuccin.customUIColors"."${flavor.lower}"."statusBar.foreground" = "accent";
    };
  };
}
