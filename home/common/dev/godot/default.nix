{ pkgs, ... }:
{
  home.packages = with pkgs; [
    godot_4_5
    godot-voxel
  ];
}
