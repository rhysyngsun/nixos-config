{ pkgs, ... }:
with pkgs.rice.colors;
{
  programs.vscode = {
    extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
      # sirmspencer.vscode-autohide
    ];

    userSettings = {
      "extensions.autoCheckUpdates" = false;
      "update.mode" = "none";

      # theme
      "window.titleBarStyle" = "custom";
      "workbench.colorTheme" = "Catppuccin ${flavor.name}";
      "catppuccin.accentColor" = accent.lower;
      # use your accent on the statusBar as well
      "catppuccin.customUIColors"."${flavor.lower}"."statusBar.foreground" = "accent";
    };
  };
}
