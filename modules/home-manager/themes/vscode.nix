{ config, lib, ... }: 
with lib;
let
  colors = config.themes.colors;
  cfg = config.themes.vscode;
in {
  imports = [
    ./colors.nix
  ];

  options.themes.vscode = {
    enable = mkEnableOption "theme-vscode";
  };

  config.programs.vscode = with colors; mkIf cfg.enable {
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