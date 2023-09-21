{ pkgs, ... }:
let
  rice = pkgs.rice;
in
{
  home.packages = with pkgs; [
    unstable.godot_4
  ];
}