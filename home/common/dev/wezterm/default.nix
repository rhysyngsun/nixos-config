{ pkgs-stable, ... }:
let
  pkgs = pkgs-stable;

in
{
  # note: NOT using home-manager's programs.wezterm.*
  #       because it handles wezterm.lua in not the most extensible way
  home.packages = with pkgs; [ wezterm ];

  xdg.configFile."wezterm/" = {
    source = ./conf;
    recursive = true;
  };

  # copied from home-manager's 
  programs.zsh.initExtra = ''
    source "${pkgs.wezterm}/etc/profile.d/wezterm.sh"
  '';

}
