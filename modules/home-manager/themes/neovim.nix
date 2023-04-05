{ pkgs, lib, ... }:
let
  colors = import ./colors.nix { inherit lib; };
in
{
  programs.neovim = with colors; {
    extraConfig = ''
    colorscheme catppuccin-${flavor.lower}
    '';

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
    ];
  };
}