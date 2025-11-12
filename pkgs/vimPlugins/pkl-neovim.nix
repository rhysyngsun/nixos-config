{pkgs, source, ... }:
pkgs.vimUtils.buildVimPlugin {
  name = "pkl-neovim";
  inherit (source) src; 
}
