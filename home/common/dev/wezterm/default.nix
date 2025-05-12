{ inputs, pkgs, ... }:
let
  wezterm = inputs.wezterm.packages.${pkgs.system}.default;
in
{
  # note: NOT using home-manager's programs.wezterm.*
  #       because it handles wezterm.lua in not the most extensible way
  home.packages = [ wezterm ];

  xdg.configFile."wezterm/" = {
    source = ./conf;
    recursive = true;
  };

  # copied from home-manager's
  programs.zsh.initExtra = ''
    source "${wezterm}/etc/profile.d/wezterm.sh"
  '';
}
