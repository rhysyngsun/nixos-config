{ pkgs, ... }:
{
  programs.neovim = with pkgs.rice.colors; {
    extraConfig = ''
      colorscheme catppuccin-${flavor.lower}
    '';

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
    ];
  };
}
