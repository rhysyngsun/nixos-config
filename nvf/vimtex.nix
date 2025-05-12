{ pkgs, ... }:
{
  config.vim = {
    lazy.plugins."vimtex" = {
      package = pkgs.vimPlugins.vimtex;
      lazy = false;
      after = # lua
        ''
        '';
    };
  };
}
