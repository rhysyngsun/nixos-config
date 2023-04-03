{ pkgs, config, lib, ... }:

with lib;

let 
  cfg = config.themes;
in 
{
  imports = [
    # colors
    ./colors.nix
    # theming of apps
    ./alacritty.nix
    ./gtk.nix
    ./neovim.nix
    ./rofi.nix
    ./vscode.nix
  ];

  options.themes = {
    enable = mkEnableOption "themes";
  };

  config.themes = mkIf cfg.enable {
    alacritty.enable = true;
    cursors.enable = true;
    gtk.enable = true;
    neovim.enable = true;
    rofi.enable = true;
    vscode.enable = true;
  };
}
