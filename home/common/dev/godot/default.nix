{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # godot_4_5
    godot_4_6
    godot-voxel
  ];
}
