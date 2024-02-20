{ pkgs, system, inputs, ... }:
let
  nixvim = inputs.nixvim.legacyPackages."${system}".makeNixvim {
    globals.mapleader = ",";

    extraConfigVim = ''
      let g:himalaya_folder_picker = 'telescope'
      let g:himalaya_folder_picker_telescope_preview = 1
    '';

    plugins.telescope = {
      enable = true;
    };

    extraPackages = with pkgs; [
      ripgrep
    ];

    extraPlugins = [
      pkgs.unstable.vimPlugins.himalaya-vim
    ];
  };
  nvimalaya = pkgs.writeShellScriptBin "nvimalaya" "NVIM_APPNAME=nvimalaya ${nixvim}/bin/nvim";
in
{
  home.packages = [ nvimalaya ];
}
