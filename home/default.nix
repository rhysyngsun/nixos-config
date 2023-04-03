{ inputs, outputs, lib, ... }:
with lib;
let
 mkUser = name: mkMerge [
  outputs.homeManagerModules
  # inputs.hyprland.homeManagerModules.default
  # import ./${name}
 ];
in {
  home-manager.users = {
    nathan = mkUser "nathan";
  };
}