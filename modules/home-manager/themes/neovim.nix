{ config, lib, pkgs, ... }: 
with lib;
let
  colors = config.themes.colors;
  cfg = config.themes.neovim;
in {
  imports = [
    ./colors.nix
  ];
  options.themes.neovim = {
    enable = mkEnableOption "theme-neovim";
  };

  config.programs.neovim = with colors; mkIf cfg.enable {
    extraConfig = ''
    colorscheme catppuccin-${flavor.lower}
    '';

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
    ];
  };
}