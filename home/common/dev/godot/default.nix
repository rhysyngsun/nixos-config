{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # godot_4_5
    godot_4_6
    pkgs-edge.godot
    godot-voxel
  ];
}
