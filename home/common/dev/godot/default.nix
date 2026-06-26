{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # godot_4_5
    # godot_4_6
    pkgs-edge.godot_4_7
    godot-voxel
  ];
}
